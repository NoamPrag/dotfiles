local config = require("aerial.config")

local M = {}

---@param client table
---@return boolean
M.client_supports_symbols = function(client)
  return client.server_capabilities.documentSymbolProvider
    and config.lsp.priority[client.name] ~= -1
end

---@param bufnr integer
---@param exclude_id nil|integer Client ID to exclude from calculation
---@return nil|table
M.get_client = function(bufnr, exclude_id)
  local ret
  local last_priority = -1
  for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
    local priority = config.lsp.priority[client.name] or 10
    if
      client.id ~= exclude_id
      and M.client_supports_symbols(client)
      and priority > last_priority
    then
      ret = client
      last_priority = priority
    end
  end
  return ret
end

return M
