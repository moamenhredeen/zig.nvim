
---@class Executor
local M = {}


---@private
---@type integer | nil id of the last opened and not yet closed buffer 
local latest_buf_id = nil

-- TODO: do we still need this 
---@private
---@type integer | nil
local latest_win_id = nil

---@private
---@class win_config default window configuration
---@field split "right" | "left" | "above" | "below" direction of the split
---@field height integer  height of the output window
---@field width integer  width of the output window
local win_config = {
	split = "below",
	height = 20,
	width = 20
}

---@public execute command asyncronously and show the output in a split
---@param command string | string[]: command to execute
---@param opts { cwd: string } options
function M.execute_command(command, opts)

	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	if not latest_buf_id then
		latest_buf_id = vim.api.nvim_create_buf(false, true)
	end

	if (not latest_win_id) or (not vim.api.nvim_win_is_valid(latest_win_id)) then
		latest_win_id = vim.api.nvim_open_win(latest_buf_id, false, win_config)
		vim.wo[latest_win_id].number = false
	end

	-- hide the buffer when escape s pressed :)
	vim.keymap.set('n', '<Esc>', '<CMD>hide<CR>', { buffer = latest_buf_id, noremap = true })
	vim.keymap.set('n', 'q', '<CMD>hide<CR>', { buffer = latest_buf_id, noremap = true })

		-- TODO: how to save window size
	-- vim.api.nvim_create_autocmd("WinResized", {
	-- 	group = vim.api.nvim_create_augroup("zig-output-resized", {}),
	-- 	callback = function ()
	-- 		if latest_win_id and vim.api.nvim_win_is_valid(latest_win_id) then
	-- 			win_config.width = vim.api.nvim_win_get_width(latest_win_id)
	-- 			win_config.height = vim.api.nvim_win_get_width(latest_win_id)
	-- 		end
	-- 	end
	-- })

	vim.api.nvim_create_autocmd("QuitPre", {
		group = vim.api.nvim_create_augroup("zig-output-closed", {}),
		callback = function ()
			if latest_win_id then
				latest_win_id = nil
				latest_buf_id = nil
			end
		end
	})

	-- run the command
	-- vim.fn.termopen(command)
	vim.api.nvim_buf_set_lines(latest_buf_id, 0, -1, false, {})
	vim.fn.jobstart(command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function (_, data)
			if not data then
				return
			end
			vim.schedule(function ()
				vim.api.nvim_buf_set_lines(latest_buf_id, -1, -1, false, data)
				vim.api.nvim_win_set_cursor(latest_win_id, {vim.api.nvim_buf_line_count(latest_buf_id), 0})
			end)
		end,
		on_stderr = function (_, data)
			if not data then
				return
			end
			vim.schedule(function ()
				vim.api.nvim_buf_set_lines(latest_buf_id, -1, -1, false, data)
				vim.api.nvim_win_set_cursor(latest_win_id, {vim.api.nvim_buf_line_count(latest_buf_id), 0})
			end)
		end
	})
end

return M
