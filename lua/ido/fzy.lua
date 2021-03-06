local ffi = require("ffi")

local os_aliases = {
   ["osx"] = "darwin",
}

local arch_aliases = {
   ["x64"] = "x86_64",
}

local os = os_aliases[jit.os:lower()] or jit.os:lower()
local arch = arch_aliases[jit.arch:lower()] or jit.arch:lower()

local native = ffi.load(debug.getinfo(1).source:sub(2,
   string.len("/lua/ido/fzy.lua") * -1 - 1)..
   "/deps/fzy-lua-native/static/libfzy-"..os.."-"..arch..".so")

ffi.cdef([[
int has_match(const char *needle, const char *haystack, int is_case_sensitive);

double match(const char *needle, const char *haystack, int is_case_sensitive);
double match_positions(const char *needle, const char *haystack, uint32_t *positions, int is_case_sensitive);
void match_positions_many(
const char *needle,
const char **haystacks,
uint32_t length,
double *scores,
uint32_t *positions,
int is_case_sensitive);
]])

-- @module fzy The interface to the Fzy algorithm for Ido
local fzy = {}

-- Get the last character position and the score of an item
-- @param query string The query or the pattern being matched in the item
-- @param item string The item which is being searched for the query
-- @param is_case_sensitive boolean Whether it should search case-sensitively
-- @return the last character position and the score
local function item_results(query, item, is_case_sensitive)
   local length = #query
   local positions = ffi.new("uint32_t["..length.."]", {})

   local score = native.match_positions(query, item, positions, is_case_sensitive)

   return positions[length - 1] + 1, score
end

-- Get the common prefix between two strings
-- @param a string The first string
-- @param b string The second string
-- @return the prefix
local function get_suggestion(a, b)
   local limit = math.min(#a, #b)

   for i = 1, limit do
      if a:sub(i, i) ~= b:sub(i, i) then
         return a:sub(1, i - 1)
      end
   end

   return a:sub(1, limit)
end

-- Filter the list
-- @param query string The query or the pattern being matched in the item
-- @param item table The item which is being searched for the query
-- @param is_case_sensitive boolean Search case-sensitively, defaults to false
-- @param fuzzy_matching boolean Search fuzzily, defaults to true
-- @return table of matched items in form of item and score, and suggestion
function fzy.filter(query, items, is_case_sensitive, fuzzy_matching)
   local results = {}
   local init_suggestion = false
   local suggestion = ""

   if fuzzy_matching == nil then
      fuzzy_matching = true
   end

   -- Filter the items
   for i = 1, #items do
      local item = items[i]

      if native.has_match(query, item, false) == 1 then
         local last_char_pos, score = item_results(query, item, is_case_sensitive)

         -- It is a true match, calculate the prefix
         if string.find(item, query, 1, true) then
            local suggest_source = item:sub(last_char_pos + 1)

            if not init_suggestion then
               suggestion = suggest_source
               init_suggestion = true
            else
               suggestion = get_suggestion(suggestion, suggest_source)
            end

         else
            if not fuzzy_matching then goto continue end
         end

         table.insert(results, {item, score})
      end

      ::continue::
   end

   -- Sort the items
   table.sort(results, function (left, right)
      return left[2] > right[2]
   end)

   return results, suggestion
end

return fzy
