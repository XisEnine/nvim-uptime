local M = {}
local start_time = nil
local session_purpose = nil
local report_file = vim.fn.stdpath("data") .. "/uptime_report.md"

-- Helper: Get Downloads path for any OS (unchanged)
local function get_downloads_path()
	if vim.fn.has("win32") == 1 then
		return os.getenv("USERPROFILE") .. "\\Downloads\\"
	else
		return os.getenv("HOME") .. "/Downloads/"
	end
end

-- Helper: Trim whitespace from a string (unchanged)
local function trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1")
end

-- File initialization: Create basic report structure
local function ensure_report_file()
	if vim.fn.filereadable(report_file) == 0 then
		local header = {
			"# Uptime Report",
			"",
		}
		local ok, err = pcall(vim.fn.writefile, header, report_file)
		if not ok then
			vim.notify("⚠️ Failed to create report: " .. err, vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

-- Reset report (unchanged)
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

-- Export report (unchanged)
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

-- Format time (unchanged)
local function format_time(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Write session details as a Markdown snippet
local function write_to_report(purpose, duration, achieved, note)
	if not ensure_report_file() then
		return
	end

	local current_date = os.date("%Y-%m-%d")
	local entry = {
		"",
		string.format("### %s - %s", current_date, purpose),
		string.format("**Duration**: %s  ", duration),
		string.format("**Achieved**: %s  ", achieved),
		string.format("**Notes**: %s  ", note or "-"),
		"",
		"---",
	}

	local file = io.open(report_file, "a")
	if file then
		file:write(table.concat(entry, "\n") .. "\n")
		file:close()
		vim.notify("📜 Uptime session recorded", vim.log.levels.INFO)
		vim.cmd("edit " .. vim.fn.fnameescape(report_file))
	else
		vim.notify("⚠️ Failed to write to report!", vim.log.levels.ERROR)
	end
end

-- Start/Stop functions remain unchanged
function M.start()
	-- ... (same as original) ...
end

function M.stop()
	-- ... (same as original) ...
end

-- ... (remaining functions and commands remain unchanged) ...

return M
