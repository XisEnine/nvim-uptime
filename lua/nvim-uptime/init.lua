local M = {}
local start_time = nil
local session_purpose = nil
local report_file = vim.fn.stdpath("data") .. "/uptime_report.md"

-- Ensure the report file exists and has the correct header
local function ensure_report_file()
  local file = io.open(report_file, "r")
  if not file then
    file = io.open(report_file, "w")
    if file then
      file:write("# Uptime Report\n\n")  -- Markdown title
      file:write("| Date | Session Purpose | Duration | Achieved |\n")
      file:write("|------|-----------------|----------|----------|\n")
      file:close()
    else
      print("⚠️ Failed to create uptime report file!")
      return false
    end
  else
    file:close()
  end
  return true
end

-- Get current time
local function current_time()
  return os.time()
end

-- Format time as HH:MM:SS
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60
  return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Get formatted current date
local function get_current_date()
  return os.date("%Y-%m-%d")
end

-- Write session details to the markdown file
local function write_to_report(purpose, duration, achieved)
  if not ensure_report_file() then return end
  
  local file = io.open(report_file, "a")
  if file then
    -- Escape any Markdown special characters in the purpose
    local escaped_purpose = purpose:gsub("|", "\\|")
    local current_date = get_current_date()
    
    file:write(string.format("| %s | %s | %s | %s |\n", 
      current_date, escaped_purpose, duration, achieved))
    file:close()
    print("📜 Uptime session recorded in uptime_report.md")
    
    -- Automatically open the report file for the user
    vim.cmd("e " .. report_file)
  else
    print("⚠️ Failed to write to uptime report!")
  end
end

-- Start tracking uptime
M.start = function()
  -- Check if a session is already in progress
  if start_time then
    print("⚠️ An uptime session is already in progress!")
    return
  end

  vim.ui.input({ prompt = "Enter purpose of this session: " }, function(input)
    if input and input ~= "" then
      session_purpose = input
      start_time = current_time()
      print("✅ Uptime tracking started! Purpose: " .. session_purpose)
    else
      print("⚠️ Session purpose cannot be empty!")
    end
  end)
end

-- Stop tracking uptime
M.stop = function()
  if not start_time then
    print("⚠️ No active uptime session!")
    return
  end
  
  local elapsed = current_time() - start_time
  local formatted_time = format_time(elapsed)
  
  vim.ui.input({ prompt = "Did you achieve your purpose? (yes/no): " }, function(response)
    local achieved = (response and response:lower() == "yes") and "✅ Yes" or "❌ No"
    write_to_report(session_purpose, formatted_time, achieved)
    
    -- Reset session
    start_time = nil
    session_purpose = nil
  end)
end

-- Open the report file anytime
M.report = function()
  if ensure_report_file() then
    vim.cmd("e " .. report_file)
  end
end

-- Register commands
vim.api.nvim_create_user_command("UptimeStart", M.start, {})
vim.api.nvim_create_user_command("UptimeStop", M.stop, {})
vim.api.nvim_create_user_command("UptimeReport", M.report, {})

return M
