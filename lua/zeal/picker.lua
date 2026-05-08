local docsets = require("zeal.docsets")
local browser = require("zeal.browser")
local M = {}

---@param docset table
---@param cfg table
function M.pick_entry(docset, cfg)
	local entries = docsets.entries(docset)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found in " .. docset.name, vim.log.levels.WARN)
		return
	end

	vim.ui.select(entries, {
		prompt = "Zeal [" .. docset.name .. "]",
		format_item = function(e)
			return e.display
		end,
	}, function(choice)
		if choice then
			browser.open(choice, cfg)
		end
	end)
end

---@param cfg table
function M.pick_docset(cfg)
	local all = docsets.list(cfg)

	if #all == 0 then
		return
	end

	if #all == 1 then
		M.pick_entry(all[1], cfg)
		return
	end

	vim.ui.select(all, {
		prompt = "Zeal docsets",
		format_item = function(d)
			return d.name
		end,
	}, function(choice)
		if choice then
			M.pick_entry(choice, cfg)
		end
	end)
end

return M
