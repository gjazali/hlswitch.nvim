--- Option storage for HlSwitch.

local M = {}

--- Default options. Mode values accept 0/1/2 or 'off'/'on'/'comment'.
local defaults = {
  default = 1,
  default_by_filetype = {},
  no_filetype_default = 0,
  treesitter = true,
  keep_groups = {},
  manage_syntax_option = true,
}

M.options = vim.deepcopy(defaults)

M.configured = false

--- Merges `opts` into the defaults and stores the result.
---@param opts table|nil User options.
---@return table options The merged options, also stored as `M.options`.
function M.set(opts)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
  return M.options
end

--- Returns a copy of the default options.
---@return table defaults
function M.defaults()
  return vim.deepcopy(defaults)
end

return M
