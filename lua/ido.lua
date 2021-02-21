-- Import custom Modules -{{{
require "utils/tables"
require "utils/strings"
local fzy = require("utils/fzy")
-- }}}

-- Helper variables -{{{
local api = vim.api
local fn = vim.fn
-- }}}

local ido = {}

-- Expose fzy on the ido module
ido.fzy = fzy

-- Variables -{{{
local key_pressed = ''
local win_width
local render_list = {}
local minimal_text_length = 0
local minimal_text = ''
local minimal_end_reached = false
local ido_looping = true
local ido_results_limit = 0

ido.vars = {
  matched_items = {},
  window = 0,
  buffer = 0,
  before_cursor = '',
  after_cursor = '',
  prefix = '',
  current_item = '',
  prefix_text = '',
  render_text = '',

  cursor_position = 1,
  more_items = false,

  pattern_text = '',
  match_list = {},
  default_prompt = '>>> ',
  prompt = '>>> '
}
-- }}}

-- Settings -{{{
ido.settings = {
  fuzzy_matching = true,
  case_sensitive = false,
  limit_lines = true,
  overlap_statusline = false,
  minimal_mode = false,
  max_lines = 10,
  min_lines = 3
}
-- }}}

-- Decorations -{{{
ido.decorations = {
  prefixstart     = '[',
  prefixend       = ']',

  matchstart      = '{',
  separator       = ' | ',
  matchend        = '}',

  marker          = '',
  moreitems       = '...'
}
-- }}}

-- key bindings -{{{
local ido_hotkeys = {}

ido.keybindings = {
  ["<Escape>"]  = 'close_window',
  ["<Return>"]  = 'ido_accept',

  ["<Left>"]    = 'cursor_move_left',
  ["<Right>"]   = 'cursor_move_right',
  ["<C-b>"]     = 'cursor_move_left',
  ["<C-f>"]     = 'cursor_move_right',

  ["<BS>"]      = 'key_backspace',
  ["<Del>"]     = 'key_delete',

  ["<C-a>"]     = 'cursor_move_begin',
  ["<C-e>"]     = 'cursor_move_end',

  ["<Tab>"]     = 'ido_complete_prefix',
  ["<C-n>"]     = 'next_item',
  ["<C-p>"]     = 'prev_item'
}

local function ido_map_keys(table)
  for key_name, action in pairs(table) do

    if key_name:sub(1, 1) == '<' then
      key_name = '\\'..key_name
    end

    ido_hotkeys[fn.eval('"' .. key_name .. '"')] = action
  end
end

function ido.load_keys()
  ido_hotkeys = {}
  ido_map_keys(ido.keybindings)
end

ido.load_keys()
-- }}}

-- Setup {{{
function ido.setup(opts)
  opts = opts or {}

  table.merge(ido.vars, opts.variables or {})
  table.merge(ido.settings, opts.settings or {})
  table.merge(ido.keybindings, opts.keybindings or {})

  ido.load_keys()
end
-- }}}

