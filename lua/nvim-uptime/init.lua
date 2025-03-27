local M = {}
local start_time = nil
local session_purpose = nil
local report_file = vim.fn.stdpath("data") .. "/uptime_report.md"

-- Helper: Get Downloads path for any OS
local function get_downloads_path()
	if vim.fn.has("win32") == 1 then
		return os.getenv("USERPROFILE") .. "\\Downloads\\"
	else
		return os.getenv("HOME") .. "/Downloads/"
	end
end

-- Helper: Trim whitespace from a string
local function trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1")
end

-- File initialization: Ensure the report file exists with the proper header
local function ensure_report_file()
	if vim.fn.filereadable(report_file) == 0 then
		local header = {
			"# Uptime Report",
			"",
			"| Date | Session Purpose | Duration | Achieved | Notes |",
			"|------|-----------------|----------|----------|-------|",
		}
		local ok, err = pcall(vim.fn.writefile, header, report_file)
		if not ok then
			vim.notify("⚠️ Failed to create report: " .. err, vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

-- Reset report: Delete all data after confirmation
local function reset_report()
	vim.ui.input({
		prompt = "Are you sure? This will DELETE all data! (y/n): ",
	}, function(response)
		if response and response:lower():sub(1, 1) == "y" then
			os.remove(report_file)
			ensure_report_file()
			vim.notify("🗑️ Report reset to empty!", vim.log.levels.INFO)
		else
			vim.notify("Reset canceled", vim.log.levels.INFO)
		end
	end)
end

-- Export report: Copy the report file to the Downloads folder and open it
local function export_report()
	local downloads_dir = get_downloads_path()
	local export_path = downloads_dir .. "uptime_report.md"

	if vim.fn.filereadable(report_file) == 0 then
		vim.notify("⚠️ No report to export!", vim.log.levels.WARN)
		return
	end

	local ok, err = pcall(function()
		local content = vim.fn.readfile(report_file)
		vim.fn.writefile(content, export_path)
	end)

	if ok then
		vim.notify("📤 Exported to: " .. export_path, vim.log.levels.INFO)
		vim.schedule(function()
			vim.cmd("edit " .. vim.fn.fnameescape(export_path))
		end)
	else
		vim.notify("⚠️ Export failed: " .. err, vim.log.levels.ERROR)
	end
end

-- Format time (in seconds) to HH:MM:SS
local function format_time(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Write session details to the report file (including Notes)
local function write_to_report(purpose, duration, achieved, note)
	if not ensure_report_file() then
		return
	end

	local current_date = os.date("%Y-%m-%d")
	local escaped_purpose = purpose:gsub("|", "\\|")
	local escaped_note = (note or ""):gsub("|", "\\|")
	local line =
		string.format("| %s | %s | %s | %s | %s |\n", current_date, escaped_purpose, duration, achieved, escaped_note)
	local file = io.open(report_file, "a")
	if file then
		file:write(line .. "\n") -- Add an extra newline for a break between entries
		file:close()
		vim.notify("📜 Uptime session recorded in uptime_report.md", vim.log.levels.INFO)
		-- Automatically open the report file for the user
		vim.cmd("edit " .. vim.fn.fnameescape(report_file))
	else
		vim.notify("⚠️ Failed to write to uptime report!", vim.log.levels.ERROR)
	end
end

-- Start tracking uptime: Prompt for the session purpose and record the start time
function M.start()
	if start_time then
		vim.notify("⚠️ An uptime session is already in progress!", vim.log.levels.WARN)
		return
	end

	vim.ui.input({ prompt = "Enter purpose of this session: " }, function(input)
		if input and trim(input) ~= "" then
			session_purpose = input
			start_time = os.time()
			vim.notify("✅ Uptime tracking started! Purpose: " .. session_purpose, vim.log.levels.INFO)
		else
			vim.notify("⚠️ Session purpose cannot be empty!", vim.log.levels.WARN)
		end
	end)
end

-- Stop tracking uptime: Calculate duration, ask if the purpose was achieved and prompt for notes, then record the session
function M.stop()
	if not start_time then
		vim.notify("⚠️ No active uptime session!", vim.log.levels.WARN)
		return
	end

	local elapsed = os.time() - start_time
	local formatted_duration = format_time(elapsed)

	vim.ui.input({ prompt = "Did you achieve your purpose? (yes/no): " }, function(response)
		local achieved = (response and response:lower():match("^y")) and "✅ Yes" or "❌ No"
		vim.ui.input({ prompt = "Enter any notes for this session (optional): " }, function(note)
			local trimmed_note = note and trim(note) or ""
			write_to_report(session_purpose, formatted_duration, achieved, trimmed_note)
			start_time = nil
			session_purpose = nil
		end)
	end)
end

-- Open the report file so the user can view their sessions
function M.report()
	if ensure_report_file() then
		vim.cmd("edit " .. vim.fn.fnameescape(report_file))
	end
end

-- Register commands
vim.api.nvim_create_user_command("UptimeStart", M.start, {})
vim.api.nvim_create_user_command("UptimeStop", M.stop, {})
vim.api.nvim_create_user_command("UptimeReport", M.report, {})
vim.api.nvim_create_user_command("UptimeReset", reset_report, {})
vim.api.nvim_create_user_command("UptimeExport", export_report, {})

return M
