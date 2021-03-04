local main = require("ido.main")
local event = require("ido.event")
local render = require("ido.render")
local result = require("ido.result")
local motion = require("ido.motion")
local advice = require("ido.advice")

local delete = {}

-- Execute a motion and restore the text stored in a direction to emulate a
-- delete. Fetch results if the motion was successful
-- @param name string The name of the motion
-- @return true
local function execute(name)

   local string, final_position = motion[name]()

   if string then
      local variables = main.sandbox.variables

      local action = function ()
         variables.before = variables.before:sub(1, #string * -1 - 1)
      end

      if final_position == "before" then
         action = function ()
            variables.after = variables.after:sub(#string + 1)
         end
      end

      advice.wrap{
         name = name,
         action = action
      }

      advice.wrap{
         name = name.."_results",
         action = function()
            event.async(result.fetch)
         end
      }

   else
      advice.wrap{name = name.."_impossible"}
   end

   return true
end

-- Generate the delete motions
for motion, _ in pairs(motion) do
   if motion:sub(-9) ~= "_possible" then
      delete[motion] = function ()
         execute(motion)
      end
   end
end

return delete
