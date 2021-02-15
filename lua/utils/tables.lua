-- Filter tables based on a given predicate (function)
table.filter = function(t, p)
  local out = {}

  for k, v in pairs(t) do
    if p(v, k, t) then table.insert(out, v) end
  end

  return out
end

-- Recursively Print table
table.print = function(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      table.print(v, indent+1)
    else
      print(formatting .. v)
    end
  end
end

-- Apply a function on every element of a table
table.map = function(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

-- Pluck nth element on every nested table
table.pluck = function(tbl, index)
  local out = {}

  for k,v in pairs(tbl) do
    table.insert(out, v[index])
  end

  return out
end

-- Find out the common prefix from a table of strings
table.prefix = function(t)
  local shortest, prefix, first = math.huge, ""

  for i, str in pairs(t) do
    if str:len() < shortest then
      shortest = str:len()
    end
  end

  for strPos = 1, shortest do
    if t[1] then
      first = t[1]:sub(strPos, strPos)
    else
      return prefix
    end

    for listPos = 2, #t do
      if t[listPos]:sub(strPos, strPos) ~= first then
        return prefix
      end
    end

    prefix = prefix .. first
  end
  return prefix
end

table.unique = function(t)

  local out = {}
  local hash = {}

  for _,v in ipairs(t) do
    if (not hash[v]) then
      table.insert(out, v)
      hash[v] = true
    end

  end

  return out
end
