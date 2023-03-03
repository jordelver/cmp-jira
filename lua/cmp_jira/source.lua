local utils = require("cmp_jira.utils")

local ok, Job = pcall(require, "plenary.job")
if not ok then
  return
end

local source = {}

source.new = function()
  local self = setmetatable({ cache = {} }, { __index = source })

  return self
end

source.complete = function(self, _, callback)
  local bufnr = vim.api.nvim_get_current_buf()

  if not self.cache[bufnr] then
    Job
      :new({
        "curl",
        "--request",
        "GET",
        "--header",
        "Content-Type: application/json",
        "--user",
        utils.authorization_header(),
        utils.api_url(),
        on_exit = function(job)
          local result = job:result()
          local ok, parsed = pcall(vim.json.decode, table.concat(result, ""))
          if not ok then
            vim.notify "Failed to parse curl result"
            return
          end

          local items = {}
          for _, jira_issue in ipairs(parsed["issues"]) do
            table.insert(items, {
              label = string.format("# %s %s", jira_issue.key, jira_issue["fields"]["summary"]),
              insertText = jira_issue.key, -- the text to insert when completed
            })
          end

          callback { items = items, isIncomplete = false }
          self.cache[bufnr] = items
        end,
      })
      :start()
  else
    callback { items = self.cache[bufnr], isIncomplete = false }
  end
end

source.get_trigger_characters = function()
  return { "#" }
end

source.get_keyword_pattern = function()
  return string.format("[%s]\\S*", "#")
end

source.is_available = function()
  return vim.bo.filetype == "gitcommit"
end

return source
