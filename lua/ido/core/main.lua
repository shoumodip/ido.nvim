local ido = require("ido")
local ui = require("ido.core.ui")
local fzy = require ("ido.core.fzy")
local stdlib = require ("ido.core.stdlib")
local advice = require ("ido.core.advice")

--- @module Main part of Ido
local main = {}

-- Make the event loop of Ido asynchronous
main.timer = vim.loop.new_timer()

--- Helper function for starting asynchronous jobs
-- @param action The function to execute
-- @return true
function main.async(action)
   main.timer:start(0, 0, vim.schedule_wrap(function()
      action()
   end))

   return true
end

--- Get the matching items and the suggestion
-- @return true
function main.get_results()
   local variables = ido.sandbox.variables
   local options = ido.sandbox.options

   local query = variables.before_cursor..variables.after_cursor

   variables.selected = 1
   variables.suggestion = ""

   if #query > 0 then
      advice.setup("filter_on_get_results", function ()
         variables.results, variables.suggestion = fzy.filter(
            query,
            variables.items,
            options.case_sensitive,
            options.fuzzy_matching)
      end)
   else
      advice.setup("get_results_for_empty_query", function ()
         variables.suggestion = ""
         variables.results = {}

         for _, item in pairs(variables.items) do
            table.insert(variables.results, {item, 0})
         end
      end)
   end

   -- No matched items
   if #variables.results == 0 then
      advice.setup("none_found_after_get_results", function ()
         variables.selected = 0
      end)
   elseif #variables.results == 1 then
      advice.setup("single_result_after_get_results", function ()
         variables.suggestion = variables.results[1][1]
      end)
   end

   advice.setup("render_after_get_results", ui.render)
   return true
end

--- Accept the selected item
-- @return true
function main.accept_selected()
   local variables = ido.sandbox.variables
   local options = ido.sandbox.options

   local selected_item = ""

   if #variables.results == 0 then
      advice.setup("no_results_on_accept_selected")
   else
      selected_item = variables.results[variables.selected][1]
   end

   advice.setup("exit_on_accept_selected", main.exit)

   if options.strict_match then
      advice.setup("clear_query_after_accept_selected", function ()
         variables.before_cursor = ""
         variables.after_cursor = ""
      end)
   end

   variables.suggestion = ""

   variables.results = {{selected_item}}

   return true
end

--- Accept the suggestion text
-- If the number of matches is 0 behave like main.accept_selected()
-- Else concatenate the suggestion to the query text
-- @return true
function main.accept_suggestion()
   local variables = ido.sandbox.variables

   if #variables.suggestion == 0 then
      advice.setup("no_suggestion_on_accept_suggestion")
   elseif #variables.results == 1 then
      advice.setup("single_result_on_accept_suggestion", main.accept_selected)
   else
      advice.setup("fuse_query_on_accept_suggestion", function ()
         stdlib.cursor.line_end()
         variables.before_cursor = variables.before_cursor..variables.suggestion
      end)

      advice.setup("get_results_after_accept_suggestion", main.get_results)

      -- Check if there is only one result now
      if #variables.results == 1 then
         advice.setup("single_result_after_accept_suggestion", main.accept_selected)
      end
   end

   advice.setup("clear_suggestion_after_accept_suggestion", function ()
      variables.suggestion = ""
   end)

   return true
end

--- Insert a character
-- This inserts all the characters which are not bound to any key as literal
-- characters
-- @param char The character to insert
-- @return true
function main.insert(string)
   local variables = ido.sandbox.variables

   advice.setup("insert_string", function ()
      variables.before_cursor = variables.before_cursor..string
   end)

   advice.setup("get_results_after_insert_string", function ()
      main.async(main.get_results)
   end)

   return true
end

