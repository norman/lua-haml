module("haml.markup.tags", package.seeall)

function open(phrase)
  local attributes = {}
  local buffer = {"<", phrase.markup_tag}
  if phrase.css_classes then
    attributes.class = string.gsub(phrase.css_classes, "%.", " ")
  end
  if phrase.css_id then
    attributes.id = phrase.css_id
  end
  if not table.empty(attributes) then
    for k, v in sorted_pairs(attributes) do
      table.insert(buffer, string.format(" %s='%s'", k, v))
    end
  end
  table.insert(buffer, '>')
  return table.concat(buffer, '')
end