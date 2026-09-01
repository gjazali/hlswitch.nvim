--- Controls regex and treesitter highlighting.

local config = require('hlswitch.config')
local dim = require('hlswitch.dim')
local state = require('hlswitch.state')

local M = {}

--- Loads syntax highlighting for a buffer if not already loaded.
---@param buf integer Buffer handle.
local function syntax_on(buf)
  vim.api.nvim_buf_call(buf, function()
    if vim.b.current_syntax == nil and vim.bo.filetype ~= '' then
      vim.bo.syntax = 'ON'
    end
  end)
end

--- Clears syntax highlighting for a buffer if not already cleared.
---@param buf integer Buffer handle.
local function syntax_off(buf)
  vim.api.nvim_buf_call(buf, function()
    if vim.b.current_syntax ~= nil then
      vim.bo.syntax = 'OFF'
    end
  end)
end

--- Whether treesitter highlighting is active on a buffer.
---@param buf integer Buffer handle.
---@return boolean running
function M.treesitter_active(buf)
  return vim.treesitter.highlighter.active[buf] ~= nil
end

--- Starts treesitter highlighting on a buffer.
---@param buf integer Buffer handle.
---@return boolean running
function M.treesitter_on(buf)
  if M.treesitter_active(buf) then
    return true
  end
  return (pcall(vim.treesitter.start, buf))
end

--- Stops treesitter highlighting on a buffer if active.
---@param buf integer Buffer handle.
function M.treesitter_off(buf)
  if M.treesitter_active(buf) then
    pcall(vim.treesitter.stop, buf)
  end
end

--- Returns LSP clients on a buffer that support semantic tokens.
---@param buf integer Buffer handle.
---@return vim.lsp.Client[] clients
local function semantic_token_clients(buf)
  return vim.tbl_filter(function(client)
    local capabilities = client.server_capabilities
    return vim.tbl_get(capabilities, 'semanticTokensProvider', 'full') and true
  end, vim.lsp.get_clients({ bufnr = buf }))
end

--- Stops semantic token highlighting and records which clients were stopped.
---@param buf integer Buffer handle.
local function semantic_tokens_off(buf)
  local stopped = {}
  for _, client in ipairs(semantic_token_clients(buf)) do
    vim.lsp.semantic_tokens.stop(buf, client.id)
    stopped[#stopped + 1] = client.id
  end
  vim.b[buf].hlswitch_stopped_clients = stopped
end

--- Restarts semantic token highlighting for clients HlSwitch stopped.
---@param buf integer Buffer handle.
local function semantic_tokens_on(buf)
  local stopped = vim.b[buf].hlswitch_stopped_clients
  if stopped == nil then
    return
  end
  vim.b[buf].hlswitch_stopped_clients = nil
  for _, client in ipairs(semantic_token_clients(buf)) do
    if vim.tbl_contains(stopped, client.id) then
      vim.lsp.semantic_tokens.start(buf, client.id)
    end
  end
end

--- Updates comment mode on all windows showing a buffer.
---@param buf integer Buffer handle.
---@param mode number|nil Mode to use (default: the buffer's current mode).
function M.sync_windows(buf, mode)
  mode = mode or state.get(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if mode == state.COMMENT then
      dim.attach(win)
    else
      dim.detach(win)
    end
  end
end

--- Updates comment mode on a single window.
---@param win integer Window handle.
function M.sync_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  if state.get(vim.api.nvim_win_get_buf(win)) == state.COMMENT then
    dim.attach(win)
  else
    dim.detach(win)
  end
end

--- Applies a mode to a buffer and its windows.
---@param buf integer Buffer handle.
---@param mode number The mode to apply.
---@param opts table|nil `treesitter`: set to false to skip managing
---                      treesitter (for callers that handle it themselves).
function M.apply(buf, mode, opts)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local drive_treesitter = config.options.treesitter
    and not (opts and opts.treesitter == false)
  if config.options.manage_syntax_option and vim.g.syntax_manual == nil then
    vim.cmd('syntax manual')
  end
  if mode == state.OFF then
    if drive_treesitter then
      M.treesitter_off(buf)
    end
    syntax_off(buf)
    semantic_tokens_off(buf)
  else
    if drive_treesitter then
      M.treesitter_on(buf)
    end
    if M.treesitter_active(buf) then
      syntax_off(buf)
    else
      syntax_on(buf)
    end
    semantic_tokens_on(buf)
  end
  if mode == state.COMMENT then
    dim.prepare(buf)
  end
  M.sync_windows(buf, mode)
end

return M