--- Loop Ido
-- @return nil if binding errors occured, else true
function main.loop()
   local variables = ido.sandbox.variables

   ui.render()

   while (variables.looping) do

      local key_pressed = vim.fn.getchar()
      local binding = variables.bindings[key_pressed]

      if binding then
         if type(binding) == "function" then

            binding() -- Function application
         elseif type(binding) == "string" then

            -- If it is an standard library function of Ido, execute it
            -- Otherwise byte-compile the Lua string and execute it
            if binding:sub(1, 6) == "stdlib" then
               binding = binding:sub(8, -1)
               stdlib[binding:gsub("%.[^.]+$", "")][binding:gsub(".*%.", "")]()

            elseif binding:sub(1, 4) == "main" then
               main[binding:sub(6, -1)]()
            else
               load(binding)()
            end
         else

            -- Invalid binding, throw error
            -- This is not possible since the binding function checks the types
            -- but *just in case*
            main.exit()
            ui.clear()
            error("Invalid binding for key:"..key_pressed.."", 3)

            return nil
         end
      else
         main.insert(vim.fn.nr2char(key_pressed))
      end

   end

   return true
end

--- Define a key in Ido
-- @param keys The dictionary of keys and their respective mappings
-- @return nil if errors were encountered, else nil
function main.define_keys(keys)
   local key_nr

   for key, mapping in pairs(keys) do
      if type(mapping) ~= "string" and type(mapping) ~= "function" then
         error("Mapping can be either a string or a function", 3)
         return nil
      end

      if type(key) ~= "string" then
         error("Key has to be a string", 3)
         return nil
      end

      if key:sub(1, 1) == "<" then

         key = vim.fn.eval('"\\'..key..'"')
         key_nr = vim.fn.char2nr(key)

         if key_nr ~= 128 then
            key = key_nr
         end
      else
         key = vim.fn.char2nr(key)
      end

      ido.sandbox.variables.bindings[key] = mapping
   end

   return true
end

--- Exit out of Ido
-- @return true
function main.exit()
   local variables = ido.sandbox.variables

   variables.looping = false
   variables.results = {{""}}
   variables.selected = 1

   -- Get rid of the Ido UI
   ui.clear()
   vim.cmd("set guicursor-=a:IdoHideCursor")
   vim.o.cmdheight = main.cmdheight
   main.cmdheight = false

   return true
end

function main.start(options)

   -- Sandbox Ido
   ido.sandbox.variables = vim.deepcopy(ido.variables)
   ido.sandbox.options = vim.deepcopy(ido.options)

   -- Load the options
   for key, value in pairs(options) do
      if ido.sandbox.options[key] ~= nil then
         ido.sandbox.options[key] = value
      elseif ido.sandbox.variables[key] ~= nil then
         ido.sandbox.variables[key] = value
      else
         error("Invalid option/variable: "..key, 2)
         return nil
      end
   end

   if type(options) ~= "nil" and type(options.keys) == "table" then
      ido.sandbox.options.keys = vim.tbl_extend("force", ido.options.keys, options.keys)
   end

   local variables = ido.sandbox.variables
   local options = ido.sandbox.options

   -- If the layout is a string load it
   if type(options.layout) == "string" then
      options.layout = ido.layouts[options.layout]
   end

   -- UI changes to make Ido feel "homey"
   main.cmdheight = main.cmdheight or vim.o.cmdheight

   if options.layout.dynamic_resize then
      vim.o.cmdheight = 1
   else
      vim.o.cmdheight = options.layout.height
   end

   vim.cmd("set guicursor+=a:IdoHideCursor")

   -- Prepare
   main.async(main.get_results)

   main.define_keys(options.keys)

   -- Ready. Set. Go!
   ui.clear()
   variables.looping = true
   main.loop()

   local result = variables.results[variables.selected][1]

   -- Use the query as the result if no items were found and strict match is off
   if not options.strict_match and #result == 0 then
      result = variables.before_cursor..variables.after_cursor
   end

   -- The event loop of Ido has stopped, get rid of the sandbox
   ido.sandbox.variables = {}
   ido.sandbox.options = {}
   advice.sandbox = {}

   return result
end

return main
