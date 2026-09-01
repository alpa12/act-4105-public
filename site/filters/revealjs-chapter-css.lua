local function is_revealjs()
  return quarto ~= nil
    and quarto.doc ~= nil
    and quarto.doc.is_format ~= nil
    and quarto.doc.is_format("revealjs")
end

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

local function assert_readable(path)
  local handle = io.open(path, "r")
  assert(handle ~= nil, "[chapter-css] Fichier CSS introuvable ou illisible: " .. path)
  handle:close()
end

function Pandoc(doc)
  if not is_revealjs() then
    return doc
  end

  local configured_path = meta_string(doc.meta["chapter-css"])
  if configured_path == nil then
    return doc
  end

  local input_file = current_input_file()
  assert(input_file ~= nil, "[chapter-css] Impossible de déterminer le document source.")

  local stylesheet = pandoc.path.join({
    pandoc.path.directory(input_file),
    configured_path
  })
  assert_readable(stylesheet)

  quarto.doc.add_resource(stylesheet)
  quarto.doc.include_text(
    "after-body",
    '<link rel="stylesheet" href="' .. configured_path .. '" data-act-chapter-css>'
  )

  return doc
end
