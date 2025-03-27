local M = {}

-- Store Neovim start time
M.start_time = os.time()

-- Function to calculate uptime
M.get_uptime = function()
	local current_time = os.time()
	local elapsed = os.difftime(current_time, M.start_time)

	-- Convert seconds to hours, minutes, seconds
	local hours = math.floor(elapsed / 3600)
	local minutes = math.floor((elapsed % 3600) / 60)
	local seconds = elapsed % 60

	return string.format("Neovim Uptime: %02d:%02d:%02d", hours, minutes, seconds)
end

-- Command to display uptime
vim.api.nvim_create_user_command("Uptime", function()
	print(M.get_uptime())
end, {})

return M
