--- @module Ido
local ido = {}

-- Internal variables of Ido
ido.vars = {
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

local function check_options(opt, value, refer)

   -- Check if the option is valid
   if refer[opt] == nil then
      error("Invalid option: "..opt, 3)
      return nil
   end

   -- Layout can be defined as a string also
   if opt == "layout" and type(value) == "string" then
      local layout = ido.layouts[value]

      -- Check if the layout is valid
      if type(layout) == "table" then
         value = vim.deepcopy(layout)
      else
         error("Invalid layout: "..value, 2)
         return nil
      end
   end

   -- Types mismatch
   if type(refer[opt]) ~= type(value) then
      error("Expected '"..opt.."' of type "..type(refer[opt])..
      " but got "..type(value).." instead", 3)

      return nil
   end

   return true
end

--- Setup a layout
-- @param name The name of the layout
-- @param opts The UX options in the layout
-- @param nil if errors encountered, else true
function ido.layouts.setup(name, opts)

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(name).." instead", 2)
      return nil
   end

   -- Check if the name is valid
   if name == "setup" or name == "default" then
      error("The name of a layout cannot be '"..name.."'", 2)
      return nil
   end

   -- Check the type of the options
   if type(opts) ~= "table" then
      error("Expected options of type table, got "..type(opts).." instead", 2)
      return nil
   end

   -- Check for user errors
   for opt, value in pairs(opts) do
      if not check_options(opt, value, ido.layouts.default) then return nil end
   end

   -- Load the missing options from the default layout
   opts = vim.tbl_extend("keep", opts, ido.layouts.default)

   -- No errors found, setup the layout
   ido.layouts[name] = opts
   return true
end

--- opts of Ido
ido.opts = {

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

   -- Whether Ido should return "" if no results found, instead of the query string
   strict_match = false,
}

--- Setup Ido
-- The main interface to the configuration api
-- @param opts The set of options which determine the setup
-- @return true if no errors were encountered, else nil
function ido.opts.setup(opts)

   -- Check if the options supplied is either a table or nil
   if opts ~= nil and type(opts) ~= "table" then
      error("Expected table of options, got "..type(opts).." instead", 2)
      return nil
   end

   -- Loop through the options, check for errors and apply them if none found
   for opt, value in pairs(opts) do

      -- Check the option
      if not check_options(opt, value, ido.opts) then return nil end

      -- Do not overwrite all the keybindings
      if opt == "keys" then
         ido.opts.keys = vim.tbl_extend("force", ido.opts.keys, value)

         goto continue
      end

      -- If the value is a table, it should be deepcopied
      if type(value) == "table" then
         value = vim.deepcopy(value)
      end

      -- Set the option
      ido.opts[opt] = value

      ::continue::
   end

   return true
end

--- The sandboxed Ido environment
ido.sandbox = {}

--- Alias for the ido.core.main.start()
-- @param opts The options to supply to ido.core.main.start()
-- @return exit value of ido.core.main.start()
function ido.start(opts)
   return require("ido.core.main").start(opts)
end

--- Packages implementation
ido.pkg = {

   -- A package template
   template = {
      opts = {},
      pkg_opts = {},
      bind = {},
      disable = {},
      main = function (pkg_opts) end,
   },

   -- A package keybinding template
   bind_template = {
      mode = "n",
      noremap = true,
      silent = true,
      buffer = false,
   },

   running = "",

   -- The list of packages
   list = {},
}

--- Bind an Ido package to a key
-- @param name The name of the package
-- @param opts The table of options
-- @return true if no errors were encountered, else nil
function ido.pkg.bind(name, opts)

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(name).." instead", 2)
      return nil
   end

   -- Check if a package with that name exists
   if ido.pkg.list[name] == nil then
      error("Non existant package: "..name, 2)
      return nil
   end

   -- Check the type of the opts
   if type(opts) ~= "table" then
      error("Expected options of type table, got "..type(opts).." instead", 2)
      return nil
   end

   if opts.key == nil then
      error("The keybinding is mandatory", 2)
      return nil
   end

   -- Check the options
   for opt, value in pairs(opts) do

      -- Key has to be a string and it has no default fallback value
      if opt == "key" then
         if type(value) ~= "string" then
            error("Expected keybinding of type string, got "..type(value).." instead", 2)
            return nil
         end
      else

         -- Check the option
         if not check_options(opt, value, ido.pkg.bind_template) then
            return nil
         end
      end
   end

   -- Load the fallback values
   opts = vim.tbl_extend("keep", opts, ido.pkg.bind_template)

   local command = vim.api.nvim_set_keymap

   -- Buffer local package
   if opts.buffer then
      command = function (mode, key, map, opts)
         vim.api.nvim_buf_set_keymap(0, mode, key, map, opts)
      end
   end

   -- Bind the key to the package
   command(opts.mode, opts.key,
   "<Esc>:lua require('ido').pkg.run('"..name:gsub("'", "\\'").."')<CR>",
   {
      noremap = opts.noremap,
      silent = opts.silent
   })

   return true
