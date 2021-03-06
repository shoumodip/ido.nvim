local main = require("ido.main")
local event = require("ido.event")
local advice = require("ido.advice")
local cursor = require("ido.cursor")
local result = require("ido.result")

-- @module accept Accepting functions for Ido
local accept = {}

-- Accept the selected item
-- @return true
function accept.selected()

   advice.wrap{
      name = "stop_event_loop",
      action = function ()
         event.stop()
      end
   }

   if #main.sandbox.variables.results == 0 then
      advice.wrap{name = "no_results"}
   else
      advice.wrap{name = "accept"}
   end

   return true
end

-- Accept the suggestion
-- @return true
function accept.suggestion()

   local variables = main.sandbox.variables

   if #variables.suggestion == 0 then
      advice.wrap{name = "no_suggestion"}
   elseif #variables.results == 1 then
      advice.wrap{
         name = "single_result",
         action = function ()
            accept.selected()
         end
      }
   else
      advice.wrap{
         name = "append_to_query",
         action = function ()
            cursor.line_end()
            variables.before = variables.before..variables.suggestion
         end
      }

      advice.wrap{
         name = "fetch_results",
         action = function ()
            result.fetch()
         end
      }

      if #variables.results == 1 then
         advice.wrap{
            name = "single_result_after_fetching",
            action = function ()
               accept.selected()
            end
         }
      end
   end

   advice.wrap{
      name = "clear_suggestion",
      action = function ()
         variables.suggestion = ""
      end
   }

   return true
end

return accept