-- Open the window -{{{
function ido.open_window()
  ido.vars.buffer = api.nvim_create_buf(false, true) -- Create new empty buffer
  vim.b.bufhidden='wipe'

  -- Calculate the Ido window size and starting position
  local win_height = ido.settings.min_lines
  local row        = vim.o.lines - win_height - 2 + (ido.settings.overlap_statusline and 1 or 0)

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
  ido.vars.window = api.nvim_open_win(ido.vars.buffer, true, win_options)
  vim.wo.winhl = 'Normal:IdoWindow'
  vim.wo.wrap = false

  return ''
end
-- }}}
-- Close the window -{{{
function ido.close_window()
  ido.vars.prompt = ido.vars.default_prompt
  api.nvim_command('echo ""')

  if not ido.settings.minimal_mode then
    api.nvim_command('bdelete!')
  end

  ido_looping = false
  return ''
end
-- }}}
-- Get the matching items -{{{

 -- Default filter function uses FZY,
 -- user can overwrite or extend this function by overwriting ido.filter
 function ido.filter(pattern_text, match_list)
   local match_list = ido.vars.match_list
   local pattern_text = ido.vars.pattern_text

   return fzy.filter(pattern_text, match_list)
 end

 -- Default sorter function uses normalized FZY score,
-- user can overwrite or extend this function by overwriting ido.sorter
function ido.sorter(left, right)
  return fzy.score(left) < fzy.score(right)
end

-- Default suggestion function uses FZY position based prefix generation
-- user can overwrite or extend this function by overwriting ido.suggester
function ido.suggester(pattern_text, matched_items)
  local init_suggestion = false
  local suggest_source

  for _, item in pairs(ido.vars.matched_items) do

     if #pattern_text == 0 then
        goto continue
     end

     if not string.find(item[1], pattern_text, 1, true) then
        break
     end

     suggest_source = item[1]:sub(item[2][#item[2]] + 1)

     if not init_suggestion then
        ido.vars.prefix = suggest_source
        init_suggestion = true
     else
        ido.vars.prefix = string.prefix(ido.vars.prefix, suggest_source)
     end

     ::continue::

     ido_results_limit = ido_results_limit + 1
  end

  if #matched_items > 0 then
     ido.vars.current_item = matched_items[1][1]
  else
     return ""
  end

  if #matched_items == 1 then
    ido.vars.prefix_text = ido.vars.current_item
    ido.vars.prefix = ido.vars.prefix_text
    ido.vars.matched_items = {}
  end
end

function ido.get_matches()
  ido.vars.matched_items = {}
  ido.vars.current_item = ""
  ido_results_limit = 0
  ido.vars.prefix = ""
  ido.vars.prefix_text = ""

  local pattern_text = ido.vars.pattern_text
  local match_list = ido.vars.match_list

  if not ido.settings.case_sensitive then
    ido.vars.pattern_text = pattern_text:lower()
  end

  ido.vars.matched_items = ido.filter(pattern_text, match_list)

  table.sort(ido.vars.matched_items, ido.sorter)

  ido.suggester(pattern_text, ido.vars.matched_items)

  return ''
end
-- }}}
-- Insert a character -{{{
function ido.insert_char()
  if key_pressed ~= '' then
    ido.vars.before_cursor = ido.vars.before_cursor .. key_pressed
    ido.vars.cursor_position = ido.vars.cursor_position + 1
    ido.vars.pattern_text = ido.vars.before_cursor .. ido.vars.after_cursor
  end
  return ''
end
-- }}}
-- Decrement the position of the cursor if possible -{{{
local function cursor_decrement()
  if ido.vars.cursor_position > 1 then
    ido.vars.cursor_position = ido.vars.cursor_position - 1
  end
  return ''
end
-- }}}
-- Increment the position of the cursor if possible -{{{
local function cursor_increment()
  if ido.vars.cursor_position <= ido.vars.pattern_text:len() then
    ido.vars.cursor_position = ido.vars.cursor_position + 1
  end
  return ''
end
-- }}}
-- Backspace key -{{{
function ido.key_backspace()
  cursor_decrement()
  ido.vars.before_cursor = ido.vars.before_cursor:gsub('.$', '')
  ido.vars.pattern_text = ido.vars.before_cursor .. ido.vars.after_cursor
  ido.get_matches()
  return ''
end
-- }}}
-- Delete key -{{{
function ido.key_delete()
  ido.vars.after_cursor = ido.vars.after_cursor:gsub('^.', '')
  ido.vars.pattern_text = ido.vars.before_cursor .. ido.vars.after_cursor
  ido.get_matches()
  return ''
end
-- }}}
-- Move the cursor left a character -{{{
function ido.cursor_move_left()
  ido.vars.after_cursor = ido.vars.before_cursor:sub(-1, -1) .. ido.vars.after_cursor
  ido.key_backspace()
  return ''
end
-- }}}
-- Move the cursor right a character -{{{
function ido.cursor_move_right()
  ido.vars.before_cursor = ido.vars.before_cursor .. ido.vars.after_cursor:sub(1, 1)
  cursor_increment()
  ido.key_delete()
  return ''
end
-- }}}
-- Beginning of line -{{{
function ido.cursor_move_begin()
  ido.vars.after_cursor = ido.vars.before_cursor .. ido.vars.after_cursor
  ido.vars.before_cursor = ''
  ido.vars.cursor_position = 1
  return ''
end
-- }}}
-- End of line -{{{
function ido.cursor_move_end()
  ido.vars.before_cursor = ido.vars.before_cursor .. ido.vars.after_cursor
  ido.vars.after_cursor = ''
  ido.vars.cursor_position = ido.vars.before_cursor:len() + 1
  return ''
end
-- }}}
-- Next item -{{{
function ido.next_item()
  if #ido.vars.matched_items > 1 then
    table.insert(ido.vars.matched_items, ido.vars.current_item)
    table.remove(ido.vars.matched_items, 1)
    ido.vars.current_item = ido.vars.matched_items[1]
  end
  return ''
end
-- }}}
-- Previous item -{{{
function ido.prev_item()
  if #ido.vars.matched_items > 1 then
    table.insert(ido.vars.matched_items, 1, ido.vars.matched_items[#ido.vars.matched_items])
    table.remove(ido.vars.matched_items, #ido.vars.matched_items)
    ido.vars.current_item = ido.vars.matched_items[1]
  end
  return ''
end
-- }}}
-- Complete the prefix -{{{
function ido.complete_prefix()
  if ido.vars.prefix_text ~= '' then
    ido.vars.pattern_text = ido.vars.prefix_text
    ido.vars.prefix = ''
    ido.vars.cursor_position = ido.vars.pattern_text:len() + 1
    ido.vars.before_cursor = ido.vars.pattern_text
    ido.vars.after_cursor = ''
  end
  return ''
end
-- }}}
-- Split the matches into newlines if required -{{{
local function split_matches_lines()
  local render_lines = string.split(ido.vars.render_text, '\n')
  ido.vars.more_items = false

  for key, value in pairs(render_lines) do
    if value:len() > win_width then

      local matches_lines, count = '', 1
      while value:len() > 0 and not (count > ido.settings.min_lines and ido.settings.limit_lines) do
        matches_lines = matches_lines .. '\n' .. value:sub(1, win_width)
        value = value:sub(win_width + 1, -1)
        count = count + 1
      end

      if ido.settings.limit_lines then
        if value == '' then
          render_lines[key] = matches_lines
        else
          render_lines[key] = matches_lines:sub(1,
          matches_lines:len() - ido.decorations['moreitems']:len() - 2)
          .. ' ' .. ido.decorations['moreitems']

          ido.vars.more_items = true
        end
      else
        render_lines[key] = matches_lines
      end

    end
  end

  if not ido.settings.limit_lines then
    if #render_lines > ido.settings.min_lines then
      api.nvim_win_set_height(ido.vars.window, ido.settings.max_lines)
    end
  end

  ido.vars.render_text = table.concat(render_lines, '\n'):gsub('^\n', '')
end
-- }}}
-- Render colors -{{{
local function render_colors()
  local ido_prefix_end = string.len(ido.vars.prompt .. ido.vars.pattern_text)
  local matches_start = {}

  fn.matchadd('IdoPrompt', '\\%1l\\%1c.*\\%' .. ido.vars.prompt:len() .. 'c')
  fn.matchadd('IdoSeparator', '\\M' .. ido.decorations["separator"])

  if ido.vars.prefix ~= '' then
    local ido_prefix_start =
    string.len(ido.vars.prompt .. ido.vars.pattern_text .. ido.decorations['prefixstart'])
    ido.vars.prefix_end =
    string.len(ido.vars.prompt .. ido.vars.pattern_text .. ido.decorations['prefixstart']
    .. ido.vars.prefix .. ido.decorations['prefixend'])

    fn.matchadd('IdoPrefix',
    '\\%1l\\%' ..  ido_prefix_start .. 'c.*\\%1l\\%' ..  ido_prefix_end + 2 .. 'c')
  end

  if #ido.vars.matched_items > 0 then
    local _, line = string.gsub(ido.decorations['matchstart'], '\n', '')

    if ido.decorations['matchstart']:len() > 0 then

      if line > 0 then
        matches_start[1] = 1
        matches_start[2] = string.len(ido.decorations['matchstart']:gsub('\n', '')) + 1
      else
        matches_start[1] = string.len(ido.vars.prompt .. ido.vars.pattern_text) + 1
        matches_start[2] = ido_prefix_end + string.len(ido.decorations['matchstart']:gsub('\n', '')) + 2
      end

      vim.fn.matchadd('IdoSeparator',
      '\\%' .. line + 1 .. 'l\\%' .. matches_start[1] .. 'c.*\\%' .. matches_start[2] .. 'c')

    end

    local matches_end = {}

    if ido.decorations['matchend']:len() > 0 then
      matches_end[1] = render_list[#render_list]:len() -
      ido.decorations['matchend']:len() + 1
      matches_end[2] = render_list[#render_list]:len() + 1

      vim.fn.matchadd('IdoSeparator',
      '\\%' .. #render_list .. 'l\\%' .. matches_end[1] .. 'c.*\\%' .. matches_end[2] .. 'c')
    end

  end

  if #ido.vars.matched_items > 0 then
    local _, newlines = string.gsub(ido.decorations['matchstart'], '\n', '')
    local match_start = 0
    if newlines > 0 then
      match_start =
      string.gsub(ido.decorations['marker'], '\n', ''):len() + 1
      match_end = match_start + ido.vars.current_item:len()
    else
      match_start = ido_prefix_end +
      string.len(string.gsub(ido.decorations['matchstart'], '\n', '') ..
      string.gsub(ido.decorations['marker'], '\n', '')) + 2
      match_end = match_start + ido.vars.current_item:len()
    end

    fn.matchadd('IdoSelectedMatch', '\\%' .. newlines + 1 .. 'l\\%' ..
    match_start - string.len(ido.decorations['marker'], '\n', '')
    .. 'c.*\\%' .. match_end .. 'c')

  end

  if ido.vars.more_items then
    local eol_start = render_list[#render_list]:len() -
    ido.decorations['moreitems']:len() + 1

    fn.matchadd('IdoSeparator',
    '\\%' .. #render_list .. 'l\\%'.. eol_start .. 'c.*\\%' .. #render_list ..
    'l\\%' .. render_list[#render_list]:len() .. 'c')
  end

  if string.len(ido.vars.prompt .. ido.vars.pattern_text) >= win_width then
    local length = string.len(ido.vars.prompt .. ido.vars.pattern_text)
    local lines = math.floor(length / win_width) + 1
    local columns = math.floor(length % win_width) + 1
    fn.matchadd('IdoCursor', '\\%' .. lines .. 'l\\%' .. columns .. 'c')
  else
    fn.matchadd('IdoCursor', '\\%1l\\%' .. (ido.vars.prompt:len() + ido.vars.cursor_position)
    .. 'c')
  end

  return ''
end
-- }}}
-- Render IDO -{{{
local function render()
  local ido_prefix_text, matched_text

  if #ido.vars.matched_items > 0 then
    ido.vars.render_text = table.concat(ido.vars.matched_items,
    ido.decorations["separator"])
  end

  if ido.vars.prefix:len() > 0 then
    ido_prefix_text = ido.decorations['prefixstart'] .. ido.vars.prefix ..
    ido.decorations['prefixend']
    if #ido.vars.matched_items == 0 and #ido.vars.matched_items == 1 then
      ido_prefix_text = ido.decorations['matchstart'] .. ido_prefix_text ..
      ido.decorations['matchend']
    end
  else
    ido_prefix_text = ""
  end

  if #ido.vars.matched_items > 0 then
    matched_text =
    ido.decorations['matchstart'] .. ido.decorations['marker'] ..
    ido.vars.render_text .. ido.decorations['matchend']
  else
    matched_text = ""
  end

  ido.vars.render_text = ido.vars.prompt .. ido.vars.pattern_text .. ' ' .. ido_prefix_text .. matched_text
  split_matches_lines()
  render_list = string.split(ido.vars.render_text, '\n')

  api.nvim_buf_set_lines(ido.vars.buffer, 0, -1, false, render_list)

  -- Colors!
  fn.clearmatches()
  render_colors()

  api.nvim_command('redraw!')
end
-- }}}
-- Print the text in minimal mode -{{{
local function minimal_print(text, end_char)
  minimal_text_length = minimal_text_length + text:len()
  end_char = end_char and end_char or ''
  local text_to_print = ''

  if minimal_text_length <= win_width and not minimal_end_reached then
    text_to_print = string.sub(minimal_text .. text,
    minimal_text:len() + 1,
    win_width - string.len(
    ido.decorations["moreitems"]:gsub('\n', '') ..
    ido.decorations["matchend"]:gsub('\n', ''))
    - 2)

    minimal_text = minimal_text .. text_to_print
    api.nvim_command('echon "' .. text_to_print .. '"')
  end

  if minimal_text_length > win_width and not minimal_end_reached then
    api.nvim_command('echohl IdoSeparator')
    api.nvim_command('echon " ' .. ido.decorations["moreitems"]:gsub('\n', '') .. '"')
    api.nvim_command('echon "' .. end_char:gsub('\n', '') .. '"')
    api.nvim_command('echohl IdoNormal')
    minimal_end_reached = true
  end
end
-- }}}
-- Render Ido in minimal mode -{{{
local function minimal_render()
  local ido_prefix_text, matched_text
  minimal_text = ''
  minimal_end_reached = false
  minimal_text_length = string.len(ido.decorations["moreitems"]:gsub('\n', '')
  .. ido.decorations["matchend"]:gsub('\n', '')) + 1

  api.nvim_command('echohl IdoPrompt')
  minimal_print(ido.vars.prompt)
  api.nvim_command('echohl IdoNormal')

  if ido.vars.before_cursor:len() > 0 then
    minimal_print(ido.vars.before_cursor)
  end

  api.nvim_command('echohl IdoCursor')
  if ido.vars.after_cursor == '' then
    minimal_print(' ')
  else
    minimal_print(ido.vars.after_cursor:sub(1, 1))
  end
  api.nvim_command('echohl IdoNormal')

  minimal_print(ido.vars.after_cursor:sub(2, -1))

  if ido.vars.prefix:len() > 0 then
    api.nvim_command('echohl IdoPrefix')
    minimal_print(ido.decorations['prefixstart']:gsub('\n', ''))
    minimal_print(ido.vars.prefix)
    minimal_print(ido.decorations['prefixend']:gsub('\n', ''))
    api.nvim_command('echohl IdoNormal')
  end

  if #ido.vars.matched_items > 0 then
    api.nvim_command('echohl IdoSeparator')
    minimal_print(ido.decorations["matchstart"], ido.decorations["matchend"])
    api.nvim_command('echohl IdoNormal')
  end

  for k, v in pairs(ido.vars.matched_items) do

    -- if minimal_text_length > win_width then break end

    if k == 1 then api.nvim_command('echohl IdoSelectedMatch') end
    minimal_print(v[1], '}')

    if ido.vars.matched_items[k + 1] ~= nil and minimal_text_length <= win_width then
      api.nvim_command('echohl IdoSeparator')
      minimal_print(ido.decorations["separator"], ido.decorations["matchend"])
      api.nvim_command('echohl IdoNormal')
    end

  end

  if #ido.vars.matched_items > 0 then
    api.nvim_command('echohl IdoSeparator')
    minimal_print(ido.decorations["matchend"], ido.decorations["matchend"])
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
      if ido.vars.current_item == '' then
        ido.vars.current_item = ido.vars.pattern_text
      end
      ido.close_window()
      return ido.vars.current_item

    elseif key_pressed_action == 'ido_complete_prefix' then
      ido.complete_prefix()

      if ido.vars.prefix_text == ido.vars.current_item and #ido.vars.matched_items == 0 and
        ido.vars.prefix_text ~= '' then
        ido.close_window()
        return ido.vars.prefix_text
      end

      ido.get_matches()
    elseif ido[key_pressed_action] then
      ido[key_pressed_action]()
    else
      if key_pressed_action == fn.nr2char(key_pressed) then
        key_pressed = fn.nr2char(key_pressed)
        ido.insert_char()
        ido.get_matches()

      else
        loadstring(key_pressed_action .. '()')()
      end
    end

    if not ido_looping then
      return current_item
    end

    if ido.settings.minimal_mode then
      minimal_render()
    else
      render()
    end
  end
end
-- }}}
-- Completing read -{{{
function ido.complete(opts)
  opts = opts or {}
  ido.vars.match_list = table.unique(opts.items)
  ido.vars.prompt = opts.prompt and opts.prompt:gsub('\n', '') .. ' ' or ido.vars.default_prompt

  ido.vars.cursor_position = 1
  ido.vars.before_cursor, ido.vars.after_cursor, ido.vars.pattern_text, ido.vars.current_item, ido.vars.prefix, ido.vars.prefix_text = '', '', '', '', '', ''
  ido.vars.matched_items = {}
  looping = true
  win_width = vim.o.columns

  local laststatus = vim.o.laststatus
  local ruler = vim.o.ruler
  local guicursor = vim.o.guicursor
  -- vim.o.guicursor = 'a:IdoHideCursor'
  vim.o.ruler = false

  if opts.keybinds ~= nil then ido_map_keys(opts.keybinds) end

  if ido.settings.minimal_mode then
    vim.o.laststatus = 2
  else
    ido.open_window()
  end

  ido.get_matches()

  if ido.settings.minimal_mode then
    minimal_render()
  else
    ido.render()
  end

  local selection = handle_keys()

  -- TODO: eval if this is needed ?
  if opts.keybinds ~= nil then
    ido_hotkeys = {}
    ido_map_keys(ido.keybindings)
  end

  ido.vars.prompt = ido.vars.default_prompt
  ido_looping = true

  if ido.settings.minimal_mode then
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

return ido
-- vim: foldmethod=marker:sw=2:foldlevel=10
