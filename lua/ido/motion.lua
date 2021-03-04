local main = require("ido.main")

local motion = {}

-- Check if a forward motion is possible
-- @return whether it is possible
function motion.forward_possible()
   return #main.sandbox.variables.after > 0
end

-- Check if a backward motion is possible
-- @return whether it is possible
function motion.backward_possible()
   return #main.sandbox.variables.before > 0
end

-- Motion to go forward a character
-- @return nil if it is impossible, or the motion string and the target position
function motion.forward()
   local variables = main.sandbox.variables

   if motion.forward_possible() then
      return variables.after:sub(1, 1), "before"
   end

   return nil
end

-- Motion to go backward a character
-- @return nil if it is impossible, or the motion string and the target position
function motion.backward()
   local variables = main.sandbox.variables

   if motion.backward_possible() then
      return variables.before:sub(-1), "after"
   end

   return nil
end

-- Motion to go forward a word
-- @return nil if it is impossible, or the motion string and the target position
function motion.forward_word()
   local variables = main.sandbox.variables
   local options = main.sandbox.options

   if motion.forward_possible() then
      local string = variables.after:gsub(
         "([^"..options.word_separators.."]*["..
            options.word_separators.."]+).*",

         "%1")

      return string, "before"
   end

   return nil
end

-- Motion to go backward a word
-- @return nil if it is impossible, or the motion string and the target position
function motion.backward_word()
   local variables = main.sandbox.variables
   local options = main.sandbox.options

   if motion.backward_possible() then
      local string = variables.before:gsub(
         ".*["..options.word_separators.."]([^"..
            options.word_separators.."]+["..
            options.word_separators.."]*)$",

         "%1")

      return string, "after"
   end

   return nil
end

-- Motion to go to the start of the line
-- @return nil if it is impossible, or the motion string and the target position
function motion.line_start()
   local variables = main.sandbox.variables

   if motion.backward_possible() then
      return variables.before, "after"
   end

   return nil
end

-- Motion to go to the end of the line
-- @return nil if it is impossible, or the motion string and the target position
function motion.line_end()
   local variables = main.sandbox.variables

   if motion.forward_possible() then
      return variables.after, "before"
   end

   return nil
end

return motion
