local ido = require("ido")
local ui = require("ido.core.ui")
local advice = require("ido.core.advice")

--- @module Standard library of Ido
local stdlib = {}

-- Cursor functions
stdlib.cursor = {}

--- Check if an increment of the cursor position is possible
-- @return whether the incrementation is possible
function stdlib.cursor.increment_possible()
   return #ido.sandbox.variables.after_cursor > 0 -- Pure function :D
end

--- Check if an decrement of the cursor position is possible
-- @return whether the incrementation is possible
function stdlib.cursor.decrement_possible()
   return #ido.sandbox.variables.before_cursor > 0
end

--- Move the cursor forward a character if possible
-- @return true
function stdlib.cursor.forward()
   if stdlib.cursor.increment_possible() then

      -- Shift the text before and after the cursor to emulate a movement
      advice.setup("shift_text_on_cursor_forward", function ()

         local variables = ido.sandbox.variables

         variables.before_cursor = variables.before_cursor
         ..variables.after_cursor:sub(1, 1)

         variables.after_cursor = variables.after_cursor:sub(2, -1)
      end)

      advice.setup("render_on_cursor_forward", ui.render)
   else
      advice.setup("cursor_forward_impossible")
   end

   return true
end

--- Move the cursor backward a character if possible
-- @return true
function stdlib.cursor.backward()

   if stdlib.cursor.decrement_possible() then

      -- Shift the text before and after the cursor to emulate a movement
      advice.setup("shift_text_on_cursor_backward", function ()

         local variables = ido.sandbox.variables

         variables.after_cursor = variables.before_cursor:sub(-1, -1)
         ..variables.after_cursor

         variables.before_cursor = variables.before_cursor:sub(1, -2)
      end)

      advice.setup("render_on_cursor_backward", ui.render)
   else
      advice.setup("cursor_backward_impossible")
   end

   return true
end

--- Move the cursor forward a word if possible
-- @return true
function stdlib.cursor.forward_word()

   if stdlib.cursor.increment_possible() then

      -- Shift the text before and after the cursor to emulate a movement
      advice.setup("shift_text_on_cursor_forward_word", function ()

         local variables = ido.sandbox.variables
         local options = ido.sandbox.options

         local init_pos = variables.after_cursor
         :gsub("([^"..options.word_separators.."]+["..options.word_separators.."]*).*", "%1")
         :len()

         variables.before_cursor = variables.before_cursor
         ..variables.after_cursor:sub(1, init_pos)

         variables.after_cursor = variables.after_cursor:sub(init_pos + 1, -1)
      end)

      advice.setup("render_on_cursor_forward_word", ui.render)
   else
      advice.setup("cursor_forward_word_impossible")
   end

   return true
end

--- Move the cursor backward a word if possible
-- @return true
function stdlib.cursor.backward_word()

   if stdlib.cursor.decrement_possible() then

      -- Shift the text before and after the cursor to emulate a movement
      advice.setup("shift_text_on_cursor_backward_word", function ()

         local variables = ido.sandbox.variables
         local options = ido.sandbox.options

         local init_pos = variables.before_cursor
         :gsub("["..options.word_separators.."]*[^"..options.word_separators.."]*$", "")
         :len()

         variables.after_cursor = variables.before_cursor:sub(init_pos + 1, -1)
         ..variables.after_cursor

         variables.before_cursor = variables.before_cursor:sub(1, math.max(init_pos, 0))
      end)

      advice.setup("render_on_cursor_backward_word", ui.render)
   else
      advice.setup("cursor_backward_word_impossible")
   end

   return true
end

--- Move the cursor to the start of the line if possible
-- @return true
function stdlib.cursor.line_start()

   if stdlib.cursor.decrement_possible() then

      advice.setup("shift_text_on_cursor_line_start", function ()

         local variables = ido.sandbox.variables

         variables.after_cursor = variables.before_cursor..variables.after_cursor
         variables.before_cursor = ""
      end)

      advice.setup("render_on_cursor_line_start", ui.render)
   else
      advice.setup("cursor_line_start_impossible")
   end

   return true
end

--- Move the cursor to the end of the line if possible
-- @return true
function stdlib.cursor.line_end()

   if stdlib.cursor.increment_possible() then

      advice.setup("shift_text_on_cursor_line_end", function ()

         local variables = ido.sandbox.variables

         variables.before_cursor = variables.before_cursor..variables.after_cursor
         variables.after_cursor = ""
      end)

      advice.setup("render_on_cursor_line_end", ui.render)
   else
      advice.setup("cursor_line_end_impossible")
   end

   return true
end

-- Delete characters
stdlib.delete = {}

--- Delete a character forwards
-- @return true if it is possible, else nil
function stdlib.delete.forward()
   local variables = ido.sandbox.variables

   if stdlib.cursor.increment_possible() then
      advice.setup("delete_forward_character", function ()

         local variables = ido.sandbox.variables
         variables.after_cursor = variables.after_cursor:sub(2, -1)
      end)

      advice.setup("get_results_on_delete_forward_character", function ()
         local main = require("ido.core.main")
         main.async(main.get_results)
      end)
   else
      advice.setup("delete_forward_impossible")
   end

   return true
end

--- Delete a character backwards
-- @return true
function stdlib.delete.backward()
   if stdlib.cursor.decrement_possible() then
      advice.setup("delete_backward_character", function ()

         local variables = ido.sandbox.variables
         variables.before_cursor = variables.before_cursor:sub(1, -2)
      end)

      advice.setup("get_results_on_delete_backward_character", function ()
         local main = require("ido.core.main")
         main.async(main.get_results)
      end)
   else
      advice.setup("delete_backward_impossible")
   end

   return true
end

-- Items in Ido
stdlib.items = {}

--- Switch to the next item
-- @return nil if there is no next item, else true
function stdlib.items.next()
   if #ido.sandbox.variables.results < 2 then
      advice.setup("next_item_not_found")
   else
      advice.setup("switch_to_next_item", function ()

         local variables = ido.sandbox.variables
         variables.selected = variables.selected + 1

         -- Wrap around if out of bound
         if variables.selected > #variables.results then
            variables.selected = 1
         end
      end)

      advice.setup("render_on_next_item", ui.render)
   end

   return true
end

--- Switch to the previous item if possible
-- @return nil if there is no previous item, else true
function stdlib.items.prev()

   if #ido.sandbox.variables.results < 2 then
      advice.setup("previous_item_not_found")
   else
      advice.setup("switch_to_previous_item", function ()

         local variables = ido.sandbox.variables
         variables.selected = variables.selected - 1

         -- Wrap around if out of bound
         if variables.selected <= 0 then
            variables.selected = #variables.results
         end
      end)

      advice.setup("render_on_previous_item", ui.render)
   end

   return true
end

return stdlib
