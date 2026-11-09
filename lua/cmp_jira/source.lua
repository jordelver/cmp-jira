local source = {}

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

source.new = function()
  local tbl = setmetatable({ cache = nil }, { __index = source })
  tbl:fetch_issues(nil)
  return tbl
end

source.fetch_issues = function(self, callback)
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
      local function finish(items)
        if callback ~= nil and type(callback) == "function" then
          callback { items = items, isIncomplete = false }
        end
      end

      -- jira may fail (auth, network, API changes) or list no issues; neither must raise in this callback
      if obj.code ~= 0 or not obj.stdout or obj.stdout == "" then
        if obj.code ~= 0 then
          vim.schedule(function()
            vim.notify("cmp_jira: jira exited with code " .. obj.code .. ": " .. vim.trim(obj.stderr or ""),
              vim.log.levels.WARN)
          end)
        end
        -- leave the cache empty so the next completion retries
        finish({})
        return
      end

      local lines = lines(obj.stdout)
      if #lines == 0 then
        finish({})
        return
      end
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
          issue = issue,
          filterText = string.format("%s %s %s %s", issue.KEY, issue.TYPE, issue.STATUS, issue.SUMMARY),
          documentation = string.format("[%s] [%s] [%s] %s", issue.KEY, issue.TYPE, issue.STATUS, issue.SUMMARY),
          label = string.format("[%s] %s", issue.KEY, issue.SUMMARY),
        })
      end

      self.cache = items
      finish(items)
    end
  )
end

local function add_remove_trigger_char_opts(tbl, request)
  local input = string.sub(request.context.cursor_before_line, request.offset - 1)

  tbl.items = vim.tbl_map(function(item)
    item = vim.tbl_extend("error", item, {
      textEdit = {
        newText = item.issue.KEY,
        range = {
          ["start"] = {
            line = request.context.cursor.row - 1,
            character = request.context.cursor.col - 1 - #input,
          },
          ["end"] = {
            line = request.context.cursor.row - 1,
            character = request.context.cursor.col - 1,
          },
        }
      },
    })
    return item
  end, tbl.items)

  return tbl
end

function source:complete(params, callback)
  local input = string.sub(params.context.cursor_before_line, params.offset - 1)
  local prefix = string.sub(params.context.cursor_before_line, 1, params.offset - 1)
  -- Only complete at the beginning of the line and when the trigger character has been typed.
  if vim.startswith(input, '#') and (prefix == '#') then
    if not self.cache then
      self:fetch_issues(function(tbl)
        tbl = add_remove_trigger_char_opts(tbl, params)
        callback(tbl)
      end)
    else
      local tbl = { items = self.cache, isIncomplete = false }
      tbl = add_remove_trigger_char_opts(tbl, params)
      callback(tbl)
    end
  else
    callback({ isIncomplete = true })
  end
end

function source:execute(completion_item, callback)
  print(vim.inspect(completion_item))
  callback(completion_item)
end

source.get_trigger_characters = function()
  return { "#" }
end

source.get_keyword_pattern = function()
  return [[#\k\+]]
end

source.is_available = function()
  return vim.bo.filetype == "gitcommit"
end

return source
