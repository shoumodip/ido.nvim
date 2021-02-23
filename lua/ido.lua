--- @module Ido
local ido = {}

-- Internal variables of Ido
ido.variables = {
   before_cursor = "",
   after_cursor = "",

   items = {},
   results = {},

   selected = 0,
   suggestion = "",

   bindings = {},
   looping = false,
}

--- Layouts of Ido
ido.layouts = {}

-- Default layout
ido.layouts.default = {
   results_start = "{",
   results_end = "}",

   suggest_start = "[",
   suggest_end = "]",

   results_separator = " | ",

   height = 2,
   dynamic_resize = false,
}

--- Setup a layout
-- @param name The name of the layout
-- @param options The UX options in the layout
-- @param nil if errors encountered, else true
function ido.layouts.setup(name, options)

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(string).." instead", 2)
      return nil
   end

   -- Check if the name is valid
   if name == "setup" or name == "default" then
      error("The name of a layout cannot be "..name, 2)
      return nil
   end

   -- Check the type of the options
   if type(options) ~= "table" then
      error("Expected options of type table, got "..type(string).." instead", 2)
      return nil
   end

   -- Load the missing options from the default layout
   options = vim.tbl_extend("keep", options, ido.layouts.default)

   -- Check for user errors
   for option, value in pairs(options) do

      -- Non-existant option
      if ido.layouts.default[option] == nil then
         error("Non existant option: "..option, 2)
         return nil
      end

      -- Types mismatch
      if type(ido.layouts.default[option]) ~= type(value) then
         error("Expected "..option.." of type "..type(ido.layouts.default[option])..
            " but got "..type(value).." instead", 2)

         return nil
      end
   end

   -- No errors found, setup the layout
   ido.layouts[name] = options
   return true
end

--- Options of Ido
ido.options = {

   -- Layout
   layout = ido.layouts.default,

   -- Prompt
   prompt = ">>> ",

   -- The keybindings in Ido
   keys = {
      ["<Right>"] = "stdlib.cursor.forward",
      ["<Left>"] = "stdlib.cursor.backward",

      ["<C-f>"] = "stdlib.cursor.forward",
      ["<C-b>"] = "stdlib.cursor.backward",

      ["<C-Right>"] = "stdlib.cursor.forward_word",
      ["<C-Left>"] = "stdlib.cursor.backward_word",

      ["<M-f>"] = "stdlib.cursor.forward_word",
      ["<M-b>"] = "stdlib.cursor.backward_word",

      ["<C-a>"] = "stdlib.cursor.line_start",
      ["<C-e>"] = "stdlib.cursor.line_end",

      ["<C-n>"] = "stdlib.items.next",
      ["<C-p>"] = "stdlib.items.prev",

      ["<Down>"] = "stdlib.items.next",
      ["<Up>"] = "stdlib.items.prev",

      ["<BS>"] = "stdlib.delete.backward",
      ["<Del>"] = "stdlib.delete.forward",

      ["<Tab>"] = "main.accept_suggestion",
      ["<CR>"] = "main.accept_selected",
      ["<Esc>"] = "main.exit",
   },

   -- Whether Ido should match case-sensitively
   case_sensitive = false,

   -- Whether Ido should match fuzzily
   fuzzy_matching = true,

   -- Characters which behave as word separators
   word_separators = "|/?,.;: ",
}

--- Setup Ido
-- The main interface to the configuration api
-- @param options The set of options which determine the setup
-- @return true if no errors were encountered, else nil
function ido.options.setup(options)

   -- Check if the options supplied is either a table or nil
   if type(options) ~= nil and type(options) ~= "table" then
      error("Expected table of options, got "..type(options).." instead", 2)
      return nil
   end

   -- Loop through the options, check for errors and apply them if none found
   for option, value in pairs(options) do

      -- Check if the options supplied is valid
      if option == "setup" or ido.options[option] == nil then
         error("Invalid option: "..option, 2)
         return nil
      end

      -- Check if the types match up
      if type(value) ~= type(ido.options[option]) then
         error("Expected "..option.." of type "..type(ido.options[option])..
         " but got "..type(value).." instead", 2)

         return nil
      end

      -- If the value is a table, it should be deepcopied
      if type(value) == "table" then
         value = vim.deepcopy(value)
      end

      -- Set the option
      ido.options[option] = value
   end

   return true
end

--- The sandboxed Ido environment
ido.sandbox = {}

-- Alias for the ido.core.main.start function
function ido.start(options)
   return require("ido.core.main").start(options)
end

return ido
