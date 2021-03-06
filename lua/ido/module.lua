-- @module module Modules system in Ido
local module = {

   -- @field options table Ido options and their values
   -- @field settings table Package specific settings
   -- @field binding table Specifications for the keybinding
   -- @field disabled table Ido options which are disabled
   -- @field main function Entry point for the package, like main() in C
   template = {
      options = {},
      settings = {},
      binding = {mode = "major"},
      disabled = {},
      main = function () end,
   },

   binding_mode_map = {
      ["major"]    = "",  -- Like `noremap`
      ["normal"]   = "n", -- Like `nnoremap`
      ["visual"]   = "v", -- Like `vnoremap`
      ["select"]   = "s", -- Like `snoremap`
      ["operator"] = "o", -- Like `onoremap`
      ["command"]  = "c", -- Like `cnoremap`
      ["insert"]   = "i", -- Like `inoremap`
      ["terminal"] = "t", -- Like `tnoremap`
   },

   running = false,

   list = {},
}

-- Load a module
-- @param options table Options which specify the setup, same as the module
-- template except the `main` and `disabled` options
-- @return nil in case of errors, else true
function module.load(options)
   local name = options.name

   -- Error handling
   if not name then
      print("The name of the module is not given")
      return nil
   end

   if name == "global" then
      print("Unallowed module name: global")
      return nil
   end

   -- Actually load the module
   package.loaded[name] = nil
   local module_exists, module_code = pcall(require, name)

   -- More error handling
   if not module_exists then
      print("Non existant or erroneous module: "..name)
      return nil
   end

   local name = options.fake_name or name

   -- Add the module main() to the list of module main() functions
   if module_code.main then
      module.list[name] = module_code.main
   end

   module_code.settings = module_code.settings or {}
   module_code.options = module_code.options or {}
   module_code.binding = module_code.binding or {}
   module_code.disabled = module_code.disabled or {}

   -- Set the settings
   if options.settings then
      for setting, value in pairs(options.settings) do

         if type(value) == "table" then
            value = vim.deepcopy(value)
         end

         module_code.settings[setting] = value
      end
   end

   -- Set the options
   if options.options then
      for option, value in pairs(options.options) do
         if module_code.disabled[option] then
            print("Disabled option in Ido module '"..name.."': "..option)
            return nil
         end

         if type(value) == "table" then
            value = vim.deepcopy(value)
         end

         module_code.options[option] = value
      end
   end

   -- Set the binding
   if options.binding then
      module_code.binding.key = options.binding.key or module_code.binding.key
      module_code.binding.mode = options.binding.mode or module_code.binding.mode
   end

   if module_code.main and module_code.binding.key then
      vim.cmd(
         module.binding_mode_map[module_code.binding.mode or "major"].. -- The mode
         "noremap "..                                                   -- Non recursive
         module_code.binding.key..                                      -- The keybinding
         " <Esc>:lua require('ido.module').run('"..name.."')<CR>"       -- The mapping
      )
   end

   return true
end

-- Run a module
-- @param name string The name of the module
-- @param args The arguments supplied to the module
-- @return nil in case of errors, else exit value of the module's main function
function module.run(name, args)

   -- Basic error detection
   if not name then
      print("The name of the package must be given")
      return nil
   end

   if not module.list[name] then
      print("main() not present or non existant module: "..name)
      return nil
   end

   module.running = name:gsub("^([^/]+)/", "ido/%1_")
   return module.list[name](args)
end

return module
