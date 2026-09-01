local chapter_order = nil
local example_index = 0

local function trim(value)
  if value == nil then
    return nil
  end
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function has_class(classes, class_name)
  return classes:includes(class_name)
end

local function ensure_class(classes, class_name)
  if not has_class(classes, class_name) then
    classes:insert(class_name)
  end
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
  return meta_string(meta.order)
    or meta_string(meta["chapter-order"])
    or read_order_from_quarto_metadata()
    or read_order_from_chapter_metadata()
    or "0"
end

local function next_example_number()
  example_index = example_index + 1
  chapter_order = chapter_order
    or read_order_from_quarto_metadata()
    or read_order_from_chapter_metadata()
    or "0"
  return chapter_order .. "." .. tostring(example_index)
end

local function title_inlines(label, number, title)
  return pandoc.List({
    pandoc.Str(label),
    pandoc.Space(),
    pandoc.Str(number),
    pandoc.Space(),
    pandoc.Str("-"),
    pandoc.Space(),
    pandoc.Str(title)
  })
end

local function copy_header_attributes(header)
  if header == nil then
    return pandoc.Attr()
  end
  return pandoc.Attr(header.identifier, header.classes, header.attributes)
end

local function example_header(label, number, title, source_header, fallback_attr)
  local attr = source_header ~= nil and copy_header_attributes(source_header) or fallback_attr or pandoc.Attr()
  ensure_class(attr.classes, "act-example-slide")
  if label == "Solution" then
    ensure_class(attr.classes, "act-example-solution-slide")
    attr.attributes["data-state"] = "act-example-solution-background"
  else
    attr.attributes["data-state"] = "act-example-background"
  end
  attr.attributes["data-example-number"] = number

  return pandoc.Header(2, title_inlines(label, number, title), attr)
end

local function push_slide(slides, slide)
  if #slide.blocks == 0 then
    return
  end

  table.insert(slides, slide)
end

local function append_blocks(target, source)
  for _, block in ipairs(source) do
    target:insert(block)
  end
end

local function attributes_are_empty(attributes)
  for _, _ in pairs(attributes) do
    return false
  end
  return true
end

local function should_unwrap_div(div)
  return div.t == "Div"
    and (
      div.attributes["__quarto_custom_scaffold"] ~= nil
      or div.attributes["data-__quarto_custom_scaffold"] ~= nil
      or (#div.classes == 0 and div.identifier == "" and attributes_are_empty(div.attributes))
    )
end

local function is_quarto_proof_title(block)
  return (block.t == "Plain" or block.t == "Para")
    and pandoc.utils.stringify(block) == "Solution"
end

local function flatten_wrappers(blocks)
  local out = pandoc.List()

  for _, block in ipairs(blocks) do
    if is_quarto_proof_title(block) then
      -- Drop the proof title scaffold that Quarto creates for `.solution`.
    elseif should_unwrap_div(block) then
      append_blocks(out, flatten_wrappers(block.content))
    else
      out:insert(block)
    end
  end

  return out
end

local function split_slides(blocks, label, number, title, fallback_attr)
  blocks = flatten_wrappers(blocks)

  local slides = {}
  local current = {
    header = nil,
    blocks = pandoc.List()
  }

  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 2 then
      push_slide(slides, current)
      current = {
        header = block,
        blocks = pandoc.List()
      }
    else
      current.blocks:insert(block)
    end
  end

  push_slide(slides, current)

  local out = pandoc.List()
  if #slides == 0 then
    out:insert(example_header(label, number, title, nil, fallback_attr))
    return out
  end

  for _, slide in ipairs(slides) do
    out:insert(example_header(label, number, title, slide.header, fallback_attr))
    for _, block in ipairs(slide.blocks) do
      out:insert(block)
    end
  end

  return out
end

local function is_solution_block(block)
  return block.t == "Div"
    and (
      has_class(block.classes, "solution")
      or has_class(block.classes, "proof")
      or has_class(block.classes, "act-example-solution")
      or (#block.classes == 0 and block.identifier == "")
    )
end

local function solution_fallback_attr(block)
  local classes = pandoc.List()
  for _, class in ipairs(block.classes or {}) do
    if class ~= "solution" and class ~= "proof" and class ~= "act-example-solution" then
      classes:insert(class)
    end
  end
  return pandoc.Attr("", classes, {})
end

local function render_question_div(div)
  local title = trim(div.attributes.title or div.attributes["data-title"])
  if title == nil or title == "" then
    quarto.log.warning("Ignoring .question example block without title attribute")
    return nil
  end

  local number = next_example_number()
  local question_blocks = pandoc.List()
  local solution_blocks = pandoc.List()
  local solution_attr = nil

  for _, block in ipairs(div.content) do
    if is_solution_block(block) then
      solution_attr = solution_attr or solution_fallback_attr(block)
      append_blocks(solution_blocks, block.content)
    else
      question_blocks:insert(block)
    end
  end

  local out = pandoc.List()
  append_blocks(out, split_slides(question_blocks, "Exemple", number, title))

  if #solution_blocks > 0 then
    append_blocks(out, split_slides(solution_blocks, "Solution", number, title, solution_attr))
  end

  return out
end

function Meta(meta)
  chapter_order = resolve_chapter_order(meta)
  return meta
end

function Div(div)
  if not has_class(div.classes, "question") then
    return nil
  end

  return render_question_div(div)
end
