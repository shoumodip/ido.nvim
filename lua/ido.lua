-- Import custom Modules -{{{
require "utils/tables"
require "utils/strings"
-- }}}
-- Helper variables -{{{
api = vim.api
fn = vim.fn
-- }}}
-- Variables -{{{
local ido_matched_items = {}
local ido_match_list = {}
local ido_window, ido_buffer
local ido_history_file = os.getenv('XDG_CACHE_HOME') .. '/.nvim_ido_hist'

local before_cursor, after_cursor, pattern = '', '', ''
local prefix, current_item, prefix_text = '', '', ''
local render_text = ''

local ido_default_prompt = '>>> '
local ido_prompt = ido_default_prompt

local cursor_position
local key_pressed = ''

local win_width
local render_list = {}
local more_items = false
-- }}}
-- Settings -{{{
ido_fuzzy_matching = true
ido_case_sensitive = false
ido_limit_lines = true

ido_decorations = {
  prefixstart     = '[',
  prefixend       = ']',

  matchstart      = '',
  separator       = ' | ',
  matchend        = '',

  marker          = '',
  moreitems       = '...'
}

ido_max_lines = 10
ido_min_lines = 3
-- }}}
-- Special keys -{{{
local special_keys = {
  €kl  = 'left',
  €kr  = 'right',
  [2]     = 'left',
  [6]     = 'right',

  [1]     = 'begin',
  [5]     = 'end',

  €kb  = 'backspace',
  €kD  = 'delete',

  [27]    = 'escape',
  [13]    = 'return',
  [9]     = 'tab',

  [14]    = 'next',
  [16]    = 'prev'
}
-- }}}
-- Open the window -{{{
local function ido_open_window()
  ido_buffer = api.nvim_create_buf(false, true) -- Create new empty buffer
  vim.b.bufhidden='wipe'

  -- Calculate our floating window size and starting position
  local win_height = ido_min_lines
  local row        = vim.fn.winheight(0) - win_height
  local col        = 0
  win_width        = vim.fn.winwidth(0)

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
  vim.wo.winhl = 'Normal:CursorLine'
  vim.wo.wrap = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false

  api.nvim_command('echo "" | redraw | echohl IdoStatus | echon " *Completions* " | echohl Normal')

  cursor_position = 1
  before_cursor, after_cursor, pattern, current_item, prefix, prefix_text = '', '', '', '', '', ''
  ido_matched_items = {}

  return ''
end
-- }}}
-- Close the window -{{{
local function ido_close_window()
  ido_prompt = ido_default_prompt
  api.nvim_command('bdelete! | echo ""')
end
-- }}}
-- Get the matching items -{{{
local function ido_get_matches()

  local pattern, true_pattern = pattern, pattern
  ido_matched_items, current_item = {}, ""
  local ido_true_matched_items = {}

  if ido_fuzzy_matching then
    pattern = pattern:gsub('.', '.*%1')
  end

  if not ido_case_sensitive then
    pattern = pattern:lower()
  end

  ido_true_matched_items = table.filter(ido_match_list,
  function(v)
    if not ido_case_sensitive then
      v = v:lower()
    end

    if v:match('^' .. true_pattern) then
      return true
    end
  end
  )

  ido_matched_items = table.filter(ido_match_list,
  function(v)
    if not ido_case_sensitive then
      v = v:lower()
    end

    if v:match(pattern) and not v:match('^' .. true_pattern) then
      return true
    end
  end
  )

  if #ido_matched_items > 1 or #ido_true_matched_items > 1 then

    if #ido_true_matched_items > 0 then
      prefix_text = table.prefix(ido_true_matched_items)
      current_item = ido_true_matched_items[1]
      prefix = prefix_text:gsub('^' .. true_pattern, '')
    else
      prefix = ''
      prefix_text = prefix
      current_item = ido_matched_items[1]
    end

  elseif ido_matched_items[1] ~= nil or ido_true_matched_items[1] ~= nil then

    if ido_true_matched_items[1] == nil then
      prefix = ido_matched_items[1]
      prefix_text = prefix
      current_item = prefix
      ido_matched_items = {}
    else
      if ido_matched_items[1] == nil then
        prefix = ido_true_matched_items[1]
        prefix_text = prefix
        current_item = prefix
        ido_true_matched_items = {}
      else
        current_item = ido_true_matched_items[1]
      end
    end

  else
    prefix = ''
    prefix_text = prefix
  end
  
  if #ido_matched_items > 0 then
    for _, v in pairs(ido_matched_items) do
      table.insert(ido_true_matched_items, v)
    end

  end

  ido_matched_items = ido_true_matched_items

  return ''
end
-- }}}
-- Insert a character -{{{
local function insert_char()
  if key_pressed ~= '' then
    before_cursor = before_cursor .. key_pressed
    cursor_position = cursor_position + 1
    pattern = before_cursor .. after_cursor
  end
  return ''
end
-- }}}
-- Decrement the position of the cursor if possible -{{{
local function cursor_decrement()
  if cursor_position > 1 then
    cursor_position = cursor_position - 1
  end
  return ''
end
-- }}}
-- Increment the position of the cursor if possible -{{{
local function cursor_increment()
  if cursor_position <= pattern:len() then
    cursor_position = cursor_position + 1
  end
  return ''
end
-- }}}
-- Backspace key -{{{
local function key_backspace()
  cursor_decrement()
  before_cursor = before_cursor:gsub('.$', '')
  pattern = before_cursor .. after_cursor
  return ''
end
-- }}}
-- Delete key -{{{
local function key_delete()
  after_cursor = after_cursor:gsub('^.', '')
  pattern = before_cursor .. after_cursor
  return ''
end
-- }}}
-- Move the cursor left a character -{{{
local function cursor_move_left()
  after_cursor = before_cursor:sub(-1, -1) .. after_cursor
  key_backspace()
  return ''
end
-- }}}
-- Move the cursor right a character -{{{
local function cursor_move_right()
  before_cursor = before_cursor .. after_cursor:sub(1, 1)
  cursor_increment()
  key_delete()
  return ''
end
-- }}}
-- Beginning of line -{{{
local function key_begin()
  after_cursor = before_cursor .. after_cursor
  before_cursor = ''
  cursor_position = 1
  return ''
end
-- }}}
-- End of line -{{{
local function key_end()
  before_cursor = before_cursor .. after_cursor
  after_cursor = ''
  cursor_position = before_cursor:len() + 1
  return ''
end
-- }}}
-- Next item -{{{
local function next_item()
  if #ido_matched_items > 1 then
    table.insert(ido_matched_items, current_item)
    table.remove(ido_matched_items, 1)
    current_item = ido_matched_items[1]
  end
  return ''
end
-- }}}
-- Previous item -{{{
local function prev_item()
  if #ido_matched_items > 1 then
    table.insert(ido_matched_items, 1, ido_matched_items[#ido_matched_items])
    table.remove(ido_matched_items, #ido_matched_items)
    current_item = ido_matched_items[1]
  end
  return ''
end
-- }}}
-- Complete the prefix -{{{
local function complete_prefix()
  if prefix ~= '' and pattern ~= prefix_text then
    pattern = prefix_text
    prefix = ''
    cursor_position = pattern:len() + 1
    before_cursor = pattern
    after_cursor = ''
  end
  return ''
end
-- }}}
-- Split the matches into newlines if required -{{{
local function split_matches_lines()
  local render_lines = string.split(render_text, '\n')
  more_items = false

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

          more_items = true
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

  render_text = table.concat(render_lines, '\n'):gsub('^\n', '')
end
-- }}}
-- Render colors -{{{
local function ido_render_colors()
  local prefix_end = string.len(ido_prompt .. pattern)
  local matches_start = {}

  fn.matchadd('IdoPrompt', '\\%1l\\%1c.*\\%' .. ido_prompt:len() .. 'c')
  fn.matchadd('IdoSeparator', '\\M' .. ido_decorations["separator"])
  
  if prefix ~= '' then
    local prefix_start =
    string.len(ido_prompt .. pattern .. ido_decorations['prefixstart'])
    prefix_end =
    string.len(ido_prompt .. pattern .. ido_decorations['prefixstart']
    .. prefix .. ido_decorations['prefixend'])

    fn.matchadd('IdoPrefix',
    '\\%1l\\%' ..  prefix_start .. 'c.*\\%1l\\%' ..  prefix_end + 2 .. 'c')
  end

  if #ido_matched_items > 0 then
    local _, line = string.gsub(ido_decorations['matchstart'], '\n', '')

    if ido_decorations['matchstart']:len() > 0 then

      if line > 0 then
        matches_start[1] = 1
        matches_start[2] = string.len(ido_decorations['matchstart']:gsub('\n', '')) + 1
      else
        matches_start[1] = string.len(ido_prompt .. pattern) + 1
        matches_start[2] = prefix_end + string.len(ido_decorations['matchstart']:gsub('\n', '')) + 2
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
      match_end = match_start + current_item:len()
    else
      match_start = prefix_end +
      string.len(string.gsub(ido_decorations['matchstart'], '\n', '') ..
      string.gsub(ido_decorations['marker'], '\n', '')) + 2
      match_end = match_start + current_item:len()
    end

    fn.matchadd('IdoSelectedMatch', '\\%' .. newlines + 1 .. 'l\\%' ..
    match_start - string.len(ido_decorations['marker'], '\n', '')
    .. 'c.*\\%' .. match_end .. 'c')

  end

  if more_items then
    local eol_start = render_list[#render_list]:len() -
    ido_decorations['moreitems']:len() + 1

    fn.matchadd('IdoSeparator',
    '\\%' .. #render_list .. 'l\\%'.. eol_start .. 'c.*\\%' .. #render_list ..
    'l\\%' .. render_list[#render_list]:len() .. 'c')
  end

  if string.len(ido_prompt .. pattern) >= win_width then
    local length = string.len(ido_prompt .. pattern)
    local lines = math.floor(length / win_width) + 1
    local columns = math.floor(length % win_width) + 1
    fn.matchadd('IdoCursor', '\\%' .. lines .. 'l\\%' .. columns .. 'c')
  else
    fn.matchadd('IdoCursor', '\\%1l\\%' .. (ido_prompt:len() + cursor_position)
    .. 'c')
  end

  return ''
end
-- }}}
-- Render IDO -{{{
local function ido_render()
  local prefix_text, matched_text

  if #ido_matched_items > 0 then
    render_text = table.concat(ido_matched_items,
    ido_decorations["separator"])
  end

  if prefix:len() > 0 then
    prefix_text = ido_decorations['prefixstart'] .. prefix ..
    ido_decorations['prefixend']
    if #ido_matched_items == 0 and #ido_matched_items == 1 then
      prefix_text = ido_decorations['matchstart'] .. prefix_text ..
      ido_decorations['matchend']
    end
  else
    prefix_text = ""
  end

  if #ido_matched_items > 0 then
    matched_text = 
    ido_decorations['matchstart'] .. ido_decorations['marker'] ..
    render_text .. ido_decorations['matchend']
  else
    matched_text = ""
  end

  render_text = ido_prompt .. pattern .. ' ' .. prefix_text .. matched_text
  split_matches_lines()
  render_list = string.split(render_text, '\n')

  api.nvim_buf_set_lines(ido_buffer, 0, -1, false, render_list)

  -- Colors!
  fn.clearmatches()
  ido_render_colors()

  api.nvim_command('redraw!')
end
-- }}}
-- Handle key presses -{{{
local function handle_keys()
  while true do
    key_pressed = fn.getchar()

    if special_keys[key_pressed] ~= nil then
      key_pressed = special_keys[key_pressed]
    else
      key_pressed = fn.nr2char(key_pressed)
    end

    if key_pressed == 'left' then
      cursor_move_left()
    elseif key_pressed == 'right' then
      cursor_move_right()

    elseif key_pressed == 'backspace' then
      key_backspace()
      ido_get_matches()
    elseif key_pressed == 'delete' then
      key_delete()
      ido_get_matches()

    elseif key_pressed == 'begin' then
      key_begin()
    elseif key_pressed == 'end' then
      key_end()

    elseif key_pressed == 'next' then
      next_item()
    elseif key_pressed == 'prev' then
      prev_item()

    elseif key_pressed == 'escape' then
      ido_close_window()
      return ''
    elseif key_pressed == 'return' then
      if current_item == '' then
        current_item = pattern
      end
      ido_close_window()
      return current_item
    elseif key_pressed == 'tab' then
      complete_prefix()

      if prefix_text == current_item and #ido_matched_items == 0 and
        prefix_text ~= '' then
        ido_close_window()
        return prefix_text
      end

      ido_get_matches()
    else
      insert_char()
      ido_get_matches()
    end

    ido_render()
  end
end
-- }}}
-- Completing read -{{{
function ido_completing_read(prompt, list)
  ido_match_list = table.unique(list)
  if prompt:gsub('\n', '') ~= nil then
    ido_prompt = prompt:gsub('\n', '')
  end

  ido_open_window()
  ido_get_matches()

  ido_render()
  return handle_keys()
end
-- }}}
-- Init -{{{
api.nvim_command('hi! IdoCursor         guifg=#161616 guibg=#cc8c3c')
api.nvim_command('hi! IdoStatus         guifg=#161616 guibg=#cc8c3c gui=bold')
api.nvim_command('hi! IdoSelectedMatch  guifg=#95a99f')
api.nvim_command('hi! IdoPrefix         guifg=#9e95c7')
api.nvim_command('hi! IdoSeparator      guifg=#635a5f')
api.nvim_command('hi! IdoPrompt         guifg=#96a6c8')
-- }}}
