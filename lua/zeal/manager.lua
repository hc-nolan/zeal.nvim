local M = {}

local picker = require("zeal.picker")

--- Download a docset
---@param callback function|nil  Optional callback function
function M.download(callback)
	require("zeal.download").get_index(function(languages)
		picker.pick_download(languages, callback)
	end)
end

return M
