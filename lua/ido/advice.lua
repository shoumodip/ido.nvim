-- @module advice Advices from Lisp implemented in Lua
local advice = {}

-- List of advices
advice.list = {}
advice.sandbox = {}

-- Check if an advice exists or not
-- @param options table
-- @return true or false
local function wrapper_exists(options)
   return advice.list[options.id] ~= nil and
      advice.list[options.id][options.hook] ~= nil
end

-- Run an advice
-- @param options table Options which describe the sequence of advices to run
-- @field id string The identifier of the advice
-- @field hook string The hook which the advice operates on: before, after, overwrite
-- @return true
function advice.run(options)

   -- Check if the advice even exists
   if not wrapper_exists(options) then

      -- Run the default action if supplied
      if options.default then
         options.default()
      end

      return true
   end

   -- The table to run the advices from
   local advice_position = advice.list[options.id][options.hook]

   for index, advice in pairs(advice_position) do

      -- Apply the advised action
      advice.action()

      -- Get rid of the advice if it is temporary
      if advice.temporary == 2 then
         advice_position[index] = nil
      end
   end

   return true
end

-- Wrap an advice around a function
-- @param options table Options which describe the advice
-- @field name string The name of the advice wrapper
-- @field action function The function which gets executed, defaults to nothing
-- @return nil in case of errors, else true
function advice.wrap(options)

   -- Undefined wrapper name
   if options.name == nil then
      print("Name of the wrapper is not defined")
      return nil
   end

   -- The advice ID:
   -- function_name@file_name:wrapper_name
   local info = debug.getinfo(2)

   local function_name = info.name or ""
   local file_name = info.source:gsub("^(.).*/", "%1"):sub(1, -5) or ""
   local advice_id = function_name..file_name..":"..options.name

   -- If it is not in a function, get rid of the `@` character
   local advice_id = advice_id:gsub('^@', "")

   -- The before advice
   advice.run{
      id = advice_id,
      hook = "before"
   }

   -- The overwrite advice or the default action
   advice.run{
      id = advice_id,
      hook = "overwrite",
      default = options.action
   }

   -- The after advice
   advice.run{
      id = advice_id,
      hook = "after"
   }

   return true
end

-- Add an advice to a wrapper
-- @param options table Options which describe the advice
-- @field name string The name of the advice
-- @field action function The function which gets executed, defaults to nothing
-- @field target string The id of the advice wrapper it points to
-- @field temporary number How temporary the advice is, can be 0, 1 or 2
-- @field hook string The activation style of the advice: before, after, overwrite (default)
-- @return nil in case of errors, else true
function advice.add(options)

   -- Check if the advice wrapper target is defined
   if options.target == nil then
      print("Advice wrapper target must be defined")
      return nil
   end

   -- Check if the name is defined
   if options.name == nil then
      print("Advice name must be defined")
      return nil
   end

   if not options.action then
      return true
   end

   -- Defaults
   options.hook = options.hook or "overwrite"

   -- Create the target if it does not exist
   if advice.list[options.target] == nil then
      advice.list[options.target] = {}
   end

   if advice.list[options.target][options.hook] == nil then
      advice.list[options.target][options.hook] = {}
   end

   -- Add the advice
   table.insert(advice.list[options.target][options.hook], {
      name = options.name,
      action = options.action,
      temporary = options.temporary
   })

   if options.temporary == 1 then
      table.insert(advice.sandbox, {
         target = options.target,
         hook = options.hook,
         index = #advice.list[options.target][options.hook]
      })
   end

   return true
end

-- Remove an advice from a wrapper
-- @param options table Options which describe the advice
-- @field name string The name of the advice
-- @field target string The id of the advice wrapper it points to
-- @field hook string The activation style of the advice: before, after, overwrite (default)
-- @return true or nil
function advice.remove(options)

   -- Check if the advice wrapper target is defined
   if options.target == nil then
      print("Advice wrapper target must be given")
      return nil
   end

   -- Check if the name is defined
   if options.name == nil then
      print("Advice name must be given")
      return nil
   end

   -- Defaults
   options.hook = options.hook or "overwrite"

   -- Check if the target exists
   if wrapper_exists{id = options.target, hook = options.hook} == nil then
      print("Advice not found: "..options.name)
      return nil
   end

   local advice_position = advice.list[options.target][options.hook]

   -- Get rid of the advice
   for index, advice in pairs(advice_position) do

      if advice.name == options.name then
         advice_position[index] = nil
         return true
      end
   end

   -- Advice with the name provided was not found
   print("Advice not found: "..options.name)
   return nil
end

return advice
