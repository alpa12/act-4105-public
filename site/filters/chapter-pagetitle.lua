local function current_input_file()
  if quarto ~= nil and quarto.doc ~= nil and quarto.doc.input_file ~= nil then
    return quarto.doc.input_file
  end

  if PANDOC_STATE ~= nil and PANDOC_STATE.input_files ~= nil and #PANDOC_STATE.input_files > 0 then
    return PANDOC_STATE.input_files[1]
  end

  return nil
end

local function meta_string(value)
  if value == nil then
    return nil
  end

  local rendered = pandoc.utils.stringify(value)
  rendered = rendered:gsub("^%s+", ""):gsub("%s+$", "")
  return rendered ~= "" and rendered or nil
end

local function document_label()
  local input_file = current_input_file()
  if input_file == nil then
    return nil
  end

  local filename = pandoc.path.filename(input_file)
  if filename == "diapos.qmd" then
    return "Notes"
  end
  if filename == "exercices.qmd" then
    return "Exercices"
  end

  return nil
end

function Meta(meta)
  local kind = document_label()
  local order = meta_string(meta.order)
  local label = meta_string(meta.label)

  if kind == nil or order == nil or label == nil then
    return meta
  end

  meta.pagetitle = pandoc.MetaString(order .. ". " .. label .. " - " .. kind)
  meta["title-prefix"] = pandoc.MetaString("")
  return meta
end
