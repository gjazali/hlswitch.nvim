--- Per-buffer syntax highlighting control with three modes: `on`
--- (everything), `off` (nothing), and `comment` (comments only).

local config = require('hlswitch.config')
local dim = require('hlswitch.dim')
local engine = require('hlswitch.engine')
local state = require('hlswitch.state')

local M = {}

M.OFF = state.OFF
M.ON = state.ON
M.COMMENT = state.COMMENT

--- Sets a buffer's highlighting mode.
---@param mode number|string 0/1/2 or 'off'/'on'/'comment'.
---@param opts table|nil `buf`: buffer handle (default: current).
---                      `explicit`: if false, filetype detection can override.
---@return boolean applied False if `mode` is invalid.
function M.set(mode, opts)
  opts = opts or {}
  local resolved = state.resolve(mode)
  if not resolved then
    vim.notify(
      ('HlSwitch: unknown mode %s'):format(vim.inspect(mode)),
      vim.log.levels.ERROR
    )
    return false
  end
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  state.set(buf, resolved, opts.explicit ~= false)
  engine.apply(buf, resolved)
  return true
end

--- Returns a buffer's current mode without changing anything.
---@param buf integer|nil Buffer handle (default: current).
---@return number|nil mode Nil if the buffer has no mode set.
function M.get(buf)
  return state.get(buf or vim.api.nvim_get_current_buf())
end

--- Returns a buffer's mode as a string, for statuslines.
---@param buf integer|nil Buffer handle (default: current).
---@return string name 'off', 'on', 'comment', or '' if unset.
function M.status(buf)
  local mode = M.get(buf)
  return mode and state.NAMES[mode] or ''
end

--- Returns a buffer's mode, computing and saving its default if unset.
---@param buf integer Buffer handle.
---@return number mode
local function settled_mode(buf)
  local mode = state.get(buf)
  if mode == nil then
    mode = state.default_for(buf)
    state.set(buf, mode)
  end
  return mode
end

--- Reapplies a buffer's mode, computing the default if unset.
---@param buf integer|nil Buffer handle (default: current).
function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  engine.apply(buf, settled_mode(buf))
end

--- Reapplies modes on all loaded buffers.
---@param redefault boolean|nil True to recompute defaults for buffers
---                             whose mode was not set explicitly.
function M.refresh_all(redefault)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      if redefault and not state.is_explicit(buf) then
        state.set(buf, state.default_for(buf))
      end
      M.refresh(buf)
    end
  end
end

--- Rebuilds comment mode's highlight data and refreshes all buffers.
function M.rescan()
  dim.reset()
  M.refresh_all()
end

--- Starts treesitter highlighting on the current buffer.
function M.treesitter_on()
  local buf = vim.api.nvim_get_current_buf()
  engine.treesitter_on(buf)
  engine.apply(buf, settled_mode(buf), { treesitter = false })
end

--- Stops treesitter highlighting on the current buffer.
function M.treesitter_off()
  local buf = vim.api.nvim_get_current_buf()
  engine.treesitter_off(buf)
  engine.apply(buf, settled_mode(buf), { treesitter = false })
end

--- Sets up autocommands.
local function create_autocommands()
  local group = vim.api.nvim_create_augroup('HlSwitch', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
    group = group,
    callback = function(args)
      M.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(args)
      if not state.is_explicit(args.buf) then
        state.set(args.buf, state.default_for(args.buf))
      end
      M.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      vim.schedule(function()
        vim.schedule(function()
          M.refresh(args.buf)
        end)
      end)
    end,
  })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(args)
      M.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'WinEnter', 'WinNew' }, {
    group = group,
    callback = function()
      engine.sync_window(vim.api.nvim_get_current_win())
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(args)
      dim.forget(tonumber(args.match))
    end,
  })

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      M.rescan()
    end,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function()
      if not config.configured then
        config.set(vim.g.hlswitch)
      end
      dim.reset()
      M.refresh_all(true)
    end,
  })
end

--- Configures HlSwitch and sets up autocommands.
---@param opts table|nil See `:help hlswitch-options`.
function M.setup(opts)
  if opts ~= nil then
    config.set(opts)
    config.configured = true
  end
  if config.options.manage_syntax_option then
    vim.cmd('syntax manual')
  end
  create_autocommands()
  dim.reset()
  if vim.v.vim_did_enter == 1 then
    M.refresh_all(true)
  end
end

return M
