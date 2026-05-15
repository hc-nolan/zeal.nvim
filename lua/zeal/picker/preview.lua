local M = {}

local run_dir = vim.fn.stdpath("run")
local tmp_counter = 0
local html_file_cache = {} -- { [filepath] = lines }
local tmp_excerpt_cache = {} -- { [path_with_fragment] = tmpfile }

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		for _, f in pairs(tmp_excerpt_cache) do
			vim.uv.fs_unlink(f, function() end)
		end
	end,
	desc = "zeal.nvim: clean up preview temp files",
})

local function extract_and_callback(html_lines, file, fragment, path, callback)
	for i, line in ipairs(html_lines) do
		if line:find(fragment, 1, true) then
			local data = table.concat(vim.list_slice(html_lines, i), "\n")
			tmp_counter = tmp_counter + 1
			local tmp = run_dir .. "/zeal-preview-" .. tmp_counter .. ".html"
			vim.uv.fs_open(tmp, "w", 438, function(err, fd)
				if err or not fd then
					vim.schedule(function()
						callback(file)
					end)
					return
				end
				vim.uv.fs_write(fd, data, 0, function(werr)
					vim.uv.fs_close(fd, function() end)
					if werr then
						vim.schedule(function()
							callback(file)
						end)
						return
					end
					tmp_excerpt_cache[path] = tmp
					vim.schedule(function()
						callback(tmp)
					end)
				end)
			end)
			return
		end
	end
	vim.schedule(function()
		callback(file)
	end)
end

---Resolves an entry path (possibly with #fragment) to a file path.
---
---Creates cached copies of the relevant entry to prevent unnecessary repeat
---reading of larger docsets.
---@param path string
---@param callback function
local function resolve(path, callback)
	local file = path:match("^([^#]+)")
	local fragment = path:match("#(.+)$")
	if not file then
		return
	end

	if not fragment then
		vim.schedule(function()
			callback(file)
		end)
		return
	end

	local cached_tmp = tmp_excerpt_cache[path]
	if cached_tmp then
		vim.schedule(function()
			callback(cached_tmp)
		end)
		return
	end

	local cached_html = html_file_cache[file]
	if cached_html then
		extract_and_callback(cached_html, file, fragment, path, callback)
		return
	end

	vim.uv.fs_open(file, "r", 438, function(err, fd)
		if err or not fd then
			return
		end
		vim.uv.fs_fstat(fd, function(err2, stat)
			if err2 or not stat then
				vim.uv.fs_close(fd)
				return
			end
			vim.uv.fs_read(fd, stat.size, 0, function(err3, data)
				vim.uv.fs_close(fd)
				if err3 or not data then
					return
				end
				local html_lines = vim.split(data, "\n", { plain = true })
				html_file_cache[file] = html_lines
				extract_and_callback(html_lines, file, fragment, path, callback)
			end)
		end)
	end)
end

---Resolves path, renders it to plain text via browser -dump, and calls callback(lines).
---@param path string  Entry path (may include #fragment)
---@param browser string|table  Browser command — string or argv table
---@param callback function  Called with (lines: string[]) on the main loop
function M.render(path, browser, callback)
	resolve(path, function(render_file)
		local cmd = {}
		vim.list_extend(cmd, type(browser) == "string" and { browser } or browser)
		vim.list_extend(cmd, { "-dump", render_file })
		vim.system(cmd, { text = true }, function(result)
			local lines = (result.code == 0 and result.stdout) and vim.split(result.stdout, "\n", { plain = true })
				or { "Preview unavailable" }
			vim.schedule(function()
				callback(lines)
			end)
		end)
	end)
end

return M
