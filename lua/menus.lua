require "ido"
local api = vim.api
local fn = vim.fn
local directory_name -- TODO: REMOVE, variable should be in function, passed from function to function.

-- Fuzzy find files -{{{
function ido_find_files(opts)
  opts = opts or {}

  local prompt = opts.prompt or string.format(
    "Find files (%s):",
    string.gsub(
      vim.fn.resolve(opts.cwd), '^' ..
      os.getenv('HOME'), '~'
  ))

  local fd_ignore = (function() -- should properly to util.
    local res = {}
    local ignore = opts.ignore or {"*.png", "*.mp3"}
    for _, v in pairs(ignore) do
      table.insert(res, "-E")
      table.insert(res, string.format([['%s']], v))
    end
    return vim.fn.join(res, " ")
  end)()

  -- local cwd = opts.cwd or vim.loop.cwd() -- TODO: find a way to shorten paths with fd. So this get used.
  local items = vim.fn.systemlist('fd . -tfile ' .. fd_ignore) -- NOTE: this is external tool user need to install.

  local edit = function(s) -- TODO: move to actions.lua
    if s == '' or not s then return end
    return vim.cmd('edit ' .. s)
  end

  return ido_complete {
    prompt = prompt,
    items = items,
    on_enter = edit
  }
end
-- }}}
-- Set the prompt -{{{
local function ido_browser_set_prompt() -- TODO: does it makes sense to populate menus file with small context depended functions?
  ido_prompt = string.format("Browse Directory (%s): ",
  string.gsub(fn.resolve(directory_name), '^' .. os.getenv('HOME'), '~'))
end
-- }}}
-- Directory Browser -{{{
function ido_browser()
  directory_name = vim.loop.cwd()

  ido_browser_set_prompt()

  return ido_complete {
    prompt = ido_prompt:gsub(' $', ''),
    items = fn.systemlist('ls -A ' .. directory_name),

    keybinds = {
      ["\\<BS>"]     = 'ido_browser_backspace', -- TODO: accept function from actions files, or user provided fucntions.
      ["\\<Return>"] = 'ido_browser_accept',
      ["\\<Tab>"] = 'ido_browser_prefix',
    },

    on_enter = function(s) directory_name = vim.loop.cwd() end
  }

end
-- }}}
-- Custom backspace in ido_browser -{{{ -- TODO: move to actions.lua, import here. eg. actions.backspace
function ido_browser_backspace()
  if ido_pattern_text == '' then
    directory_name = fn.fnamemodify(directory_name, ':h')

    ido_browser_set_prompt()
    ido_match_list = fn.systemlist('ls -A ' .. directory_name)
    ido_get_matches()
  else
    ido_key_backspace()
  end
end
-- }}}
-- Accept current item -{{{
function ido_browser_accept()
  if ido_current_item == '' then
    ido_current_item = ido_pattern_text
  end

  if fn.isdirectory(directory_name .. '/' .. ido_current_item) == 1 then
    directory_name = directory_name .. '/' .. ido_current_item
    ido_match_list = fn.systemlist('ls -A ' .. directory_name)
    ido_pattern_text, ido_before_cursor, ido_after_cursor = '', '', ''
    ido_cursor_position = 1
    ido_get_matches()
    ido_browser_set_prompt()
  else
    ido_close_window()
    return vim.cmd('edit ' .. directory_name .. '/' .. ido_current_item)
  end
end
-- }}}
-- Modified prefix acception -{{{
function ido_browser_prefix()
  ido_complete_prefix()

  if ido_prefix_text == ido_current_item and #ido_matched_items == 0 and
    ido_prefix_text ~= '' then
    ido_browser_accept()
  end
end
-- }}}
