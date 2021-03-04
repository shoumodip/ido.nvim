-- @module config Configure the behaviour of Ido
local config = {}

-- The default options of Ido
-- @field prompt string The prompt of Ido, defaults to ">>>"
-- @field layout string The layout of Ido, defaults to "default"
-- @field theme string The theme of Ido, defaults to "default"
-- @field render table The options of rendering
-- @field keys table Keys and their accompanied bindings
-- @field case_sensitive boolean Match items case-sensitively, defaults to false
-- @field fuzzy_matching boolean Match items fuzzily, defaults to true
-- @field word_separators string List of characters which act as word boundaries
config.options = {

   prompt = ">>> ",

   layout = "default",

   theme = "default",

   keys = {
      ["<Right>"] = "ido.cursor.forward",
      ["<Left>"] = "ido.cursor.backward",

      ["<C-f>"] = "ido.cursor.forward",
      ["<C-b>"] = "ido.cursor.backward",

      ["<C-Right>"] = "ido.cursor.forward_word",
      ["<C-Left>"] = "ido.cursor.backward_word",

      ["<M-f>"] = "ido.cursor.forward_word",
      ["<M-b>"] = "ido.cursor.backward_word",

      ["<C-a>"] = "ido.cursor.line_start",
      ["<C-e>"] = "ido.cursor.line_end",

      ["<C-n>"] = "ido.result.next",
      ["<C-p>"] = "ido.result.prev",

      ["<Down>"] = "ido.result.next",
      ["<Up>"] = "ido.result.prev",

      ["<BS>"] = "ido.delete.backward",
      ["<Del>"] = "ido.delete.forward",

      ["<C-k>"] = "ido.delete.backward",
      ["<C-d>"] = "ido.delete.forward",

      ["<C-BS>"] = "ido.delete.backward_word",
      ["<C-Del>"] = "ido.delete.forward_word",

      ["<M-k>"] = "ido.delete.backward_word",
      ["<M-d>"] = "ido.delete.forward_word",

      ["<C-w>"] = "ido.delete.line_start",
      ["<M-w>"] = "ido.delete.line_end",

      ["<Tab>"] = "ido.accept.suggestion",
      ["<CR>"] = "ido.accept.selected",
      ["<Esc>"] = "ido.event.exit"
   },

   case_sensitive = false,

   fuzzy_matching = true,

   word_separators = "|/?,.;: "
}

-- Configure Ido
-- @param options table The options to set, see config.options above
-- @return true
function config.set(options)
   config.options = vim.tbl_deep_extend("force", config.options, options)
   return true
end

return config
