local function suppression_requested(meta)
  local value = meta["suppress-title-prefix"]

  return value ~= nil and pandoc.utils.stringify(value) == "true"
end

function Meta(meta)
  if not suppression_requested(meta) then
    return meta
  end

  local title = pandoc.utils.stringify(meta.title)
  title = title:gsub("^Chapitre.-:[%s]*", "")
  meta.title = pandoc.MetaString(title)

  return meta
end
