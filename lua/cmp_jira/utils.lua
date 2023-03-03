local M = {}

M.api_url = function ()
  local subdomain = vim.env.JIRA_SUBDOMAIN

  if not subdomain then
    vim.notify "JIRA_SUBDOMAIN environment variable must be set"
    return
  end

  return "https://"..subdomain..".atlassian.net/rest/api/2/search"..M.query()
end

M.query = function ()
  local assignee = vim.env.JIRA_ASSIGNEE

  if not assignee then
    vim.notify "JIRA_USERNAME environment variable must be set"
    return
  end

  return "?jql=assignee%20%3D%20%22"..assignee.."%22%20AND%20status%20%21%3D%20Done&fields=key,summary"
end

M.authorization_header = function ()
  local username = vim.env.JIRA_USERNAME
  local token = vim.env.JIRA_TOKEN

  if not username or not token then
    vim.notify "JIRA_USERNAME and JIRA_TOKEN environment variable(s) must be set"
    return
  end

  return string.format("%s:%s", username, token)
end

return M
