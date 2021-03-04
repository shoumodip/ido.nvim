local main = require("ido.main")
local options = require("ido.config").options

-- @module event The event loop of Ido
local event = {}

-- Timer
event.timer = vim.loop.new_timer()

-- Helper function for starting asynchronous jobs
-- @param action The function to execute
-- @return true
function event.async(action)
   event.timer:start(0, 0, vim.schedule_wrap(action))

   return true
end

-- Stop the event loop of Ido
-- @return true
function event.stop()
   main.sandbox.variables.looping = false

   return true
end

-- Exit Ido
-- @return true
function event.exit()
   main.sandbox.variables.results = {}
   event.stop()

   return true
end

-- Loop Ido
-- @return nil if errors were encountered, else true
function event.loop()
   local variables = main.sandbox.variables

   while (variables.looping) do

      local key_pressed = vim.fn.getchar()
      local binding = variables.bindings[key_pressed]

      if binding then
         if type(binding) == "function" then

            binding()
         elseif type(binding) == "string" then

            if binding:sub(1, 3) == "ido" then
               binding = binding:sub(5, -1)

               local binding_module = binding:gsub("%..*$", "")
               local binding_function = binding:gsub("^.*%.", "")

               require("ido."..binding_module)[binding_function]()

            else
               load(binding)()
            end
         else

            -- Invalid binding, throw error
            event.stop()
            print("Invalid binding for key: "..key_pressed, 3)

            return nil
         end
      else
         main.insert(vim.fn.nr2char(key_pressed))
      end

   end

   return true
end

return event
