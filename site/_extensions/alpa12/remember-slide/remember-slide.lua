local defaults = {
  title = "Remember this",
  enabled = true,
  include_css = true,
  marker_class = "remember-slide",
  summary_marker_class = "remember-slides",
  previous_opacity = "0.35",
  current_opacity = "1",
  current_font_weight = "inherit",
  font_size = "0.72em",
  dense_font_size = "0.62em",
  dense_threshold = 4,
  list_style_type = "disc",
  list_gap = "0.35em",
  content_width = "100%",
  content_max_width = "none",
  title_margin_bottom = "0.35em",
  item_line_height = "1.15",
  list_padding_left = "1.05em",
  fit_text = false,
  fit_threshold = 3,
  fit_class = "r-fit-text",
  previous_class = "remember-slide-previous",
  current_class = "remember-slide-current",
  content_class = "remember-slide-content",
  recap_class = "remember-slide-recap",
  summary_recap_class = "remember-slides-recap"
}

local function warn(message)
  if quarto ~= nil and quarto.log ~= nil and quarto.log.warning ~= nil then
    quarto.log.warning("[remember-slide] " .. message)
  else
    io.stderr:write("[remember-slide] " .. message .. "\n")
  end
end

local function is_revealjs()
  if quarto ~= nil and quarto.doc ~= nil and quarto.doc.is_format ~= nil then
    return quarto.doc.is_format("revealjs")
  end

  return FORMAT ~= nil and FORMAT:match("revealjs") ~= nil
end

local function meta_to_string(value, fallback)
  if value == nil then
    return fallback
  end

  local value_type = type(value)
  if value_type == "string" or value_type == "number" or value_type == "boolean" then
    return tostring(value)
  end

  local rendered = pandoc.utils.stringify(value)
  if rendered == "" then
    return fallback
  end
  return rendered
end

local function meta_to_bool(value, fallback)
  if value == nil then
    return fallback
  end

  if type(value) == "boolean" then
    return value
  end

  local rendered = pandoc.utils.stringify(value):lower()
  if rendered == "true" or rendered == "yes" or rendered == "1" then
    return true
  end
  if rendered == "false" or rendered == "no" or rendered == "0" then
    return false
  end

  return fallback
end

local function meta_to_number(value, fallback, option_name)
  local rendered = meta_to_string(value, nil)
  if rendered == nil then
    return fallback
  end

  local parsed = tonumber(rendered)
  if parsed == nil then
    if option_name ~= nil then
      warn(option_name .. " must be a number. Using " .. tostring(fallback) .. ".")
    end
    return fallback
  end

  return parsed
end

local function clamp_opacity(value, fallback, option_name)
  local parsed = meta_to_number(value, tonumber(fallback), option_name)
  if parsed == nil then
    warn(option_name .. " must be a number between 0 and 1. Using " .. fallback .. ".")
    return fallback
  end

  if parsed < 0 or parsed > 1 then
    warn(option_name .. " must be between 0 and 1. Using " .. fallback .. ".")
    return fallback
  end

  return tostring(parsed)
end

local function non_empty(value, fallback, option_name)
  local rendered = meta_to_string(value, fallback)
  if rendered == "" then
    warn(option_name .. " is empty. Using " .. fallback .. ".")
    return fallback
  end
  return rendered
end

