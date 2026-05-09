local M = {}

M.current = false
M.term = nil

---@param entry table
---@param cfg table
function M.open(entry, cfg)
	if cfg.use_toggleterm and M.current then
		M.toggle()
		return
	end

	if not cfg.use_toggleterm then
		vim.cmd(cfg.split)
		vim.cmd("term " .. cfg.browser .. " '" .. entry.path .. "'")
		vim.cmd("startinsert")
		return
	end

	local Term = require("toggleterm.terminal").Terminal
	local t = Term:new({
		cmd = cfg.browser .. " '" .. entry.path .. "'",
		close_on_exit = true,
		direction = cfg.toggleterm.direction,
		display_name = "Zeal Term",
		on_stderr = function(self, job, err, name)
			local e = ""
			for line in pairs(err) do
				e = e .. "\n" .. line
			end
			local log = "zeal.nvim: Error in terminal. Status: \n"
				.. "job: "
				.. job
				.. "\nerror: "
				.. e
				.. "\nname: "
				.. name
			vim.notify(log, vim.log.levels.ERROR)
		end,
		on_exit = function()
			M.current = false
			M.term = nil
		end,
	})

	M.term = t
	M.current = true
	t:toggle()

	if cfg.toggleterm.direction == ("vertical" or "horizontal") then
		t:resize(cfg.toggleterm.split_size)
	end
end

function M.toggle()
	if M.current and M.term then
		M.term:toggle()
	else
		vim.notify("zeal.nvim: No docset terminal present.", vim.log.levels.INFO)
	end
end

return M
