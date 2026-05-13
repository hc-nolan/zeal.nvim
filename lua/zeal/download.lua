local M = {}

local cache_dir = vim.fn.stdpath("cache") .. "/zeal-docsets"
local cache_path = cache_dir .. "/index.json"

---Recursively copy a directory using vim.uv
---@param src string
---@param dest string
---@return boolean ok, string? err
local function copy_dir(src, dest)
	local ok, err = vim.uv.fs_mkdir(dest, 493) -- 0755
	if not ok then
		return false, "failed to create dir " .. dest .. ": " .. (err or "")
	end
	local handle = vim.uv.fs_scandir(src)
	if not handle then
		return false, "failed to scan " .. src
	end
	while true do
		local name, type = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "directory" then
			local ok2, err2 = copy_dir(src .. "/" .. name, dest .. "/" .. name)
			if not ok2 then
				return false, err2
			end
		else
			local ok3, err3 = vim.uv.fs_copyfile(src .. "/" .. name, dest .. "/" .. name)
			if not ok3 then
				return false, "failed to copy " .. name .. ": " .. (err3 or "")
			end
		end
	end
	return true
end

---@param language string
function M.download_lang(language)
	local cfg = require("zeal").config
	vim.notify("zeal.nvim: downloading " .. language, vim.log.levels.INFO)

	local url = "https://go.zealdocs.org/d/com.kapeli/" .. language .. "/latest"
	local docsets_path = cfg.docsets_path

	local tmp = vim.fn.tempname()
	local tarball = tmp .. ".tgz"
	vim.fn.mkdir(tmp, "p")

	local function cleanup()
		vim.uv.fs_unlink(tarball)
		vim.fn.delete(tmp, "rf")
	end

	local cmd = { "curl", "-fsSL", "--connect-timeout", "10", "--retry", "2", "-o", tarball, url }
	vim.system(cmd, {}, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify("zeal.nvim: curl failed: " .. result.stderr, vim.log.levels.ERROR)
				cleanup()
			end)
			return
		end

		local tar_cmd = { "tar", "-xzf", tarball, "-C", tmp }
		vim.system(tar_cmd, {}, function(tar_result)
			if tar_result.code ~= 0 then
				vim.schedule(function()
					vim.notify("zeal.nvim: tar failed: " .. tar_result.stderr, vim.log.levels.ERROR)
					cleanup()
				end)
				return
			end

			-- find the .docset directory the tarball extracted to
			local handle = vim.uv.fs_scandir(tmp)
			local src
			if handle then
				while true do
					local name, type = vim.uv.fs_scandir_next(handle)
					if not name then
						break
					end
					if type == "directory" and name:match("%.docset$") then
						src = tmp .. "/" .. name
						break
					end
				end
			end

			if not src then
				vim.schedule(function()
					vim.notify("zeal.nvim: no .docset found in archive for " .. language, vim.log.levels.ERROR)
					cleanup()
				end)
				return
			end

			local dest = docsets_path .. "/" .. language .. ".docset"
			vim.schedule(function()
				-- remove existing docset so copy doesn't nest inside it
				if vim.uv.fs_stat(dest) then
					vim.fn.delete(dest, "rf")
				end
				local ok, err = copy_dir(src, dest)
				if not ok then
					vim.notify("zeal.nvim: copy failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
					cleanup()
					return
				end
				vim.notify("zeal.nvim: installed " .. language, vim.log.levels.INFO)
				cleanup()
			end)
		end)
	end)
end

--- Fetches index of available docsets from Zeal API; noop if fetched within 24hrs
---@param on_complete function Callback function to call on download completion
local function fetch_index(on_complete)
	local index_url = "https://api.zealdocs.org/v1/docsets"
	local cache_ttl = 24 * 60 * 60 -- 24 hours

	local cache_info = vim.uv.fs_stat(cache_path)
	if cache_info then
		local now = os.time()
		local age = now - cache_info.mtime.sec
		if age < cache_ttl then
			on_complete()
			return
		end
	end
	vim.fn.mkdir(cache_dir, "p")

	-- use temp file initially, move to cache_path if download succeeds
	local cache_tmp = cache_path .. ".tmp"
	local cmd = { "curl", "-fsSL", "--connect-timeout", "10", "--retry", "2", "-o", cache_tmp, index_url }
	vim.system(cmd, {}, function(result)
		if result.code ~= 0 then
			vim.uv.fs_unlink(cache_tmp)
			vim.schedule(function()
				vim.notify("zeal.nvim: curl failed: " .. result.stderr, vim.log.levels.ERROR)
			end)
			return
		end
		local ok, err = vim.uv.fs_rename(cache_tmp, cache_path)
		if not ok then
			vim.schedule(function()
				vim.notify("zeal.nvim: failed to move cache: " .. err, vim.log.levels.ERROR)
			end)
			return
		end
		on_complete()
	end)
end

--- Fetch the latest index if needed, then read it and return JSON-parsed results
---@param on_complete function
function M.get_index(on_complete)
	fetch_index(function()
		local ok, index_parsed = pcall(function()
			local raw = table.concat(vim.fn.readfile(cache_path), "\n")
			return vim.json.decode(raw)
		end)
		if not ok then
			vim.notify("zeal.nvim: parsing docset failed: " .. index_parsed, vim.log.levels.ERROR)
			return
		end
		on_complete(index_parsed)
	end)
end

return M
