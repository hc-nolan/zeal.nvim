local M = {}

---@param entry table
---@param cfg table
function M.open(entry, cfg)
	vim.cmd(cfg.split)
	vim.cmd("term " .. cfg.browser .. " '" .. entry.path .. "'")
	vim.cmd("startinsert")
end

return M
