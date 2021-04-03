local theme = require("ido.theme")
local module = require("ido.module")
local advice = require("ido.advice")
local config = require("ido.config")

-- @module main Main module of Ido
local main = {}

local ruler_save = nil

-- Internal variables of Ido
-- @field before string The query text before the cursor
-- @field after string The query text after the cursor
-- @field items table The array of items to filter from
-- @field results table The array of items which match the query
-- @field selected number The index of the selected item
-- @field suggestion string The common suffix present after the query in all true results
-- @field bindings table Point to respective keys in `options.keys` by keycodes
-- @field looping boolean Whether the event loop of Ido is running
main.variables = {
   before = "",
   after = "",

   items = {},
   results = {},

   selected = 0,
   suggestion = "",

   bindings = {},
   looping = false,
}

-- The sandbox
-- @field variables table The sandboxed internal Ido variables
-- @field options table The sandboxed Ido configuration options
main.sandbox = {
   variables = {},
   options = {}
}

-- Insert a string
-- @param string The string to insert
-- @return true
function main.insert(string)

   if #string == 0 then return true end

   local variables = main.sandbox.variables

   advice.wrap{
      name = "append_string",
      action = function ()
         variables.before = variables.before..string
      end
   }

   advice.wrap{
      name = "fetch_results",
      action = function ()
         require("ido.event").async(require("ido.result").fetch)
      end
   }

   return true
end

-- Map keybindings
-- @param key_definitions table The dictionary of keys and their definitions
-- @return true
function main.map(key_definitions)

   local key_number = 0

   for key, mapping in pairs(key_definitions) do

      if key:sub(1, 1) == "<" then

         key = vim.fn.eval('"\\'..key..'"')
         key_number = vim.fn.char2nr(key)

         if key_number ~= 128 then
            key = key_number
         end
      else
         key = vim.fn.char2nr(key)
      end

      main.sandbox.variables.bindings[key] = mapping
   end

   return true
end

-- Start Ido
-- @param fields table The dictionary of options and variables
-- @return selected item
function main.start(fields)

   -- Sandbox Ido
   main.sandbox.variables = vim.deepcopy(main.variables)
   main.sandbox.options = vim.deepcopy(config.options)

   for key, value in pairs(fields) do
      local target = ""

      if config.options[key] ~= nil then
         target = "options"
      elseif main.variables[key] ~= nil then
         target = "variables"
      else
         print("Invalid field: "..key)
         return nil
      end

      if type(value) == "table" then
         main.sandbox[target][key] = vim.tbl_extend("force",
            main.sandbox[target][key],
            value)
      else
         main.sandbox[target][key] = value
      end
   end

   -- Load the module specific options
   if module.running then
      local options = require(module.running).options

      if options then
         main.sandbox.options = vim.tbl_deep_extend(
            "force",
            main.sandbox.options,
            options)
      end

      module.running = false
   end

   local variables = main.sandbox.variables
   local options = main.sandbox.options

   -- Initialize
   main.map(options.keys)
   vim.cmd("set guicursor+=a:ido_hide_cursor")

   require(options.renderer).init()
   theme.load(options.theme)

   -- Start the event loop
   variables.looping = true
   require("ido.result").fetch()
   require("ido.event").loop()

   -- Store the selected result
   local selected = ""

   if #variables.results > 0 then
      selected = variables.results[variables.selected][1]
   end

   -- Get rid of the Ido interface
   require(options.renderer).exit()

   vim.cmd("set guicursor-=a:ido_hide_cursor")

   main.sandbox.variables = {}
   main.sandbox.options = {}

   for index, advice_info in pairs(advice.sandbox) do
      advice.list[advice_info.target][advice_info.hook][advice_info.index] = nil
      advice.sandbox[index] = nil
   end

   ruler_save = nil

   return selected
end

return main
