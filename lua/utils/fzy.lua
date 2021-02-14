local fzy_lua_native = vim.api.nvim_get_runtime_file("deps/fzy-lua-native/lua/native.lua", false)[1]
if not fzy_lua_native then
  error("Unable to find native fzy native lua dep file. Probably need to update submodules!")
end

local fzy_native = loadfile(fzy_lua_native)()

-- local fzy_native = require('fzy')
-- }}}

local fzy = {}

local OFFSET = -fzy_native.get_score_floor()
local FZY_MIN_SCORE = fzy_native.get_score_min()

function fzy.filter(needle, haystack)
  local matches = fzy_native.filter(needle, haystack)

  if #needle == 0 then return {}, {} end

  local matched_items = {}
  local true_matched_items = {}

  for index, match_data in pairs(matches) do
    local filename, positions = match_data[1], match_data[2]

    -- if fzy_native.score(needle, filename) == fzy_native.get_score_max() then
      -- exact match
      -- table.insert(true_matched_items, filename)
    -- else
      -- regular match
      table.insert(matched_items, filename)
    -- end
  end

  -- NOTE: very annoying that we have this sort function as it slows down the implementation quite a bit
  table.sort(matched_items, function(a,b)
    return fzy.sort(needle, a) < fzy.sort(needle, b)
  end)

  return matched_items, true_matched_items
end

-- Borrowed from telescope.nvim
-- https://github.com/nvim-telescope/telescope.nvim/blob/7d4d3462e990e2af489eb285aa7041d0b787c560/lua/telescope/sorters.lua#L377
function fzy.sort(prompt, line)
  -- Check for actual matches before running the scoring alogrithm.
  if not fzy_native.has_match(prompt, line) then
    return -1
  end

  local fzy_score = fzy_native.score(prompt, line)

  -- The fzy score is -inf for empty queries and overlong strings.  Since
  -- this function converts all scores into the range (0, 1), we can
  -- convert these to 1 as a suitable "worst score" value.
  if fzy_score == FZY_MIN_SCORE then
    return 1
  end

  -- Poor non-empty matches can also have negative values. Offset the score
  -- so that all values are positive, then invert to match the
  -- table.sort "smaller is better" convention. Note that for exact
  -- matches, fzy returns +inf, which when inverted becomes 0.
  return 1 / (fzy_score + OFFSET)
end

return fzy
