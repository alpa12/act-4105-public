local chapter_order = nil
local section_index = 0

local function trim(value)
  if value == nil then
    return nil
  end
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function meta_string(value)
  if value == nil then
    return nil
  end
  return trim(pandoc.utils.stringify(value))
end

local function read_order_from_quarto_metadata()
  if quarto == nil or quarto.metadata == nil or quarto.metadata.get == nil then
    return nil
  end
  return meta_string(quarto.metadata.get("order"))
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

local function read_order_from_chapter_metadata()
  local input_file = current_input_file()
  if input_file == nil then
    return nil
  end

  local input_dir = pandoc.path.directory(input_file)
  local path = pandoc.path.join({ input_dir, "_metadata.yml" })
  local file = io.open(path, "r")

  if file == nil then
    return nil
  end

  local content = file:read("*a")
  file:close()

  for line in content:gmatch("[^\r\n]+") do
    local value = line:match("^%s*order:%s*(.-)%s*$")
    if value ~= nil then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"', ""):gsub('"$', "")
      value = value:gsub("^'", ""):gsub("'$", "")
      return trim(value)
    end
  end

  return nil
end

local function resolve_chapter_order(meta)
  chapter_order = chapter_order
    or meta_string(meta.order)
    or meta_string(meta["chapter-order"])
    or read_order_from_quarto_metadata()
    or read_order_from_chapter_metadata()
    or "0"

  return chapter_order
end

local function is_revealjs()
  if quarto == nil or quarto.doc == nil or quarto.doc.is_format == nil then
    return true
  end
  return quarto.doc.is_format("revealjs")
end

local function title_to_inlines(title)
  if title == nil then
    return nil
  end

  if title.t == "MetaInlines" or title.t == "Inlines" then
    return pandoc.List(title)
  end

  local text = meta_string(title)
  if text == nil or text == "" then
    return nil
  end

  return pandoc.List({ pandoc.Str(text) })
end

local function has_chapter_prefix(title)
  local text = meta_string(title)
  return text ~= nil and text:match("^Chapitre%s+[%w%.%-]+%s*:")
end

local function prefixed_title(order, original)
  local inlines = pandoc.List({
    pandoc.Str("Chapitre"),
    pandoc.Space(),
    pandoc.Str(order .. "\194\160:"),
    pandoc.LineBreak()
  })

  for _, inline in ipairs(original) do
    inlines:insert(inline)
  end

  return pandoc.MetaInlines(inlines)
end

local function strip_existing_section_number(inlines)
  if #inlines < 2 or inlines[1].t ~= "Str" then
    return inlines
  end

  if inlines[1].text:match("^%d+%.$") and inlines[2].t == "Space" then
    local stripped = pandoc.List()
    for i = 3, #inlines do
      stripped:insert(inlines[i])
    end
    return stripped
  end

  return inlines
end

function Meta(meta)
  if not is_revealjs() then
    return nil
  end

  local title = title_to_inlines(meta.title)
  if title == nil or has_chapter_prefix(meta.title) then
    return nil
  end

  meta.title = prefixed_title(resolve_chapter_order(meta), title)
  return meta
end

function Header(header)
  if not is_revealjs() or header.level ~= 1 then
    return nil
  end

  if header.classes:includes("unnumbered") then
    return nil
  end

  section_index = section_index + 1

  local content = pandoc.List({
    pandoc.Str(tostring(section_index) .. "."),
    pandoc.Space()
  })

  for _, inline in ipairs(strip_existing_section_number(header.content)) do
    content:insert(inline)
  end

  header.content = content
  return header
end
