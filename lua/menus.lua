require "ido"
local api = vim.api
local fn = vim.fn
local directory_name

-- Set the prompt -{{{
local function ido_find_files_set_prompt()
  ido_prompt = string.format("Find files (%s): ",
  string.gsub(fn.resolve(directory_name), '^' .. os.getenv('HOME'), '~'))
end
-- }}}
-- Find files -{{{
function ido_find_files()
  directory_name = vim.loop.cwd()

  ido_find_files_set_prompt()

  return ido_complete {
    prompt = ido_prompt:gsub(' $', ''),
    items = fn.systemlist('ls -A ' .. directory_name),

    keybinds = {
      ["\\<BS>"]     = 'ido_find_files_backspace',
      ["\\<Return>"] = 'ido_find_files_accept',
      ["\\<Tab>"] = 'ido_find_files_prefix',
    },

    on_enter = function(s) directory_name = vim.loop.cwd() end
  }

end
-- }}}
-- Custom backspace in ido_find_files -{{{
function ido_find_files_backspace()
  if ido_pattern_text == '' then
    directory_name = fn.fnamemodify(directory_name, ':h')

    ido_find_files_set_prompt()
    ido_match_list = fn.systemlist('ls -A ' .. directory_name)
    ido_get_matches()
  else
    ido_key_backspace()
  end
end
-- }}}
-- Accept current item -{{{
function ido_find_files_accept()
  if ido_current_item == '' then
    ido_current_item = ido_pattern_text
  end

  if fn.isdirectory(directory_name .. '/' .. ido_current_item) == 1 then
    directory_name = directory_name .. '/' .. ido_current_item
    ido_match_list = fn.systemlist('ls -A ' .. directory_name)
    ido_pattern_text, ido_before_cursor, ido_after_cursor = '', '', ''
    ido_cursor_position = 1
    ido_get_matches()
    ido_find_files_set_prompt()
  else
    ido_close_window()
    return vim.cmd('edit ' .. directory_name .. '/' .. ido_current_item)
  end
end
-- }}}
-- Modified prefix acception -{{{
function ido_find_files_prefix()
  ido_complete_prefix()

  if ido_prefix_text == ido_current_item and #ido_matched_items == 0 and
    ido_prefix_text ~= '' then
    ido_find_files_accept()
  end
end
-- }}}
