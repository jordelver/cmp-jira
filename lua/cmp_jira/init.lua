local source = require("cmp_jira.source")

local M = {}

M.setup = function()
  require("cmp").register_source("jira", source.new())
end

return M
