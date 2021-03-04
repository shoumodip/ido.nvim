-- @module layout How Ido looks
local layout = {}

-- The default layout of Ido
-- @field results_start string The decoration before the results
-- @field results_selected string The decoration before the selected result
-- @field results_separator string The decoration separating the results
-- @field results_end string The decoration after the results
-- @field suggest_start string The decoration before the suggestion
-- @field suggest_end string The decoration after the suggestion
-- @field maximum_height number The maximum possible height of the Ido interface
-- @field dynamic_resize boolean Dynamically resize to take up the least height possible
-- @field render_sequence table The sequence to render the tokens of Ido in
layout.default = {
   results_start = "{",
   results_selected = "",
   results_separator = " | ",
   results_end = "}",

   suggest_start = "[",
   suggest_end = "]",

   maximum_height = 1,
   dynamic_resize = false,

   render_sequence = {
      "prompt",
      "query",
      "results",
   }
}

-- Create new layout
-- Accepts a layout specification in the form of a table
-- The contents of the table has to be in the same format as shown
-- in the default layout
-- @param options table The specification for the layout
-- @return nil in case of errors, else true
function layout.new(options)

   -- Some error handling
   if options.name == nil then
      print("Name of the layout is not defined")
      return nil
   end

   if options.name == "new" then
      print("Invalid layout name: "..options.name)
      return nil
   end

   -- Register the layout
   layout[options.name] = vim.tbl_extend("keep", options, layout.default)
   layout[options.name].name = nil

   return true
end

return layout
