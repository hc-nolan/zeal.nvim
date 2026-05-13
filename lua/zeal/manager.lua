local M = {}

local picker = require("zeal.picker")

--- Download a docset
---@param callback function?
function M.download(callback)
	require("zeal.download").get_index(function(languages)
		picker.pick_download(languages, callback)
	end)
end

--- Remove a docset
---@param callback function?
function M.remove(callback)
	picker.pick_removal(callback)
end

function M.manager()
	picker.pick_manager()
end

return M
