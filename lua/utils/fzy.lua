-- load native fzy submodule {{{
local fzy_lua_native = vim.api.nvim_get_runtime_file("deps/fzy-lua-native/lua/native.lua", false)[1]
if not fzy_lua_native then
  error("Unable to find native fzy native lua dep file. Probably need to update submodules!")
end

local fzy_native = loadfile(fzy_lua_native)()
-- }}}

local fzy = {}

local OFFSET = -fzy_native.get_score_floor()
local FZY_MIN_SCORE = fzy_native.get_score_min()
local FZY_MAX_SCORE = fzy_native.get_score_max()

function fzy.score(match)
  local fzy_score = match[3]

  if not fzy_score then return -1 end

  -- The fzy score is -inf for empty queries and overlong strings.  Since
  -- this function converts all scores into the range (0, 1), we can
  -- convert these to 1 as a suitable "worst score" value.
  if fzy_score == FZY_MIN_SCORE then return 1 end

  -- Poor non-empty matches can also have negative values. Offset the score
  -- so that all values are positive, then invert to match the
  -- table.sort "smaller is better" convention. Note that for exact
  -- matches, fzy returns +inf, which when inverted becomes 0.
  return 1 / (fzy_score + OFFSET)
end

function fzy.filter(needle, haystack)
  return fzy_native.filter(needle, haystack)
end

return fzy
