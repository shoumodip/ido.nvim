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

-- merge two tables
table.merge = function(t1, t2)
  for k,v in pairs(t2) do
    t1[k] = v
  end
  return t1
end
