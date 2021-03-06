local main = require("ido.main")

-- @module render Builtin renderer for Ido
local render = {}

render.window_width = 0 -- The width of the Neovim window
render.chars_filled = 0 -- The characters which have been filled
render.echo_list = {} -- The buffered command for rendering Ido
render.ruler_save = false -- The saved value of the ruler

-- Renderer settings
-- @field results_start string The decoration before the results
-- @field results_separator string The decoration separating the results
-- @field results_end string The decoration after the results
-- @field suggest_start string The decoration before the suggestion
-- @field suggest_end string The decoration after the suggestion
render.settings = {
   results_start = "{",
   results_separator = " | ",
   results_end = "}",

   suggest_start = "[",
   suggest_end = "]",
}

-- Queue a string to be rendered
-- @param string string String to be rendered
-- @field highlight string The highlight color of the text, defaults to `ido_normal`
-- @param force boolean Render the buffered text, even though there are empty characters left
-- @return whether more tokens can be rendered
function render.queue(string, highlight, force)

   -- No need to process anything if the string is blank
   if #string == 0 then
      goto render_text_maybe
   end

   -- Get rid of the newlines
   string = string:gsub("\n", ""):sub(1, render.window_width - render.chars_filled - 1)

   -- Add the characters to the render buffer
   table.insert(render.echo_list, {string, highlight or "ido_normal"})
   render.chars_filled = render.chars_filled + #string

   -- If it is forced or there is no more space left, execute the buffered command

   ::render_text_maybe::
   if force or render.chars_filled == render.window_width - 1 then
      vim.cmd("redraw")
      vim.api.nvim_echo(render.echo_list, false, {})

      -- Stop the rendering loop
      return false
   end

   return true
end

-- Draw the prompt
-- @return whether more tokens can be rendered
function render.prompt()
   return render.queue(main.sandbox.options.prompt, "ido_prompt")
end

-- Draw the input field
-- @return whether more tokens can be rendered
function render.input()

   local variables = main.sandbox.variables
   local options = main.sandbox.options

   -- Draw the text before the cursor
   if not render.queue(variables.before) then return false end

   local cursor_overlap_character = ""

   if #variables.after > 0 then

      -- The cursor is overlapping the first character of `after`
      cursor_overlap_character = variables.after:sub(1, 1)
   elseif #variables.suggestion > 0 or #variables.results == 1 then

      -- The cursor is overlapping the first character of `suggest_start`
      cursor_overlap_character = render.settings.suggest_start:sub(1, 1)
   else

      -- The cursor is overlapping nothing, draw a space
      cursor_overlap_character = " "
   end

   -- Draw the cursor
   if not render.queue(cursor_overlap_character, "ido_cursor") then return false end

   if #variables.after > 0 then
      if not render.queue(variables.after:sub(2, -1)) then return false end
   end

   -- Render the suggestion
   if #variables.suggestion > 0 or #variables.results == 1 then

      -- Render the ux element before the suggestion
      local suggest_start = render.settings.suggest_start

      if #variables.after == 0 then
         suggest_start = suggest_start:sub(2)
      end

      if not render.queue(suggest_start, "ido_ux") then return false end

      -- Render the suggestion and the ux element after the suggestion
      if not render.queue(variables.suggestion, "ido_suggestion") then return false end
      if not render.queue(render.settings.suggest_end, "ido_ux") then return false end
   end

   -- Render a space before the results if not already
   if #variables.suggestion == 0 and #variables.after > 0 then
      return render.queue(" ")
   end

   return true
end

-- Draw the results
-- @return whether more tokens can be rendered
function render.results()

   local variables = main.sandbox.variables
   local results_limit = #variables.results

   -- Do not render results if number of results is less than 2
   -- 0 results => nothing to render
   -- 1 result  => render as a suggestion
   if results_limit < 2 then
      return true
   end

   local index = variables.selected + 1

   -- Render the ux element before the results
   if not render.queue(render.settings.results_start, "ido_ux") then
      return false
   end

   -- Render the first item
   if not render.queue(variables.results[variables.selected][1], "ido_selected") then
      return false
   end

   -- Iterate for the same number of times as there are number of results
   for i = 1, results_limit do

      -- Wrap around the end
      if index > results_limit then
         index = 1
      end

      -- Stop if we have arrived at the selected item again
      if index == variables.selected then
         goto render_results_end
      end

      -- Render the separator
      if not render.queue(render.settings.results_separator, "ido_ux") then
         return false
      end

      -- Render the result with accompanied highlighting
      if not render.queue(variables.results[index][1]) then
         return false
      end

      -- Go to the next index
      index = index + 1
   end

   ::render_results_end::
   return render.queue(render.settings.results_end, "ido_ux")
end

-- The function to run when Ido is initialised
-- @return true
function render.init()
   if not render.ruler then
      render.ruler = vim.o.ruler
   end

   vim.cmd("set noruler")
   vim.cmd("autocmd VimResized <buffer> lua require('ido.event').async(require('ido.render').main)")

   return true
end

-- The function to run when Ido exits
-- @return true
function render.exit()
   vim.api.nvim_set_option("ruler", render.ruler)
   render.ruler = false

   vim.cmd("autocmd! VimResized <buffer>")
   vim.cmd("echo '' | redraw")

   return true
end

-- The entry point to the renderer
-- @return true
function render.main()

   render.echo_list = {}

   local variables = main.sandbox.variables
   local options = main.sandbox.options

   render.chars_filled = 0
   render.window_width = vim.o.columns

   -- Render the prompt
   if not render.prompt() then
      return true
   end

   -- Render the input field
   if not render.input() then
      return true
   end

   -- Render the results
   if not render.results() then
      return true
   end

   -- Render Ido if still not done
   render.queue("", nil, true)

   return true
end

return render
