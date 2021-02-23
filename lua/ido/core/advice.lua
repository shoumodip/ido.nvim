--- @module Advices in Ido
local advice = {}

-- The sandbox for the advices
advice.sandbox = {}

--- Setup the target for an advice
-- @param name The name of the target
-- @param action The default function which gets activated
-- @return nil in case of error, else true
function advice.setup(name, action)

   if type(name) ~= "string" then
      error("Expected name of type string but got "..
         type(name).." instead", 2)

      return nil
   end

   if name == "setup" or
         name == "set" or
         name == "clear" or
         name == "sandbox" then

      error("Invalid name: "..value, 2)
      return nil
   end

   action = action or function () end

   if type(action) ~= "function" then
      error("Expected action of type function, got "..type(action)..
         " instead", 2)

      return nil
   end

   -- Prefer temporary advices over permanent advices
   local target = advice.sandbox[name]

   if not target then
      target = advice[name]

      if not target then
         action()
         return nil
      end
   end

   if type(target.before) == "function" then
      target.before()
   end

   if type(target.overwrite) == "function" then
      target.overwrite()
   else
      action()
   end

   if type(target.after) == "function" then
      target.after()
   end

   return true
end

--- Set the advice applied to a advice target
-- @param target The target to apply the advice to
-- @param behaviour The advice type
-- @param action The advice
-- @param permanent Whether the advice should persist after Ido exits, true by
-- default
-- @return nil if errors encountered, else true
function advice.set(target, behaviour, action, permanent)

   -- Check for errors in target
   if type(target) ~= "string" then
      error("Expected target of type string but got "..
         type(name).." instead", 2)

      return nil
   end

   if name == "setup" or
         name == "set" or
         name == "clear" or
         name == "sandbox" then

      error("Invalid target: "..value, 2)
      return nil
   end

   -- Check for errors in behaviour
   if type(behaviour) ~= "string" then
      error("Expected behaviour of type string but got "..
         type(behaviour).." instead", 2)

      return nil
   end

   if behaviour ~= "before" and
      behaviour ~= "overwrite" and
      behaviour ~= "after" then

      error("Invalid behaviour: "..behaviour, 2)
      return nil
   end

   -- Check for errors in action
   if type(action) ~= "function" then
      error("Expected action of type function, got "..type(action)..
         " instead", 2)

      return nil
   end

   permanent = permanent == nil and true or permanent

   -- Check for errors in permanent flag
   if type(permanent) ~= "boolean" then
      error("Expected permanent flag of type boolean, got "..type(permanent)..
         " instead", 2)

      return nil
   end

   -- Add the advice
   local advice_target

   if permanent then
      if not advice[target] then
         advice[target] = {}
      end

      advice_target = advice[target]
   else
      if not advice.sandbox[target] then
         advice.sandbox[target] = {}
      end

      advice_target = advice.sandbox[target]
   end

   advice_target[behaviour] = action

   return true
end

--- Clear the advice applied to a function
-- @param target The advice target to remove from
-- @param behaviour The advice to remove
-- @param permanent Whether the advice is permanent or not
-- @return nil if errors encountered, else true
function advice.clear(target, behaviour, permanent)

   -- Check for errors in target
   if type(target) ~= "string" then
      error("Expected target of type string but got "..
         type(name).." instead", 2)

      return nil
   end

   if name == "setup" or
         name == "set" or
         name == "clear" or
         name == "sandbox" then

      error("Invalid target: "..value, 2)
      return nil
   end

   -- Check for errors in behaviour
   if type(behaviour) ~= "string" then
      error("Expected behaviour of type string but got "..
         type(behaviour).." instead", 2)

      return nil
   end

   if behaviour ~= "before" and
      behaviour ~= "overwrite" and
      behaviour ~= "after" then

      error("Invalid behaviour: "..behaviour, 2)
      return nil
   end

   permanent = permanent == nil and true or permanent

   -- Check for errors in permanent flag
   if type(permanent) ~= "boolean" then
      error("Expected permanent flag of type boolean, got "..type(permanent)..
         " instead", 2)

      return nil
   end

   -- Remove the advice
   local advice_target

   if permanent then
      advice_target = advice[target]
   else
      advice_target = advice.sandbox[target]
   end

   if type(advice_target) == "nil" then
      error("Advice target does not exist: "..target, 2)
      return nil
   end

   advice_target = nil
   return true
end

return advice
