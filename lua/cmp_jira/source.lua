local source = {}

local cache = {}

local function split(str, pattern)
  local splitted = {}
  for s in str:gmatch(pattern) do
    table.insert(splitted, s)
  end
  return splitted
end

local function lines(str)
  return split(str, "[^\r\n]+")
end

local function fetch_issues(callback)
  vim.system(
    {
      (vim.uv.os_uname().sysname == "Windows_NT") and "jira.exe" or "jira",
      "issue",
      "list",
      "--assignee",
      "christian.heinigk@vector.com",
      "--plain"
    }, { text = true },
    function(obj)
      local lines = lines(obj.stdout)
      lines = vim.tbl_map(function(value)
        return value:gsub("\t+", ";")
      end, lines)

      local headers = split(lines[1], "[^;]+")
      local body = { unpack(lines, 2) }
      local issues = {}
      for _, value in ipairs(body) do
        local issue = {}
        local row = split(value, "[^;]+")
        for col, header in ipairs(headers) do
          issue[header] = row[col]
        end
        table.insert(issues, issue)
      end

      local items = {}
      for _, issue in ipairs(issues) do
        table.insert(items, {
          label = string.format("%s %s %s %s", issue.KEY, issue.TYPE, issue.STATUS, issue.SUMMARY),
          insertText = issue.KEY, -- the text to insert when completed
        })
      end

      if callback ~= nil and type(callback) == "function" then
        callback { items = items, isIncomplete = false }
      end
      cache = items
    end
  )
end

source.new = function()
  fetch_issues(nil)
  return setmetatable({ cache = {} }, { __index = source })
end

source.complete = function(self, request, callback)
  if not self.cache then
    fetch_issues(callback)
  else
    callback { items = cache, isIncomplete = false }
  end
end

source.get_trigger_characters = function()
  return { "$" }
end

source.get_keyword_pattern = function()
  return [[$\S*]]
end

source.is_available = function()
  return vim.bo.filetype == "gitcommit"
end

return source