end

--- Create a new package
-- @param name The name of the package
-- @opts The table of options
-- @return true if no errors were encountered, else nil
function ido.pkg.new(name, opts)

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(name).." instead", 2)
      return nil
   end

   -- Package with that name already exists
   if ido.pkg.list[name] ~= nil then
      error("Package already exists: "..name, 2)
      return nil
   end

   -- Check the type of the options
   if type(opts) ~= "table" then
      error("Expected options of type table, got "..type(opts).." instead", 2)
      return nil
   end

   for opt, value in pairs(opts) do

      -- Check the option
      if not check_options(opt, value, ido.pkg.template) then return nil end

      if opt == "disable" then

         local disabled = {}

         for _, opt in pairs(value) do

            -- Check the option
            if ido.opts[opt] == nil then
               error("Invalid option: "..opt, 2)
               return nil
            end

            disabled[opt] = true
         end

         opts.disable = vim.deepcopy(disabled)
      end

   end

   -- Create the package
   ido.pkg.list[name] = vim.tbl_extend("keep", opts, ido.pkg.template)
   ido.pkg.list[name].history = {}

   if ido.pkg.list[name].bind.key ~= nil then
      return ido.pkg.bind(name, ido.pkg.list[name].bind)
   end

   return true
end

--- Setup the options of a package
-- @param name The name of the package
-- @param opts The table of options
-- @return true if no errors were encountered, else nil
function ido.pkg.setup(name, opts)

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(name).." instead", 2)
      return nil
   end

   -- Check if the package exists
   if ido.pkg.list[name] == nil then
      error("Non existant package: "..name, 2)
      return nil
   end

   opts = opts or {}

   -- Check the type of the options
   if type(opts) ~= "table" then
      error("Expected options of type table, got "..type(opts).." instead", 2)
      return nil
   end

   for opt, value in pairs(opts) do

      -- Check the option
      if not check_options(opt, value, ido.pkg.template) then return nil end

      if opt == "opts" then
         for opt, value in pairs(value) do

            if ido.pkg.list[name].disable[opt] == true then
               error("Option '"..opt.."' cannot be changed in package '"..name.."'", 2)
               return nil
            end

            -- Check the option
            if not check_options(opt, value, ido.opts) then return nil end
         end

      elseif opt == "bind" then
         value = vim.tbl_extend("keep", value, ido.pkg.list[name].bind)

      elseif opt == "pkg_opts" then
         value = vim.tbl_extend("keep", value, ido.pkg.list[name].pkg_opts)
      else
         error("Invalid option: "..opt, 2)
         return nil
      end

      -- Set the option
      ido.pkg.list[name][opt] = value
   end

   if ido.pkg.list[name].bind.key ~= nil then
      return ido.pkg.bind(name, ido.pkg.list[name].bind)
   end

   return true
end

--- Run a package
-- @param name The name of the package
-- @param pkg_opts Table with options passed to the package's main function
-- @return exit value of the package
function ido.pkg.run(name, pkg_opts)
   pkg_opts = pkg_opts or {}

   -- Check the type of the name
   if type(name) ~= "string" then
      error("Expected name of type string, got "..type(name).." instead", 2)
      return nil
   end

   -- Check if the package exists
   if ido.pkg.list[name] == nil then
      error("Non existant package: "..name, 2)
      return nil
   end

   ido.pkg.running = name
   return ido.pkg.list[name].main(vim.tbl_extend("force", pkg_opts, ido.pkg.list[name].pkg_opts))
end

--- Syntactic sugar over ido.start()
-- @param opts The options to supply to ido.start()
-- @return exit value of ido.start()
function ido.pkg.start(opts)
   return ido.start(vim.tbl_extend("force", opts, ido.pkg.list[ido.pkg.running].opts))
end

return ido
