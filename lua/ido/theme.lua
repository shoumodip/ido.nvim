-- @module theme Themes of Ido
local theme = {}

-- The default theme
-- Each element in this table is a table of properties
-- The properties are the options given to the highlight command
-- The key of each item is the option, and the value is the value
--
-- For example:
-- ["guifg"] = "#ebdbb2"
--
-- is converted to:
-- guifg=#ebdbb2
--
-- @field prompt table The prompt
-- @field normal table Normal text
-- @field cursor table The virtual cursor
-- @field ux table UX elements of the layout
-- @field suggestion table Suggestions
-- @field selected table The selected item
theme.default = {
   prompt     = {},
   normal     = {},
   cursor     = {},
   ux         = {},
   selected   = {},
   suggestion = {},
}

-- Create new theme
-- Accepts a theme specification in the form of a table
-- The contents of the table has to be in the same format as shown
-- in the default theme
-- @param options table The specification for the theme
-- @return nil in case of errors, else true
function theme.new(options)

   -- Undefined name
   if options.name == nil then
      print("Name of the theme is not defined")
      return nil
   end

   if options.name == "new" then
      print("Invalid theme name: "..options.name)
      return nil
   end

   -- Register the theme
   theme[options.name] = vim.tbl_extend("keep", options, theme.default)
   theme[options.name].name = nil

   -- Generate the command for the theme
   local command = ""

   -- Loop through the elements in the theme specification
   for element, definition in pairs(theme[options.name]) do

      local highlight_command = ""
      local highlight_name = "ido_"..element

      if definition.link then

         -- Link it to a highlight color
         highlight_command = "link "..highlight_name.." "..definition.link
      else

         -- Define it in terms of color constants
         highlight_command = highlight_name.." "

         for property, value in pairs(definition) do
            highlight_command = highlight_command..property.."="..value.." "
         end
      end

      -- Empty definition, default to a link to Normal
      if #highlight_command == #highlight_name + 1 then
         highlight_command = "link "..highlight_name.." Normal"
      end

      -- Append the command to the global command
      command = command.." | highlight! "..highlight_command
   end

   -- Load the theme
   vim.cmd(command:sub(4))

   return true
end

-- Create the default theme
theme.new{
   name       = "default",
   prompt     = {guifg = "#96a6c8", guibg = "#161616"},
   normal     = {guifg = "#ebdbb2", guibg = "#161616"},
   cursor     = {guifg = "#161616", guibg = "#cc8c3c"},
   ux         = {guifg = "#857c7f", guibg = "#161616"},
   selected   = {guifg = "#d79921", guibg = "#161616"},
   suggestion = {guifg = "#cc8c3c", guibg = "#161616", gui = "bold"},
}

return theme
