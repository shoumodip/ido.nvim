string.split = function(str, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

string.prefix = function(a, b)
   local limit = math.min(a:len(), b:len())

   for i = 1, limit do
      if a:sub(i, i) ~= b:sub(i, i) then
         return a:sub(1, i - 1)
      end
   end

   return a:sub(1, limit)
end
