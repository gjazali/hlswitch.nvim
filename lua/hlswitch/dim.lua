--- Colour suppression for comment mode.

local config = require('hlswitch.config')

local M = {}

local COMMENT_TARGETS = {
  Comment = true,
  SpecialComment = true,
  Todo = true,
}

local namespace = vim.api.nvim_create_namespace('hlswitch_dim')
local considered = {}
local attached = {}
local scanned_syntax = {}
local scanned_captures = false

--- Whether a highlight group should lose its colour in comment mode.
---@param name string Highlight group name.
---@return boolean dim
local function should_dim(name)
  if name:lower():find('comment', 1, true) then
    return false
  end
  for _, pattern in ipairs(config.options.keep_groups) do
    if name:match(pattern) then
      return false
    end
  end
  local resolved =
    vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(name)), 'name')
  if COMMENT_TARGETS[resolved] then
    return false
  end
  local definition = vim.api.nvim_get_hl(0, { name = name, link = false })
  return next(definition) ~= nil
end

--- Blanks out colours for groups in `names` within the namespace.
---@param names string[] Highlight group names to consider.
---@return boolean added True if any new overrides were created.
local function define(names)
  local added = false
  for _, name in ipairs(names) do
    if not considered[name] then
      considered[name] = true
      local ok, dim = pcall(should_dim, name)
      if ok and dim then
        vim.api.nvim_set_hl(namespace, name, {})
        added = true
      end
    end
  end
  return added
end

--- Lists the syntax groups defined for a buffer.
---@param buf integer Buffer handle.
---@return string[] names
local function syntax_groups(buf)
  local ok, output = pcall(function()
    return vim.api.nvim_buf_call(buf, function()
      return vim.api.nvim_exec2('syntax list', { output = true }).output
    end)
  end)
  if not ok or type(output) ~= 'string' then
    return {}
  end
  local names = {}
  for line in output:gmatch('[^\n]+') do
    local name = line:match('^(%a[%w_.]*)%s+xxx')
    if name then
      names[#names + 1] = name
    end
    -- Include matchgroups
    for group in line:gmatch('matchgroup=(%a[%w_.]*)') do
      if group ~= 'NONE' then
        names[#names + 1] = group
      end
    end
  end
  return names
end

--- Lists all highlight groups starting with `@` (treesitter/LSP captures).
---@return string[] names
local function capture_groups()
  local names = {}
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:sub(1, 1) == '@' then
      names[#names + 1] = name
    end
  end
  return names
end

--- Reapplies the namespace on all attached windows.
local function reattach()
  for win in pairs(attached) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_hl_ns(win, namespace)
    else
      attached[win] = nil
    end
  end
end

--- Scans for highlight groups a buffer uses and adds overrides.
---@param buf integer Buffer handle.
function M.prepare(buf)
  local added = false
  if not scanned_captures then
    scanned_captures = true
    added = define(capture_groups())
  end
  local syntax = vim.b[buf].current_syntax
  if syntax and not scanned_syntax[syntax] then
    scanned_syntax[syntax] = true
    added = define(syntax_groups(buf)) or added
  end
  if added then
    reattach()
  end
end

--- Applies the dimming namespace to a window.
---@param win integer Window handle.
function M.attach(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_set_hl_ns(win, namespace)
  attached[win] = true
end

--- Restores a window to global highlights if HlSwitch changed them.
---@param win integer Window handle.
function M.detach(win)
  if not attached[win] then
    return
  end
  attached[win] = nil
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_hl_ns(win, 0)
  end
end

--- Removes tracking for a closed window.
---@param win integer Window handle.
function M.forget(win)
  attached[win] = nil
end

--- Clears all overrides and rescans from scratch.
function M.reset()
  for _, win in ipairs(vim.tbl_keys(attached)) do
    M.detach(win)
  end
  namespace = vim.api.nvim_create_namespace('')
  considered = {}
  scanned_syntax = {}
  scanned_captures = false
end

--- Returns the active namespace for comment mode.
---@return integer namespace
function M.namespace()
  return namespace
end

return M
