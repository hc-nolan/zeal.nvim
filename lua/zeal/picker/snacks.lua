local browser = require("zeal.browser")
local cfg = require("zeal").config
local M = {}

---@param entries table
---@param title string
---@param query? string
function M.entry_picker(entries, title, query)
	local snacks = require("snacks")
	local picker_cfg = cfg.picker.snacks
	local items = {}

	for _, e in ipairs(entries) do
		table.insert(items, { text = e.display, path = e.path })
	end

	snacks.picker({
		items = items,
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal [" .. title .. "]",
		pattern = query or "",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param docsets table
---@param on_choice function  Function to call upon selection
function M.pick_docsets(docsets, on_choice)
	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, d in ipairs(docsets) do
		table.insert(items, { text = d.name, name = d.name, path = d.path, file = d.path })
	end

	snacks.picker({
		items = items,
		format = function(d)
			return {
				{ d.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			on_choice(choice)
		end,
		preview = "none",
	})
end

---@param languages table  Table of languages read from Zeal docset index
---@param callback function|nil  Optional callback function
function M.pick_download(languages, callback)
	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, e in ipairs(languages) do
		table.insert(items, { text = e.name, name = e.name })
	end

	snacks.picker({
		items = items,
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			if choice then
				require("zeal.download").download_lang(choice.name)
				if callback then
					callback(choice.name)
				end
			end
		end,
		preview = "none",
	})
end

return M
