--- Plugin entry point: commands and startup.

if vim.g.loaded_hlswitch == 1 then
  return
end
vim.g.loaded_hlswitch = 1

require('hlswitch').setup()

local function command(name, run, opts)
  vim.api.nvim_create_user_command(name, run, opts or {})
end

command('HlSwitchOn', function()
  require('hlswitch').set('on')
end, { desc = 'HlSwitch: highlight everything in this buffer' })

command('HlSwitchOff', function()
  require('hlswitch').set('off')
end, { desc = 'HlSwitch: highlight nothing in this buffer' })

command('HlSwitchComment', function()
  require('hlswitch').set('comment')
end, { desc = 'HlSwitch: highlight comments only in this buffer' })

command('HlSwitch', function(opts)
  require('hlswitch').set(opts.args)
end, {
  nargs = 1,
  desc = 'HlSwitch: set this buffer to off, on or comment',
  complete = function(lead)
    return vim.tbl_filter(function(name)
      return name:find(lead, 1, true) == 1
    end, { 'off', 'on', 'comment' })
  end,
})

command('HlSwitchTSOn', function()
  require('hlswitch').treesitter_on()
end, { desc = 'HlSwitch: start the treesitter highlighter here' })

command('HlSwitchTSOff', function()
  require('hlswitch').treesitter_off()
end, { desc = 'HlSwitch: stop the treesitter highlighter here' })