local function read_config(meta)
  local raw_options = meta["remember-slide"]

  if raw_options == false then
    return { enabled = false }
  end

  local options = {}
  if raw_options ~= nil then
    if type(raw_options) == "table" then
      options = raw_options
    else
      warn("remember-slide must be a YAML object or false. Using default options.")
    end
  end

  return {
    enabled = meta_to_bool(options["enabled"], defaults.enabled),
    include_css = meta_to_bool(options["include-css"], defaults.include_css),
    title = meta_to_string(options["title"], defaults.title),
    marker_class = non_empty(options["class"], defaults.marker_class, "remember-slide.class"),
    summary_marker_class = non_empty(
      options["summary-class"],
      defaults.summary_marker_class,
      "remember-slide.summary-class"
    ),
    previous_opacity = clamp_opacity(
      options["previous-opacity"],
      defaults.previous_opacity,
      "remember-slide.previous-opacity"
    ),
    current_opacity = clamp_opacity(
      options["current-opacity"],
      defaults.current_opacity,
      "remember-slide.current-opacity"
    ),
    current_font_weight = non_empty(
      options["current-font-weight"],
      defaults.current_font_weight,
      "remember-slide.current-font-weight"
    ),
    font_size = non_empty(options["font-size"], defaults.font_size, "remember-slide.font-size"),
    dense_font_size = non_empty(
      options["dense-font-size"],
      defaults.dense_font_size,
      "remember-slide.dense-font-size"
    ),
    dense_threshold = meta_to_number(
      options["dense-threshold"],
      defaults.dense_threshold,
      "remember-slide.dense-threshold"
    ),
    list_style_type = non_empty(
      options["list-style-type"],
      defaults.list_style_type,
      "remember-slide.list-style-type"
    ),
    list_gap = non_empty(options["list-gap"], defaults.list_gap, "remember-slide.list-gap"),
    content_width = non_empty(
      options["content-width"],
      defaults.content_width,
      "remember-slide.content-width"
    ),
    content_max_width = non_empty(
      options["content-max-width"],
      defaults.content_max_width,
      "remember-slide.content-max-width"
    ),
    title_margin_bottom = non_empty(
      options["title-margin-bottom"],
      defaults.title_margin_bottom,
      "remember-slide.title-margin-bottom"
    ),
    item_line_height = non_empty(
      options["item-line-height"],
      defaults.item_line_height,
      "remember-slide.item-line-height"
    ),
    list_padding_left = non_empty(
      options["list-padding-left"],
      defaults.list_padding_left,
      "remember-slide.list-padding-left"
    ),
    fit_text = meta_to_bool(options["fit-text"], defaults.fit_text),
    fit_threshold = meta_to_number(
      options["fit-threshold"],
      defaults.fit_threshold,
      "remember-slide.fit-threshold"
    ),
    fit_class = non_empty(options["fit-class"], defaults.fit_class, "remember-slide.fit-class"),
    previous_class = non_empty(
      options["previous-class"],
      defaults.previous_class,
      "remember-slide.previous-class"
    ),
    current_class = non_empty(
      options["current-class"],
      defaults.current_class,
      "remember-slide.current-class"
    ),
    content_class = non_empty(
      options["content-class"],
      defaults.content_class,
      "remember-slide.content-class"
    ),
    recap_class = non_empty(options["recap-class"], defaults.recap_class, "remember-slide.recap-class"),
    summary_recap_class = non_empty(
      options["summary-recap-class"],
      defaults.summary_recap_class,
      "remember-slide.summary-recap-class"
    ),
    slide_level = meta_to_number(
      options["slide-level"],
      meta_to_number(meta["slide-level"], nil, "slide-level"),
      "remember-slide.slide-level"
    )
  }
end

local function normalize_config(config)
  if not config.enabled then
    return config
  end

  if config.marker_class == config.recap_class then
    warn("remember-slide.class and remember-slide.recap-class must be different. Using "
      .. defaults.recap_class
      .. " for recap-class.")
    config.recap_class = defaults.recap_class
  end

  if config.summary_marker_class == config.recap_class
      or config.summary_marker_class == config.summary_recap_class then
    warn("remember-slide.summary-class must differ from generated recap classes. Using "
      .. defaults.summary_marker_class
      .. " for summary-class.")
    config.summary_marker_class = defaults.summary_marker_class
  end

  if config.summary_recap_class == config.recap_class then
    warn("remember-slide.summary-recap-class and remember-slide.recap-class must be different. Using "
      .. defaults.summary_recap_class
      .. " for summary-recap-class.")
    config.summary_recap_class = defaults.summary_recap_class
  end

  return config
end

