local M = {}
local start_time = nil
local session_purpose = nil
local report_file = vim.fn.stdpath("data") .. "/uptime_report.md"

-- Helper to trim whitespace
local function trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

-- Safely ensure report file exists
local function ensure_report_file()
  if vim.fn.filereadable(report_file) == 0 then
    local header = {
      "# Uptime Report",
      "",
      "| Date | Session Purpose | Duration | Achieved |",
      "|------|-----------------|----------|----------|"
    }
    local ok, err = pcall(vim.fn.writefile, header, report_file)
    if not ok then
      vim.notify("⚠️ Failed to create report file: " .. err, vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

-- Format time as HH:MM:SS
local function format_time(seconds)
  return os.date("!%H:%M:%S", seconds)
end

-- Write to report with error handling
local function write_to_report(purpose, duration, achieved)
  if not ensure_report_file() then return end

  -- Escape Markdown special characters
  local function escape_md(str)
    return str:gsub("[\\`*_{}%[%]()#+-.!|]", "\\%1")
  end

  local entry = {
    os.date("%Y-%m-%d"),
    escape_md(purpose),
    duration,
    achieved
  }

  local line = string.format("| %s | %s | %s | %s |\n", unpack(entry))
  
  local ok, err = pcall(function()
    local fd = io.open(report_file, "a")
    if not fd then error("Failed to open file") end
    fd:write(line)
    fd:close()
  end)
  
  if ok then
    vim.notify("📜 Session recorded in report", vim.log.levels.INFO)
    vim.schedule(function()
      vim.cmd("edit " .. vim.fn.fnameescape(report_file))
    end)
  else
    vim.notify("⚠️ Failed to write report: " .. err, vim.log.levels.ERROR)
  end
end

-- Start tracking
M.start = function()
  if start_time then
    vim.notify("⚠️ Session already in progress!", vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = "Session purpose: ",
    default = "General editing",
  }, function(input)
    if not input then return end
    
    local purpose = trim(input)
    if purpose == "" then
      vim.notify("⚠️ Purpose cannot be empty!", vim.log.levels.ERROR)
      return
    end

    start_time = os.time()
    session_purpose = purpose
    vim.notify("✅ Tracking started: " .. purpose, vim.log.levels.INFO)
  end)
end

-- Stop tracking
M.stop = function()
  if not start_time then
    vim.notify("⚠️ No active session!", vim.log.levels.WARN)
    return
  end

  local elapsed = os.time() - start_time
  local duration = format_time(elapsed)

  vim.ui.input({
    prompt = "Achieved goal? (y/n): ",
    default = "y",
  }, function(achieved)
    local result = (achieved:lower():sub(1,1) == "y") and "✅ Yes" or "❌ No"
    write_to_report(session_purpose, duration, result)
    start_time = nil
    session_purpose = nil
  end)
end

-- Open report
M.report = function()
  if ensure_report_file() then
    vim.cmd("edit " .. vim.fn.fnameescape(report_file))
  end
end

-- Register commands
vim.api.nvim_create_user_command("UptimeStart", M.start, {})
vim.api.nvim_create_user_command("UptimeStop", M.stop, {})
vim.api.nvim_create_user_command("UptimeReport", M.report, {})

return M
