local ido = require "ido"
local api = vim.api
local fn = vim.fn
local directory_name

-- Set the prompt -{{{
local function ido_browser_set_prompt()

  -- This is an action used more than once, so I decided to abstract it out into a function.
  ido.vars.prompt = string.format("Browse (%s): ",
  string.gsub(fn.resolve(directory_name), '^' .. os.getenv('HOME'), '~'))
end
-- }}}
-- Directory Browser -{{{
function ido_browser()
  directory_name = vim.loop.cwd()

  ido_browser_set_prompt()

  return ido.complete {
    prompt = ido.vars.prompt:gsub(' $', ''),
    items = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name)),

    keybinds = {
      ["<BS>"]     = 'ido_browser_backspace',
      ["<Return>"] = 'ido_browser_accept',
      ["<Tab>"]    = 'ido_browser_prefix',
    },

    on_enter = function(s) directory_name = vim.loop.cwd() end
  }

end
-- }}}
-- Custom backspace in ido_browser -{{{
function ido_browser_backspace()
  if ido.vars.pattern_text == '' then
    directory_name = fn.fnamemodify(directory_name, ':h')

    ido_browser_set_prompt()
    ido.vars.match_list = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name))
    ido.get_matches()
  else
    ido.key_backspace()
  end
end
-- }}}
-- Accept current item in ido_browser -{{{
function ido_browser_accept()
  if ido.vars.current_item == '' then
    ido.vars.current_item = ido.vars.pattern_text
  end

  if fn.isdirectory(directory_name .. '/' .. ido_current_item) == 1 then
    directory_name = directory_name .. '/' .. ido_current_item
    ido.vars.match_list = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name))
    ido.vars.pattern_text, ido.vars.before_cursor, ido.vars.after_cursor = '', '', ''
    ido.vars.cursor_position = 1
    ido.get_matches()
    ido_browser_set_prompt()
  else
    ido.close_window()
    return vim.cmd('edit ' .. directory_name .. '/' .. ido.vars.current_item)
  end
end
-- }}}
-- Modified prefix acception in ido_browser -{{{
function ido_browser_prefix()
  ido.complete_prefix()

  if ido.vars.prefix_text == ido.vars.current_item and #ido.vars.matched_items == 0 and
    ido.vars.prefix_text ~= '' then

    ido_browser_accept()
  end
end
-- }}}