local function has_class(element, class_name)
  if element == nil or element.classes == nil then
    return false
  end

  for _, class in ipairs(element.classes) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function unique_classes(classes)
  local seen = {}
  local result = {}

  for _, class in ipairs(classes) do
    if class ~= nil and class ~= "" and not seen[class] then
      table.insert(result, class)
      seen[class] = true
    end
  end

  return result
end

local function is_remember_slide_header(block, config)
  return block.t == "Header"
    and has_class(block, config.marker_class)
    and not has_class(block, config.recap_class)
    and not has_class(block, config.summary_recap_class)
end

local function is_remember_slide_div(block, config)
  return block.t == "Div"
    and has_class(block, config.marker_class)
    and not has_class(block, config.recap_class)
    and not has_class(block, config.summary_recap_class)
end

local function is_summary_slide_header(block, config)
  return block.t == "Header"
    and has_class(block, config.summary_marker_class)
    and not has_class(block, config.recap_class)
    and not has_class(block, config.summary_recap_class)
end

local function is_summary_slide_div(block, config)
  return block.t == "Div"
    and has_class(block, config.summary_marker_class)
    and not has_class(block, config.recap_class)
    and not has_class(block, config.summary_recap_class)
end

local function is_next_slide_header(block, stop_level)
  return block.t == "Header" and block.level <= stop_level
end

local function title_inlines(title)
  local parsed = pandoc.read(title, "markdown")
  if #parsed.blocks == 1 and parsed.blocks[1].t == "Para" then
    return parsed.blocks[1].content
  end

  return pandoc.Inlines({ pandoc.Str(title) })
end

local function heading_title_inlines(block, config)
  if block.content ~= nil and #block.content > 0 then
    return block.content
  end

  return title_inlines(config.title)
end

local function font_size_for(config, item_count)
  if item_count >= config.dense_threshold then
    return config.dense_font_size
  end

  return config.font_size
end

local function style_attributes(config, item_count)
  return table.concat({
    "--remember-slide-previous-opacity: " .. config.previous_opacity .. ";",
    "--remember-slide-current-opacity: " .. config.current_opacity .. ";",
    "--remember-slide-current-font-weight: " .. config.current_font_weight .. ";",
    "--remember-slide-font-size: " .. font_size_for(config, item_count) .. ";",
    "--remember-slide-list-style-type: " .. config.list_style_type .. ";",
    "--remember-slide-list-gap: " .. config.list_gap .. ";",
    "--remember-slide-content-width: " .. config.content_width .. ";",
    "--remember-slide-content-max-width: " .. config.content_max_width .. ";",
    "--remember-slide-title-margin-bottom: " .. config.title_margin_bottom .. ";",
    "--remember-slide-item-line-height: " .. config.item_line_height .. ";",
    "--remember-slide-list-padding-left: " .. config.list_padding_left .. ";"
  }, " ")
end

local function content_classes(config, item_count)
  local classes = { config.content_class }

  if config.fit_text and item_count >= config.fit_threshold then
    table.insert(classes, config.fit_class)
  end

  return classes
end

