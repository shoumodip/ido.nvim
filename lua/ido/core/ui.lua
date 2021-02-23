local ido = require("ido")

--- Split a string by delimiter
-- @param delim The delimiter to split the string by
-- @return table of split strings
function string:split(delim)
   local results = {}

   -- OOP ;)
   self = self..delim

   for str in self:gmatch("(.-)"..delim) do
      table.insert(results, str)
   end

   return results
end

--- @module UI of Ido
local ui = {}

ui.columns = 0
ui.chars_maximum = 0
ui.chars_filled = 0
ui.echo_command = ""

--- Clear the echo area
-- @return true
function ui.clear()
   ui.chars_filled = 0
   vim.cmd("mode")
   return true
end

--- Draw text with highlight
-- @param string The string to draw
-- @param highlight The highlight to display the string in, defaults to
-- IdoNormal
-- @return false if there is no more space to render, else true
function ui.draw(string, highlight, force)

   -- Split the string by newlines
   local lines = string:split("\n")
   local text = ""

   -- Treat the output text as a 2D matrix of characters
   for index, line in pairs(lines) do
      if ui.chars_filled == ui.chars_maximum then
         break
      end

      -- Calculate the number of spaces required to create a newline. A literal
      -- newline is not printed because it becomes really hard to work on that
      -- logic.

      -- The number of occupied "cells" in the current row is the modulo of the
      -- area of the range of the matrix with the number of columns. Subtract
      -- that from the number of characters in the string and the number of columns
      -- and we get the number of spaces required to create a "newline"
      if lines[index + 1] then
         local spaces = string.rep(" ",
            ui.columns - #line - ui.chars_filled % ui.columns)

         line = line..spaces
      end

      -- Only take specific number of characters which can be required
      line = line:sub(1, ui.chars_maximum - ui.chars_filled - 1)
      ui.chars_filled = ui.chars_filled + #line

      -- Append the line to the text to be displayed
      text = text..line
   end

   -- Get rid of quotes otherwise `echon` will freak out
   text = text:gsub("'", "\\'")

   -- Cache the echo command and only print when the limit has been reached
   -- Provides **EXTREMELY MASSIVE** performance gain
   -- Without this it flickers when running `fd -t d -H . $HOME` (2000+ items)
   -- With this it works on `fd -t f -H . $HOME` (100000+ items) with no issues
   ui.echo_command =
      ui.echo_command..
      " | echohl "..(highlight or "IdoNormal").. -- Highlight of the text
      " | echon '"..text.. -- The text
      "' | echohl IdoNormal" -- Normal color

   if force or ui.chars_filled >= ui.chars_maximum - 1 then
      ui.clear()
      vim.cmd(ui.echo_command:sub(3, -1))
      ui.echo_command = ""

      return false
   end

   return true
end

--- Render Ido
-- @return true
function ui.render()
   ui.echo_command = ""

   -- Prepare yourself for some ugly code

   local variables = ido.sandbox.variables
   local options = ido.sandbox.options

   -- The number of results and the index of the item after the selected one
   local results_limit = #variables.results
   local index = variables.selected + 1

   -- The columns and the maximum possible characters which can be displayed
   ui.columns = vim.o.columns
   ui.chars_maximum = ui.columns * options.layout.height

   -- Draw the prompt and text before the cursor
   if not ui.draw(options.prompt, "IdoPrompt") then return nil end
   if not ui.draw(variables.before_cursor) then return true end

   -- Check if there is anything after the cursor
   if #variables.after_cursor > 0 then

      -- Draw the character directly after the cursor as being highlighted by the cursor
      if not ui.draw(variables.after_cursor:sub(1, 1), "IdoCursor") then return true end

      -- Draw the rest of the query text as normal
      if not ui.draw(variables.after_cursor:sub(2, -1)) then return true end

      -- Add an extra blank
      ui.draw(" ")
   else

      -- There is nothing after the cursor, a space has to be highlighted as the cursor
      ui.draw(" ", "IdoCursor")
   end

   -- Check if there are results
   if variables.selected == 0 then
      goto render
   end

   -- Check if there is only one result
   if #variables.results == 1 then

      -- Draw the results as a suggestion
      if not ui.draw(options.layout.suggest_start, "IdoUXElements") then return true end
      if not ui.draw(variables.results[variables.selected][1], "IdoSuggestion") then return true end
      if not ui.draw(options.layout.suggest_end, "IdoUXElements") then return true end

      goto render
   else

      -- Check if there is a suggestion
      if #variables.suggestion > 0 then

         -- Draw the suggestion
         if not ui.draw(options.layout.suggest_start, "IdoUXElements") then return true end
         if not ui.draw(variables.suggestion, "IdoSuggestion") then return true end
         if not ui.draw(options.layout.suggest_end, "IdoUXElements") then return true end
      end

      -- Miss the '||' operator of shell scripting yet? I sure as hades do

      -- Draw the selected item
      if not ui.draw(options.layout.results_start, "IdoUXElements") then return true end
      if not ui.draw(variables.results[variables.selected][1], "IdoSelected") then return true end
   end

   -- Draw the rest of the items
   for i = 1, results_limit do

      -- Index is there to wrap around once we reach of the results list
      if index > results_limit then index = 1 end
      if index == variables.selected then break end

      -- Draw the separator and the item
      if not ui.draw(options.layout.results_separator, "IdoUXElements") then return true end
      if not ui.draw(variables.results[index][1]) then return true end

      -- Increment the index
      index = index + 1
   end

   -- Draw the decoration which signifies the end of all results
   if not ui.draw(options.layout.results_end, "IdoUXElements") then return true end

   ::render::
   ui.draw("", nil, true)

   return true
end

return ui
