--- Per-buffer mode tracking.

local config = require('hlswitch.config')

local M = {}

M.OFF = 0
M.ON = 1
M.COMMENT = 2

M.NAMES = { [M.OFF] = 'off', [M.ON] = 'on', [M.COMMENT] = 'comment' }

local ALIASES = {
  off = M.OFF,
  none = M.OFF,
  on = M.ON,
  all = M.ON,
  full = M.ON,
  comment = M.COMMENT,
  comments = M.COMMENT,
}

--- Converts a mode value to its numeric form.
---@param value number|string|nil A mode like `2` or `'comment'`.
---@return number|nil mode Nil if `value` is not a valid mode.
function M.resolve(value)
  if type(value) == 'number' then
    return M.NAMES[value] and value or nil
  end
  if type(value) == 'string' then
    local numeric = tonumber(value)
    if numeric then
      return M.NAMES[numeric] and numeric or nil
    end
    return ALIASES[value:lower()]
  end
  return nil
end

--- Returns a buffer's current mode.
---@param buf integer Buffer handle.
---@return number|nil mode Nil if the buffer has no mode set.
function M.get(buf)
  return vim.b[buf].hlswitch_mode
end

--- Stores a buffer's mode without changing highlighting.
---@param buf integer Buffer handle.
---@param mode number The mode to store.
---@param explicit boolean|nil True if the user set this mode directly.
function M.set(buf, mode, explicit)
  vim.b[buf].hlswitch_mode = mode
  if explicit then
    vim.b[buf].hlswitch_explicit = true
  end
end

--- Whether a buffer's mode was set by the user, not computed from defaults.
---@param buf integer Buffer handle.
---@return boolean explicit
function M.is_explicit(buf)
  return vim.b[buf].hlswitch_explicit == true
end

--- Returns the default mode for a buffer based on its filetype.
---@param buf integer Buffer handle.
---@return number mode
function M.default_for(buf)
  local options = config.options
  local filetype = vim.bo[buf].filetype
  local wanted = options.default_by_filetype[filetype]
  if wanted == nil and filetype == '' and vim.bo[buf].buflisted then
    wanted = options.no_filetype_default
  end
  if wanted == nil then
    wanted = options.default
  end
  return M.resolve(wanted) or M.ON
end

return M
