local M = {}

---@param cfg table
---@return table
function M.list(cfg)
	local docsets = {}
	local handle = vim.uv.fs_scandir(cfg.docsets_path)

	if not handle then
		vim.notify("zeal.nvim: docsets path not found: " .. cfg.docsets_path, vim.log.levels.ERROR)
		return docsets
	end

	while true do
		local name, type = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "directory" and name:match("%.docset$") then
			table.insert(docsets, {
				name = name:gsub("%.docset$", ""),
				path = cfg.docsets_path .. "/" .. name,
			})
		end
	end

	table.sort(docsets, function(a, b)
		return a.name < b.name
	end)

	return docsets
end

---@param name string
---@param cfg table
function M.find(name, cfg)
	for _, d in ipairs(M.list(cfg)) do
		if d.name:lower() == name:lower() then
			return d
		end
	end
end

---@param docset table
---@return table
function M.entries(docset)
	local db = docset.path .. "/Contents/Resources/docSet.dsidx"
	local raw =
		vim.fn.systemlist(string.format("sqlite3 '%s' \"SELECT name, path FROM searchIndex ORDER BY name\"", db))
	local entries = {}

	for _, line in ipairs(raw) do
		local entry_name, path = line:match("^(.-)|(.+)$")
		if entry_name and path then
			table.insert(entries, {
				display = entry_name,
				path = docset.path .. "/Contents/Resources/Documents/" .. path:match("^([^#]+)"),
			})
		end
	end
	return entries
end

return M
