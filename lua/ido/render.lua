local main = require("ido.main")
local layout = require("ido.layout")

-- @module render Rendering functions for Ido
local render = {}

render.tokens_rendered = {} -- The tokens of Ido which have been rendered
render.window_width = 0 -- The width of the Neovim window
render.chars_maximum = 0 -- The maximum number of characters which can be printed
render.chars_filled = 0 -- The characters which have been filled
render.echo_command = "" -- The buffered vimL command for rendering Ido

render.tokens = {} -- Drawing functions for the tokens

-- Render Ido
-- @return true
function render.draw()

   vim.cmd("redraw")
   vim.cmd(render.echo_command:sub(4))

   return true
end

-- Queue a string to be rendered
-- @param string string String to be rendered
-- @field highlight string The highlight color of the text, defaults to `ido_normal`
-- @param force boolean Render the buffered text, even though there are empty characters left
-- @return whether more tokens can be rendered
function render.queue(string, highlight, force)

   local lines = ""
   local text = ""

   -- No need to process anything if the string is blank
   if #string == 0 then
      goto render_text_maybe
   end

   -- Split the line along newlines
   lines = vim.split(string, "\n", true)

   -- Treat the characters as the 2D matrix
   for index, line in pairs(lines) do

      -- Stop if the limit has been exceeded
      if render.chars_filled == render.chars_maximum then
         break
      end

      -- Figure out the number of spaces to put after the line
      if lines[index + 1] then
         local spaces = string.rep(" ",
            render.window_width - #line - render.chars_filled % render.window_width)

         line = line..spaces
      end

      -- Add the characters to the line
      line = line:sub(1, render.chars_maximum - render.chars_filled)
      render.chars_filled = render.chars_filled + #line

      -- Add the characters to the text to be queued
      text = text..line
   end

   -- Get rid of the quotes otherwise `echon` will freak out
   text = text:gsub("'", "''")

   -- Generate the render command and buffer it
   render.echo_command =
      render.echo_command..
         " | echohl "..(highlight or "ido_normal")..
         " | echon '"..text.."'"..
         " | echohl ido_normal"

   ::render_text_maybe::

   -- If it is forced or there is no more space left, execute the buffered command
   if force or render.chars_filled == render.chars_maximum then

      render.draw()

      if not force then render.echo_command = "" end

      -- If it is forced, we do not want the rendering loop to stop
      return render.chars_filled < render.chars_maximum
   end

   return true
end

-- Draw the prompt
-- @return whether more tokens can be rendered
function render.tokens.prompt()
   return render.queue(main.sandbox.options.prompt, "ido_prompt")
end

-- Draw the query
-- @return whether more tokens can be rendered
function render.tokens.query()

   local variables = main.sandbox.variables
   local options = main.sandbox.options
   local layout = layout[options.layout]

   -- Draw the text before the cursor
   if not render.queue(variables.before) then return false end

   local cursor_overlap_character = ""

   if #variables.after > 0 then

      -- The cursor is overlapping the first character of `after`
      cursor_overlap_character = variables.after:sub(1, 1)
   elseif #variables.suggestion > 0 or #variables.results == 1 then

      -- The cursor is overlapping the first character of `suggest_start`
      cursor_overlap_character = layout.suggest_start:sub(1, 1)
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
      local suggest_start = layout.suggest_start

      if #variables.after == 0 then
         suggest_start = suggest_start:sub(2)
      end

      if not render.queue(suggest_start, "ido_ux") then return false end

      -- Render the suggestion and the ux element after the suggestion
      if not render.queue(variables.suggestion, "ido_suggestion") then return false end
      if not render.queue(layout.suggest_end, "ido_ux") then return false end
   end

   -- Render a space before the results if not already
   if #variables.suggestion > 0 or #variables.after > 0 then
      return render.queue(" ", "ido_normal")
   end

   return true
end

-- Draw the results with custom coloring capabilities
-- @return whether more tokens can be rendered
function render.tokens.results(options)

   local variables = main.sandbox.variables
   local layout = layout[main.sandbox.options.layout]
   local results_limit = #variables.results

   -- Do not render results if number of results is less than 2
   -- 0 results => nothing to render
   -- 1 result  => render as a suggestion
   if results_limit < 2 then
      return true
   end

   local index_increment_value = options.reverse and -1 or 1
   local index = variables.selected
   local rendered_selected = false

   -- Calculate the starting index if the reverse flag is on
   if options.reverse then
      if results_limit == index or
         results_limit < options.lines_limit then

         index = index - 1
      else
         index = (index + options.lines_limit - 1) % results_limit
      end
   end

   -- Render the ux element before the results
   if not render.queue(layout.results_start, "ido_ux") then
      return false
   end

   -- Iterate for the same number of times as there are number of results
   for i = 1, results_limit do

      -- Wrap around the end
      if options.reverse then
         if index < 1 then index = index + results_limit end
      else
         if index > results_limit then index = 1 end
      end

      -- Check if the current index is the selected index
      if index == variables.selected then

         -- Selected index has already been rendered, means it has wrapped
         -- around to the initial index
         if rendered_selected then
            return true
         end

         -- The selected result has been rendered
         rendered_selected = true

         -- Render the separator
         if not render.queue(layout.results_selected, "ido_ux") then
            return false
         end
      end

      -- Render the result with accompanied highlighting
      if not render.queue(variables.results[index][1],
         index == variables.selected and "ido_selected") then
         return false
      end

      -- Do not go beyoud `lines_limit`
      if options.lines_limit and
         math.floor(render.chars_filled / render.window_width) >= options.lines_limit then

         goto render_results_end
      end

      -- Go to the next index
      index = index + index_increment_value

      -- Do not render the separator if it is the last item to be rendered
      if index % results_limit ~= variables.selected then

         if options.reverse then
            if (index + 1) % results_limit == variables.selected then
               goto render_results_end
            end

            if results_limit == variables.selected and
               (index + 1 == results_limit or index == 0) then

               goto continue
            end
         end

         if not render.queue(layout.results_separator, "ido_ux") then
            return false
         end
      end

      ::continue::
   end

   ::render_results_end::
   return render.queue(layout.results_end, "ido_ux")
end

-- Render Ido
-- @param preserve_output boolean true Use the previous output, defaults to false
-- @return true
function render.start(preserve_output)

   if preserve_output then
      render.draw()
   else
      render.echo_command = ""
   end

   local variables = main.sandbox.variables
   local options = main.sandbox.options

   local layout = layout[options.layout]
   local token_index = 1

   render.tokens_rendered = {}
   render.chars_filled = 0
   render.window_width = vim.o.columns
   render.chars_maximum = render.window_width * layout.maximum_height - 1

   -- Render the tokens one by one
   while token_index <= #layout.render_sequence do

      local current_token = layout.render_sequence[token_index]
      local render_token = ""
      local render_token_args = {}

      -- Do not render the same token twice
      if render.tokens_rendered[current_token] then
         goto continue
      end

      if type(current_token) == "string" then

         -- The token to be rendered is the token string itself
         render_token = current_token
      elseif type(current_token) == "table" then

         -- The token to be rendered is the first element of the current token
         -- and the rest of the keys and values are the options passed to it
         render_token = current_token[1]

         render_token_args = current_token
      else

         -- Invalid token type
         print("Invalid token type: "..type(token))
         return nil
      end

      -- Render the token
      if not render.tokens[render_token](render_token_args) then
         goto render_ido_final
      end

      -- Register the current token as being registered
      render.tokens_rendered[current_token] = true

      ::continue::

      -- Render the next token
      token_index = token_index + 1
   end

   -- Render Ido if still not done
   ::render_ido_final::
   if render.chars_filled == render.chars_maximum then
      return true
   end

   local spaces_count = render.chars_maximum - render.chars_filled

   if layout.dynamic_resize then
      spaces_count = spaces_count % render.window_width
   end

   render.queue(string.rep(" ", spaces_count), nil, true)

   return true
end

return render
