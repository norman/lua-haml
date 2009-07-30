function sorted_pairs(t, func)
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys, func)
  local iterator, _, index = ipairs(keys)
  return function()
    local _, key = iterator(keys, index)
    index = index + 1
    return key, t[key] 
  end, tab, index
end