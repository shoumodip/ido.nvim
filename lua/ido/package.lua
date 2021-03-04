local main = require("ido.main")
local module = require("ido.module")

-- @module package
-- @field list table List of packages
local package = {
   list = {}
}

-- Register a new package
-- @param options table Options which specify the package
-- @field name string The name of the package
-- @field modules table The modules of the package
-- @return nil if errors were encountered, else true
function package.new(options)
   local name = options.name
   local modules = options.modules

   -- Basiv error detection
   if not (name and modules) then
      print("Name and modules of the package are mandatory")
      return nil
   end

   -- The magical step which registers a package
   package.list[name] = {}

   -- Add the module names to the list
   for _, module in pairs(modules) do
      package.list[name][module] = {}
   end

   -- `global` cannot be the name of a module
   if package.list[name].global then
      print("Invalid module name: "..global)
      package.list[name].global = nil
      return nil
   end

   return true
end

-- Setup the packages
-- @param packages table The table of options which specify the packages setup
-- The keys of the options table are the names of the packages
-- Their value are an options series of tables
-- The global table defines the options applied to every single module in the package
-- The table with the name of the module contains the options passed to the module
-- @return nil if errors were encountered, else true
function package.setup(packages)
   local global_options = {}

   for package_name, options in pairs(packages) do

      -- Load the package only if it exists
      local package_exists, package_code = pcall(require, "package_"..package_name)

      if not package_exists then
         print("Non existant package: "..package_name)
         return nil
      end

      -- User options and settings
      global_options = vim.deepcopy(options.global or {})
      options.global = nil
      options = vim.tbl_extend("force", package.list[package_name], options)

      -- Load the modules with the specified settings
      for module_name, module_options in pairs(options) do
         module_options.name = "ido/"..package_name.."_"..module_name
         module_options.fake_name = package_name.."/"..module_name

         module.load(vim.tbl_extend("force", global_options, module_options))
      end

   end

   return true
end

return package
