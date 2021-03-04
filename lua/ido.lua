local main = require("ido.main")
local theme = require("ido.theme")
local config = require("ido.config")
local layout = require("ido.layout")
local module = require("ido.module")
local advice = require("ido.advice")
local cursor = require("ido.cursor")
local motion = require("ido.motion")
local delete = require("ido.delete")
local render = require("ido.render")
local result = require("ido.result")
local accept = require("ido.accept")
local package = require("ido.package")

-- @module ido The aliases file
local ido = {}

-- Aliases
ido.main = main
ido.theme = theme
ido.config = config
ido.layout = layout
ido.module = module
ido.advice = advice
ido.cursor = cursor
ido.motion = motion
ido.delete = delete
ido.render = render
ido.result = result
ido.accept = accept
ido.package = package

-- The start function
ido.start = main.start

-- Common point for setting up Ido
-- @param options table The table of options
-- @field default table The default options of Ido, supplied to `config.set`
-- @field packages table The packages configuration, supplied to `package.setup`
function ido.setup(options)
   if options.default then
      config.set(options.default)
   end

   if options.packages then
      package.setup(options.packages)
   end

   return true
end

return ido
