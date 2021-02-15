-- NOTE: using local fork for now awaiting resolution of following fzy-lua-native PR:
-- https://github.com/romgrk/fzy-lua-native/pull/10
local fzy_lua_native = "/users/alexanderjeurissen/Development/open-source/fzy-lua-native/lua/native.lua"
-- local fzy_lua_native = vim.api.nvim_get_runtime_file("deps/fzy-lua-native/lua/native.lua", false)[1]
if not fzy_lua_native then
  error("Unable to find native fzy native lua dep file. Probably need to update submodules!")
end

local fzy_native = loadfile(fzy_lua_native)()
-- }}}

local fzy = {}

local OFFSET = -fzy_native.get_score_floor()
local FZY_MIN_SCORE = fzy_native.get_score_min()
local FZY_MAX_SCORE = fzy_native.get_score_max()

-- Borrowed from telescope.nvim
-- And optimized for  our usecase
-- https://github.com/nvim-telescope/telescope.nvim/blob/7d4d3462e990e2af489eb285aa7041d0b787c560/lua/telescope/sorters.lua#L377
local function normalized_score(match)
  local _filename, _positions, fzy_score = unpack(match)

  if not fzy_score then return -1 end

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

function fzy.filter(needle, haystack)
  -- Step 1. Obtain matches using native fzy implementation
  local matches = fzy_native.filter(needle, haystack)

  -- Step 2. Return all matches if the search query is empty
  if #needle == 0 then return table.pluck(matches, 1), {} end

  -- Step 3. Sort the matches using the normalized fzy score
  -- see normalized_score function for more detail
  table.sort(matches, function(a,b)
    return normalized_score(a) < normalized_score(b)
  end)

  -- Step 4. Differentiate between exact matches and regular matches
  -- NOTE: Some of this can be refactored and cleaned up after we refactored the table.prefix
  local matched_items = table.filter(matches, function(match, _index, _tbl)
    local score = match[3]

    return score < FZY_MAX_SCORE
  end)

  local true_matched_items = table.filter(matches, function(match, _index, _tbl)
    local score = match[3]

    return score == FZY_MAX_SCORE
  end)

  matched_items = table.pluck(matched_items, 1)
  true_matched_items = table.pluck(true_matched_items, 1)

  return matched_items, true_matched_items
end

return fzy