local function recap_slide(items, current_index, slide_level, config, options)
  options = options or {}
  local bullet_items = {}

  for index, item_blocks in ipairs(items) do
    local item_class = config.previous_class
    if options.all_current or index == current_index then
      item_class = config.current_class
    end

    local item = pandoc.List:new()
    item:insert(pandoc.Div(item_blocks, pandoc.Attr("", { item_class }, {})))
    table.insert(bullet_items, item)
  end

  local heading_classes = unique_classes({
    "remember-slide",
    config.recap_class,
    options.extra_class
  })

  return {
    pandoc.Header(
      slide_level,
      options.title_inlines or title_inlines(config.title),
      pandoc.Attr("", heading_classes, { { "style", style_attributes(config, #items) } })
    ),
    pandoc.Div(
      { pandoc.BulletList(bullet_items) },
      pandoc.Attr("", content_classes(config, #items), {})
    )
  }
end

local function inferred_slide_level(blocks, config)
  if config.slide_level ~= nil then
    return config.slide_level
  end

  for _, block in ipairs(blocks) do
    if is_remember_slide_header(block, config) then
      return block.level
    end
  end

  return 2
end

local function insert_generated_slide(output, items, current_index, slide_level, config, options)
  for _, generated_block in ipairs(recap_slide(items, current_index, slide_level, config, options)) do
    output:insert(generated_block)
  end
end

local function skip_marker_body(blocks, index, stop_level)
  index = index + 1
  while index <= #blocks and not is_next_slide_header(blocks[index], stop_level) do
    index = index + 1
  end
  return index
end

local function replace_remember_slides(blocks, config)
  local output = pandoc.List:new()
  local remembered_items = {}
  local doc_slide_level = inferred_slide_level(blocks, config)
  local transformed_count = 0
  local index = 1

  while index <= #blocks do
    local block = blocks[index]

    if is_summary_slide_header(block, config) then
      local slide_level = block.level
      local stop_level = math.max(slide_level, doc_slide_level)

      if #remembered_items == 0 then
        warn("Found a remember-slides summary before any remember-slide items.")
      end

      insert_generated_slide(
        output,
        remembered_items,
        #remembered_items,
        slide_level,
        config,
        {
          all_current = true,
          extra_class = config.summary_recap_class,
          title_inlines = heading_title_inlines(block, config)
        }
      )
      transformed_count = transformed_count + 1
      index = skip_marker_body(blocks, index, stop_level)
    elseif is_remember_slide_header(block, config) then
      local slide_level = block.level
      local stop_level = math.max(slide_level, doc_slide_level)
      local item_blocks = pandoc.List:new()

      index = index + 1
      while index <= #blocks and not is_next_slide_header(blocks[index], stop_level) do
        item_blocks:insert(blocks[index])
        index = index + 1
      end

      if #item_blocks == 0 then
        warn("Found an empty remember slide; generating an empty recap item.")
        item_blocks:insert(pandoc.Plain({}))
      end

      table.insert(remembered_items, item_blocks)
      transformed_count = transformed_count + 1
      insert_generated_slide(
        output,
        remembered_items,
        #remembered_items,
        slide_level,
        config
      )
    elseif is_summary_slide_div(block, config) then
      if #remembered_items == 0 then
        warn("Found a remember-slides summary before any remember-slide items.")
      end

      insert_generated_slide(
        output,
        remembered_items,
        #remembered_items,
        doc_slide_level,
        config,
        {
          all_current = true,
          extra_class = config.summary_recap_class
        }
      )
      transformed_count = transformed_count + 1
      index = index + 1
    elseif is_remember_slide_div(block, config) then
      local item_blocks = pandoc.List:new(block.content)

      if #item_blocks == 0 then
        warn("Found an empty remember div; generating an empty recap item.")
        item_blocks:insert(pandoc.Plain({}))
      end

      table.insert(remembered_items, item_blocks)
      transformed_count = transformed_count + 1
      insert_generated_slide(
        output,
        remembered_items,
        #remembered_items,
        doc_slide_level,
        config
      )
      index = index + 1
    else
      output:insert(block)
      index = index + 1
    end
  end

  return output, transformed_count
end

local function add_css_dependency(config, transformed_count)
  if transformed_count == 0 or not config.include_css then
    return
  end

  if quarto == nil or quarto.doc == nil or quarto.doc.add_html_dependency == nil then
    warn("Could not register remember-slide.css outside the Quarto Lua runtime.")
    return
  end

  quarto.doc.add_html_dependency({
    name = "remember-slide",
    version = "0.1.0",
    stylesheets = { "remember-slide.css" }
  })
end

function Pandoc(doc)
  local config = normalize_config(read_config(doc.meta))
  if not config.enabled then
    return doc
  end

  if not is_revealjs() then
    warn("This extension targets revealjs output. The document was left unchanged.")
    return doc
  end

  local transformed_count
  doc.blocks, transformed_count = replace_remember_slides(doc.blocks, config)
  add_css_dependency(config, transformed_count)
  return doc
end
