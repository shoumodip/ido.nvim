local main = require("ido.main")
local config = require("ido.config")
local advice = require("ido.advice")
local event = require("ido.event")
local fzy = require("ido.fzy")

-- @module result Functions related to results
local result = {}

-- Get the matching items and the suggestion
-- @return true
function result.fetch()
   local variables = main.sandbox.variables
   local options = main.sandbox.options

   local query = variables.before..variables.after

   variables.selected = 1
   variables.suggestion = ""

   if #query > 0 then

      advice.wrap{
         name = "filter",
         action = function ()
            variables.results, variables.suggestion = fzy.filter(
               query,
               variables.items,
               options.case_sensitive,
               options.fuzzy_matching)
         end
      }
   else

      advice.wrap{
         name = "empty_query",
         action = function ()
            variables.suggestion = ""
            variables.results = {}

            for _, item in pairs(variables.items) do
               table.insert(variables.results, {item, 0})
            end
         end
      }
   end

   if #variables.results == 0 then

      advice.wrap{
         name = "no_results",
         action = function ()
            variables.selected = 0
         end
      }
   elseif #variables.results == 1 then

      advice.wrap{
         name = "single_result",
         action = function ()
            variables.suggestion = variables.results[1][1]
         end
      }
   end

   advice.wrap{
      name = "render",
      action = function ()
         require(config.options.renderer).main()
      end
   }

   return true
end

-- Switch to the next results
-- @return true
function result.next()

   local variables = main.sandbox.variables

   if #variables.results < 2 then
      advice.wrap{name = "not_found"}
   else
      advice.wrap{
         name = "switch",
         action = function ()

            variables.selected = variables.selected + 1

            -- Wrap around if out of bound
            if variables.selected > #variables.results then
               variables.selected = 1
            end
         end
      }

      advice.wrap{
         name = "render",
         action = function ()
            require(config.options.renderer).main()
         end
      }
   end

   return true
end

-- Switch to the previous results
-- @return true
function result.prev()

   local variables = main.sandbox.variables

   if #variables.results < 2 then
      advice.wrap{name = "not_found"}
   else
      advice.wrap{
         name = "switch",
         action = function ()

            variables.selected = variables.selected - 1

            -- Wrap around if out of bound
            if variables.selected <= 0 then
               variables.selected = #variables.results
            end
         end
      }

      advice.wrap{
         name = "render",
         action = function ()
            require(config.options.renderer).main()
         end
      }
   end

   return true
end

return result
