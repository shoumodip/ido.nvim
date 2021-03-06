local main = require("ido.main")
local config = require("ido.config")
local motion = require("ido.motion")
local advice = require("ido.advice")

local cursor = {}

-- Execute a motion and render if the motion returned true
-- @param name string The name of the motion
-- @return true
local function execute(name)

   local string, final_position = motion[name]()

   if string then

      local variables = main.sandbox.variables

      local action = function ()
         variables.after = string..variables.after
         variables.before = variables.before:sub(1, #string * -1 - 1)
      end

      if final_position == "before" then
         action = function ()
            variables.before = variables.before..string
            variables.after = variables.after:sub(#string + 1)
         end
      end

      advice.wrap{
         name = name,
         action = function ()
            action()
         end
      }

      advice.wrap{
         name = name.."_render",
         action = function ()
            require(config.options.renderer).main()
         end
      }

   else
      advice.wrap{name = name.."_impossible"}
   end

   return true
end

-- Generate the cursor motions
for motion, _ in pairs(motion) do
   if motion:sub(-9) ~= "_possible" then
      cursor[motion] = function ()
         execute(motion)
      end
   end
end

return cursor
