-- Import custom Modules -{{{
require "utils/tables"
require "utils/strings"
-- }}}

-- Import fzy_lua_native {{{
local fzy_lua_native = vim.api.nvim_get_runtime_file("deps/fzy-lua-native/lua/native.lua", false)[1]

if not fzy_lua_native then
  error("Unable to find native fzy native lua dep file. Probably need to update submodules!")
end

local fzy = loadfile(fzy_lua_native)()
--}}}

-- Helper variables -{{{
local api = vim.api
local fn = vim.fn
-- }}}
-- Variables -{{{
local key_pressed = ''
local win_width
local render_list = {}
local minimal_text_length = 0
local minimal_text = ''
local minimal_end_reached = false
local ido_looping = true
local ido_results_limit = 0

ido_matched_items = {}
ido_window, ido_buffer = 0, 0

ido_before_cursor, ido_after_cursor = '', ''
ido_prefix, ido_current_item, ido_prefix_text = '', '', ''
ido_render_text = ''

ido_default_prompt = '>>> '

ido_cursor_position = 1
ido_more_items = false

ido_pattern_text = ''
ido_match_list = {}
ido_prompt = ido_default_prompt
-- }}}
-- Settings -{{{
ido_fuzzy_matching = true
ido_case_sensitive = false
ido_limit_lines = true
ido_overlap_statusline = false
ido_minimal_mode = false

ido_decorations = {
  prefixstart     = '[',
  prefixend       = ']',

  matchstart      = '{',
  separator       = ' | ',
  matchend        = '}',

  marker          = '',
  moreitems       = '...'
}

ido_max_lines = 10
ido_min_lines = 3
ido_key_bindings = {}
-- }}}
-- Special keys -{{{
local ido_hotkeys = {}
ido_keybindings = {
  ["<Escape>"]  = 'ido_close_window',
  ["<Return>"]  = 'ido_accept',

  ["<Left>"]    = 'ido_cursor_move_left',
  ["<Right>"]   = 'ido_cursor_move_right',
  ["<C-b>"]     = 'ido_cursor_move_left',
  ["<C-f>"]     = 'ido_cursor_move_right',

  ["<BS>"]      = 'ido_key_backspace',
  ["<Del>"]     = 'ido_key_delete',

  ["<C-a>"]     = 'ido_cursor_move_begin',
  ["<C-e>"]     = 'ido_cursor_move_end',

  ["<Tab>"]     = 'ido_complete_prefix',
  ["<C-n>"]     = 'ido_next_item',
  ["<C-p>"]     = 'ido_prev_item'
}

function ido_map_keys(table)
  for key_name, action in pairs(table) do

    if key_name:sub(1, 1) == '<' then
      key_name = '\\'..key_name
    end

    ido_hotkeys[fn.eval('"' .. key_name .. '"')] = action
  end
end

function ido_load_keys()
  ido_hotkeys = {}
  ido_map_keys(ido_keybindings)
end

ido_load_keys()
-- }}}
-- Open the window -{{{
local function ido_open_window()
  ido_buffer = api.nvim_create_buf(false, true) -- Create new empty buffer
  vim.b.bufhidden='wipe'

  -- Calculate the Ido window size and starting position
  local win_height = ido_min_lines
  local row        = vim.o.lines - win_height - 2 + (ido_overlap_statusline and 1 or 0)

  local col        = 0

  -- Set some options
  local win_options = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  -- And finally create it with buffer attached
  ido_window = api.nvim_open_win(ido_buffer, true, win_options)
  vim.wo.winhl = 'Normal:IdoWindow'
  vim.wo.wrap = false

  return ''
end
-- }}}
-- Close the window -{{{
function ido_close_window()
  ido_prompt = ido_default_prompt
  api.nvim_command('echo ""')

  if not ido_minimal_mode then
    api.nvim_command('bdelete!')
  end

  ido_looping = false
  return ''
end
-- }}}
-- Get the matching items -{{{
function ido_get_matches()
  ido_matched_items, ido_current_item = {}, ""
  ido_results_limit = 0
  ido_prefix = ""
  ido_prefix_text = ""

  local init_suggestion = false

  if not ido_case_sensitive then
    ido_pattern_text = ido_pattern_text:lower()
  end

  ido_matched_items = fzy.filter(ido_pattern_text, ido_match_list)

  table.sort(ido_matched_items, function (left, right) return left[3] > right[3] end)

  local suggest_source

  for _, item in pairs(ido_matched_items) do

     if #ido_pattern_text == 0 then
        goto continue
     end

     if not string.find(item[1], ido_pattern_text, 1, true) then
        break
     end

     suggest_source = item[1]:sub(item[2][#item[2]] + 1)

     if not init_suggestion then
        ido_prefix = suggest_source
        init_suggestion = true
     else
        ido_prefix = string.prefix(ido_prefix, suggest_source)
     end

     ::continue::

     ido_results_limit = ido_results_limit + 1
  end

  if #ido_matched_items > 0 then
     ido_current_item = ido_matched_items[1][1]
  else
     return ""
  end

  if #ido_matched_items == 1 then
     ido_prefix_text = ido_current_item
     ido_prefix = ido_prefix_text
     ido_matched_items = {}
  end

  return ''
end
-- }}}
-- Insert a character -{{{
function ido_insert_char()
  if key_pressed ~= '' then
    ido_before_cursor = ido_before_cursor .. key_pressed
    ido_cursor_position = ido_cursor_position + 1
    ido_pattern_text = ido_before_cursor .. ido_after_cursor
  end
  return ''
end
-- }}}
-- Decrement the position of the cursor if possible -{{{
local function cursor_decrement()
  if ido_cursor_position > 1 then
    ido_cursor_position = ido_cursor_position - 1
  end
  return ''
end
-- }}}
-- Increment the position of the cursor if possible -{{{
local function cursor_increment()
  if ido_cursor_position <= ido_pattern_text:len() then
    ido_cursor_position = ido_cursor_position + 1
  end
  return ''
end
-- }}}
-- Backspace key -{{{
function ido_key_backspace()
  cursor_decrement()
  ido_before_cursor = ido_before_cursor:gsub('.$', '')
  ido_pattern_text = ido_before_cursor .. ido_after_cursor
  ido_get_matches()
  return ''
end
-- }}}
-- Delete key -{{{
function ido_key_delete()
  ido_after_cursor = ido_after_cursor:gsub('^.', '')
  ido_pattern_text = ido_before_cursor .. ido_after_cursor
  ido_get_matches()
  return ''
end
-- }}}
-- Move the cursor left a character -{{{
function ido_cursor_move_left()
  ido_after_cursor = ido_before_cursor:sub(-1, -1) .. ido_after_cursor
  ido_key_backspace()
  return ''
end
-- }}}
-- Move the cursor right a character -{{{
function ido_cursor_move_right()
  ido_before_cursor = ido_before_cursor .. ido_after_cursor:sub(1, 1)
  cursor_increment()
  ido_key_delete()
  return ''
end
-- }}}
-- Beginning of line -{{{
function ido_cursor_move_begin()
  ido_after_cursor = ido_before_cursor .. ido_after_cursor
  ido_before_cursor = ''
  ido_cursor_position = 1
  return ''
end
-- }}}
-- End of line -{{{
function ido_cursor_move_end()
  ido_before_cursor = ido_before_cursor .. ido_after_cursor
  ido_after_cursor = ''
  ido_cursor_position = ido_before_cursor:len() + 1
  return ''
end
-- }}}
-- Next item -{{{
function ido_next_item()
  if #ido_matched_items > 1 then
    table.insert(ido_matched_items, ido_current_item)
    table.remove(ido_matched_items, 1)
    ido_current_item = ido_matched_items[1]
  end
  return ''
end
-- }}}
-- Previous item -{{{
function ido_prev_item()
  if #ido_matched_items > 1 then
    table.insert(ido_matched_items, 1, ido_matched_items[#ido_matched_items])
    table.remove(ido_matched_items, #ido_matched_items)
    ido_current_item = ido_matched_items[1]
  end
  return ''
end
-- }}}
-- Complete the prefix -{{{
function ido_complete_prefix()
  if ido_prefix_text ~= '' then
    ido_pattern_text = ido_prefix_text
    ido_prefix = ''
    ido_cursor_position = ido_pattern_text:len() + 1
    ido_before_cursor = ido_pattern_text
    ido_after_cursor = ''
  end
  return ''
end
-- }}}
-- Split the matches into newlines if required -{{{
local function split_matches_lines()
  local render_lines = string.split(ido_render_text, '\n')
  ido_more_items = false

  for key, value in pairs(render_lines) do
    if value:len() > win_width then

      local matches_lines, count = '', 1
      while value:len() > 0 and not (count > ido_min_lines and ido_limit_lines) do
        matches_lines = matches_lines .. '\n' .. value:sub(1, win_width)
        value = value:sub(win_width + 1, -1)
        count = count + 1
      end

      if ido_limit_lines then
        if value == '' then
          render_lines[key] = matches_lines
        else
          render_lines[key] = matches_lines:sub(1,
          matches_lines:len() - ido_decorations['moreitems']:len() - 2)
          .. ' ' .. ido_decorations['moreitems']

          ido_more_items = true
        end
      else
        render_lines[key] = matches_lines
      end

    end
  end

  if not ido_limit_lines then
    if #render_lines > ido_min_lines then
      api.nvim_win_set_height(ido_window, ido_max_lines)
    end
  end

  ido_render_text = table.concat(render_lines, '\n'):gsub('^\n', '')
end
-- }}}
-- Render colors -{{{
local function ido_render_colors()
  local ido_prefix_end = string.len(ido_prompt .. ido_pattern_text)
  local matches_start = {}

  fn.matchadd('IdoPrompt', '\\%1l\\%1c.*\\%' .. ido_prompt:len() .. 'c')
  fn.matchadd('IdoSeparator', '\\M' .. ido_decorations["separator"])

  if ido_prefix ~= '' then
    local ido_prefix_start =
    string.len(ido_prompt .. ido_pattern_text .. ido_decorations['prefixstart'])
    ido_prefix_end =
    string.len(ido_prompt .. ido_pattern_text .. ido_decorations['prefixstart']
    .. ido_prefix .. ido_decorations['prefixend'])

    fn.matchadd('IdoPrefix',
    '\\%1l\\%' ..  ido_prefix_start .. 'c.*\\%1l\\%' ..  ido_prefix_end + 2 .. 'c')
  end

  if #ido_matched_items > 0 then
    local _, line = string.gsub(ido_decorations['matchstart'], '\n', '')

    if ido_decorations['matchstart']:len() > 0 then

      if line > 0 then
        matches_start[1] = 1
        matches_start[2] = string.len(ido_decorations['matchstart']:gsub('\n', '')) + 1
      else
        matches_start[1] = string.len(ido_prompt .. ido_pattern_text) + 1
        matches_start[2] = ido_prefix_end + string.len(ido_decorations['matchstart']:gsub('\n', '')) + 2
      end

      vim.fn.matchadd('IdoSeparator',
      '\\%' .. line + 1 .. 'l\\%' .. matches_start[1] .. 'c.*\\%' .. matches_start[2] .. 'c')

    end

    local matches_end = {}

    if ido_decorations['matchend']:len() > 0 then
      matches_end[1] = render_list[#render_list]:len() -
      ido_decorations['matchend']:len() + 1
      matches_end[2] = render_list[#render_list]:len() + 1

      vim.fn.matchadd('IdoSeparator',
      '\\%' .. #render_list .. 'l\\%' .. matches_end[1] .. 'c.*\\%' .. matches_end[2] .. 'c')
    end

  end

  if #ido_matched_items > 0 then
    local _, newlines = string.gsub(ido_decorations['matchstart'], '\n', '')
    local match_start = 0
    if newlines > 0 then
      match_start =
      string.gsub(ido_decorations['marker'], '\n', ''):len() + 1
      match_end = match_start + ido_current_item:len()
    else
      match_start = ido_prefix_end +
      string.len(string.gsub(ido_decorations['matchstart'], '\n', '') ..
      string.gsub(ido_decorations['marker'], '\n', '')) + 2
      match_end = match_start + ido_current_item:len()
    end

    fn.matchadd('IdoSelectedMatch', '\\%' .. newlines + 1 .. 'l\\%' ..
    match_start - string.len(ido_decorations['marker'], '\n', '')
    .. 'c.*\\%' .. match_end .. 'c')

  end

  if ido_more_items then
    local eol_start = render_list[#render_list]:len() -
    ido_decorations['moreitems']:len() + 1

    fn.matchadd('IdoSeparator',
    '\\%' .. #render_list .. 'l\\%'.. eol_start .. 'c.*\\%' .. #render_list ..
    'l\\%' .. render_list[#render_list]:len() .. 'c')
  end

  if string.len(ido_prompt .. ido_pattern_text) >= win_width then
    local length = string.len(ido_prompt .. ido_pattern_text)
    local lines = math.floor(length / win_width) + 1
    local columns = math.floor(length % win_width) + 1
    fn.matchadd('IdoCursor', '\\%' .. lines .. 'l\\%' .. columns .. 'c')
  else
    fn.matchadd('IdoCursor', '\\%1l\\%' .. (ido_prompt:len() + ido_cursor_position)
    .. 'c')
  end

  return ''
end
-- }}}
-- Render IDO -{{{
local function ido_render()
  local ido_prefix_text, matched_text

  if #ido_matched_items > 0 then
    ido_render_text = table.concat(ido_matched_items,
    ido_decorations["separator"])
  end

  if ido_prefix:len() > 0 then
    ido_prefix_text = ido_decorations['prefixstart'] .. ido_prefix ..
    ido_decorations['prefixend']
    if #ido_matched_items == 0 and #ido_matched_items == 1 then
      ido_prefix_text = ido_decorations['matchstart'] .. ido_prefix_text ..
      ido_decorations['matchend']
    end
  else
    ido_prefix_text = ""
  end

  if #ido_matched_items > 0 then
    matched_text =
    ido_decorations['matchstart'] .. ido_decorations['marker'] ..
    ido_render_text .. ido_decorations['matchend']
  else
    matched_text = ""
  end

  ido_render_text = ido_prompt .. ido_pattern_text .. ' ' .. ido_prefix_text .. matched_text
  split_matches_lines()
  render_list = string.split(ido_render_text, '\n')

  api.nvim_buf_set_lines(ido_buffer, 0, -1, false, render_list)

  -- Colors!
  fn.clearmatches()
  ido_render_colors()

  api.nvim_command('redraw!')
end
-- }}}
-- Print the text in minimal mode -{{{
local function ido_minimal_print(text, end_char)
  minimal_text_length = minimal_text_length + text:len()
  end_char = end_char and end_char or ''
  local text_to_print = ''

  if minimal_text_length <= win_width and not minimal_end_reached then
    text_to_print = string.sub(minimal_text .. text,
    minimal_text:len() + 1,
    win_width - string.len(
    ido_decorations["moreitems"]:gsub('\n', '') ..
    ido_decorations["matchend"]:gsub('\n', ''))
    - 2)

    minimal_text = minimal_text .. text_to_print
    api.nvim_command('echon "' .. text_to_print .. '"')
  end

  if minimal_text_length > win_width and not minimal_end_reached then
    api.nvim_command('echohl IdoSeparator')
    api.nvim_command('echon " ' .. ido_decorations["moreitems"]:gsub('\n', '') .. '"')
    api.nvim_command('echon "' .. end_char:gsub('\n', '') .. '"')
    api.nvim_command('echohl IdoNormal')
    minimal_end_reached = true
  end
end
-- }}}
-- Render Ido in minimal mode -{{{
local function ido_minimal_render()
  local ido_prefix_text, matched_text
  minimal_text = ''
  minimal_end_reached = false
  minimal_text_length = string.len(ido_decorations["moreitems"]:gsub('\n', '')
  .. ido_decorations["matchend"]:gsub('\n', '')) + 1

  api.nvim_command('echohl IdoPrompt')
  ido_minimal_print(ido_prompt)
  api.nvim_command('echohl IdoNormal')

  if ido_before_cursor:len() > 0 then
    ido_minimal_print(ido_before_cursor)
  end

  api.nvim_command('echohl IdoCursor')
  if ido_after_cursor == '' then
    ido_minimal_print(' ')
  else
    ido_minimal_print(ido_after_cursor:sub(1, 1))
  end
  api.nvim_command('echohl IdoNormal')

  ido_minimal_print(ido_after_cursor:sub(2, -1))

  if ido_prefix:len() > 0 then
    api.nvim_command('echohl IdoPrefix')
    ido_minimal_print(ido_decorations['prefixstart']:gsub('\n', ''))
    ido_minimal_print(ido_prefix)
    ido_minimal_print(ido_decorations['prefixend']:gsub('\n', ''))
    api.nvim_command('echohl IdoNormal')
  end

  if #ido_matched_items > 0 then
    api.nvim_command('echohl IdoSeparator')
    ido_minimal_print(ido_decorations["matchstart"], ido_decorations["matchend"])
    api.nvim_command('echohl IdoNormal')
  end

  for k, v in pairs(ido_matched_items) do

    -- if minimal_text_length > win_width then break end

    if k == 1 then api.nvim_command('echohl IdoSelectedMatch') end
    ido_minimal_print(v[1], '}')

    if ido_matched_items[k + 1] ~= nil and minimal_text_length <= win_width then
      api.nvim_command('echohl IdoSeparator')
      ido_minimal_print(ido_decorations["separator"], ido_decorations["matchend"])
      api.nvim_command('echohl IdoNormal')
    end

  end

  if #ido_matched_items > 0 then
    api.nvim_command('echohl IdoSeparator')
    ido_minimal_print(ido_decorations["matchend"], ido_decorations["matchend"])
    api.nvim_command('echohl IdoNormal')
  end

  api.nvim_command('redraw')
end
-- }}}
-- Handle key presses -{{{
local function handle_keys()
  while ido_looping do
    key_pressed = fn.getchar()
    -- I really want Ido to 'return' a value when Enter is pressed so stuff like
    --
    -- print(ido_complete({items = {'red', 'green', 'blue'}}) .. ' is my color')
    --
    -- is possible. I know the 'on_enter' option exists, but at the end of the
    -- day, I mostly use temporary Ido functions to achieve my tasks, and the
    -- return feature is a blessing. Therefore I deal with this complexity
    -- below, as this is more of a personal preference.

    if fn.char2nr(key_pressed) == 128 then
      key_pressed_action = ido_hotkeys[key_pressed] and ido_hotkeys[key_pressed] or fn.nr2char(key_pressed)
    else
      key_pressed_action = ido_hotkeys[fn.nr2char(key_pressed)] and
      ido_hotkeys[fn.nr2char(key_pressed)] or
      fn.nr2char(key_pressed)
    end

    if key_pressed_action == 'ido_accept' then
      if ido_current_item == '' then
        ido_current_item = ido_pattern_text
      end
      ido_close_window()
      return ido_current_item

    elseif key_pressed_action == 'ido_complete_prefix' then
      ido_complete_prefix()

      if ido_prefix_text == ido_current_item and #ido_matched_items == 0 and
        ido_prefix_text ~= '' then
        ido_close_window()
        return ido_prefix_text
      end

      ido_get_matches()

    else
      if key_pressed_action == fn.nr2char(key_pressed) then
        key_pressed = fn.nr2char(key_pressed)
        ido_insert_char()
        ido_get_matches()

      else

        loadstring(key_pressed_action .. '()')()
      end
    end

    if not ido_looping then
      return current_item
    end

    if ido_minimal_mode then
      ido_minimal_render()
    else
      ido_render()
    end
  end
end
-- }}}
-- Completing read -{{{
function ido_complete(opts)
  opts = opts or {}
  ido_match_list = table.unique(opts.items)
  ido_prompt = opts.prompt and opts.prompt:gsub('\n', '') .. ' ' or ido_default_prompt

  ido_cursor_position = 1
  ido_before_cursor, ido_after_cursor, ido_pattern_text, ido_current_item, ido_prefix, ido_prefix_text = '', '', '', '', '', ''
  ido_matched_items = {}
  looping = true
  win_width = vim.o.columns

  local laststatus = vim.o.laststatus
  local ruler = vim.o.ruler
  local guicursor = vim.o.guicursor
  -- vim.o.guicursor = 'a:IdoHideCursor'
  vim.o.ruler = false

  if opts.keybinds ~= nil then ido_map_keys(opts.keybinds) end

  if ido_minimal_mode then
    vim.o.laststatus = 2
  else
    ido_open_window()
  end

  ido_get_matches()

  if ido_minimal_mode then
    ido_minimal_render()
  else
    ido_render()
  end

  local selection = handle_keys()

  if opts.keybinds ~= nil then
    ido_hotkeys = {}
    ido_map_keys(ido_keybindings)
  end

  ido_prompt = ido_default_prompt
  ido_looping = true

  if ido_minimal_mode then
    vim.o.laststatus = laststatus
  end

  -- vim.o.guicursor = guicursor
  vim.o.ruler = ruler

  if opts.on_enter then
    return opts.on_enter(selection)
  else
    return selection
  end
end
-- }}}
-- Init -{{{
api.nvim_command('hi! IdoCursor         guifg=#161616 guibg=#cc8c3c')
api.nvim_command('hi! IdoHideCursor     gui=reverse blend=100')
api.nvim_command('hi! IdoSelectedMatch  guifg=#95a99f')
api.nvim_command('hi! IdoPrefix         guifg=#9e95c7')
api.nvim_command('hi! IdoSeparator      guifg=#635a5f')
api.nvim_command('hi! IdoPrompt         guifg=#96a6c8')
api.nvim_command('hi! IdoWindow         guibg=#202020')
-- }}}
