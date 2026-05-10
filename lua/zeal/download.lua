local M = {}

local cache_dir = vim.fn.stdpath("cache") .. "/zeal-docsets"
local cache_path = cache_dir .. "/index.json"

---@param cfg table
---@param language string
local function download_lang(cfg, language)
	vim.notify("zeal.nvim: downloading " .. language, vim.log.levels.INFO)

	local url = "https://go.zealdocs.org/d/com.kapeli/" .. language .. "/latest"
	local docsets_path = cfg.docsets_path

	local tmp = vim.fn.tempname()
	local tarball = tmp .. ".tgz"
	vim.fn.mkdir(tmp, "p")

	local cmd = { "curl", "-fsSL", "--connect-timeout", "10", "--retry", "2", "-o", tarball, url }
	vim.system(cmd, {}, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify("zeal.nvim: curl failed: " .. result.stderr, vim.log.levels.ERROR)
			end)
			return
		end

		local tar_cmd = { "tar", "-xzf", tarball, "-C", tmp }
		vim.system(tar_cmd, {}, function(result)
			if result.code ~= 0 then
				vim.schedule(function()
					vim.notify("zeal.nvim: tar failed: " .. result.stderr, vim.log.levels.ERROR)
				end)
				return
			end

			-- find the .docset directory the tarball extracted to
			local handle = vim.uv.fs_scandir(tmp)
			local src
			if handle then
				while true do
					local name, type = vim.uv.fs_scandir_next(handle)
					if not name then break end
					if type == "directory" and name:match("%.docset$") then
						src = tmp .. "/" .. name
						break
					end
				end
			end

			if not src then
				vim.schedule(function()
					vim.notify("zeal.nvim: no .docset found in archive for " .. language, vim.log.levels.ERROR)
				end)
				return
			end

			local dest = docsets_path .. "/" .. language .. ".docset"
			vim.system({ "mv", src, dest }, {}, function(mv_result)
				vim.schedule(function()
					if mv_result.code ~= 0 then
						vim.notify("zeal.nvim: move failed: " .. mv_result.stderr, vim.log.levels.ERROR)
						return
					end
					vim.notify("zeal.nvim: installed " .. language, vim.log.levels.INFO)
					vim.uv.fs_unlink(tarball)
				end)
			end)
		end)
	end)
end

---@param cfg table
function M.fetch_index(cfg)
	local index_url = "https://api.zealdocs.org/v1/docsets"
	local cache_ttl = 24 * 60 * 60 -- 24 hours

	local function pick_lang()
		local index = table.concat(vim.fn.readfile(cache_path), "\n")
		local index_parsed = vim.json.decode(index)
		require("zeal.picker").pick_download(index_parsed, cfg, download_lang)
	end

	local cache_info = vim.uv.fs_stat(cache_path)
	if cache_info then
		local now = os.time()
		local age = now - cache_info.mtime.sec
		if age < cache_ttl then
			pick_lang()
			return
		end
	end
	vim.fn.mkdir(cache_dir, "p")

	local cmd = { "curl", "-fsSL", index_url, "-o", cache_path }
	vim.system(cmd, {}, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify("zeal.nvim: curl failed: " .. result.stderr, vim.log.levels.ERROR)
			end)
			return
		end
		vim.schedule(pick_lang)
	end)
end

return M
