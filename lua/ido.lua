-- @module ido The aliases file
local ido = {}

-- Aliases
ido.main = require("ido.main")
ido.theme = require("ido.theme")
ido.event = require("ido.event")
ido.config = require("ido.config")
ido.module = require("ido.module")
ido.advice = require("ido.advice")
ido.cursor = require("ido.cursor")
ido.motion = require("ido.motion")
ido.delete = require("ido.delete")
ido.render = require("ido.render")
ido.result = require("ido.result")
ido.accept = require("ido.accept")
ido.package = require("ido.package")

-- The start function
ido.start = ido.main.start

-- Common point for setting up Ido
-- @param options table The table of options
-- @field default table The default options of Ido, supplied to `config.set`
-- @field packages table The packages configuration, supplied to `package.setup`
function ido.setup(options)
   if options.default then
      ido.config.set(options.default)
   end

   if options.packages then
      ido.package.setup(options.packages)
   end

   return true
end

return ido
