local function has_class(classes, class)
  for _, value in ipairs(classes) do
    if value == class then
      return true
    end
  end
  return false
end

local function inline_text(inlines)
  return pandoc.utils.stringify(inlines)
    -- Lua character classes are byte-oriented. `%s` may consume one byte of
    -- a UTF-8 non-breaking space, leaving an invalid character in the title.
    :gsub("[ \t\r\n\f\v]+", " ")
    :gsub("^[ \t\r\n\f\v]+", "")
    :gsub("[ \t\r\n\f\v]+$", "")
    :gsub("^%d+%.[ \t\r\n\f\v]+", "")
end

local function html_escape(value)
  return value
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
end

local function overview_list(sections)
  local html = {
    '<ol class="act-print-overview-list" aria-label="Sections du chapitre">'
  }

  for index, section in ipairs(sections) do
    table.insert(
      html,
      '<li><span class="act-print-overview-number">' ..
        tostring(index) ..
      '</span><span class="act-print-overview-title">' ..
        html_escape(section.title) ..
        '</span><a class="act-print-overview-link" href="#' ..
        html_escape(section.target) ..
        '" aria-label="Aller à la section ' ..
        tostring(index) ..
        ' : ' ..
        html_escape(section.title) ..
        '"></a></li>'
    )
  end

  table.insert(html, "</ol>")
  return pandoc.RawBlock("html", table.concat(html, "\n"))
end

function Pandoc(doc)
  local sections = {}

  for index, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 1 and not has_class(block.classes, "progress-overview") then
      local title = inline_text(block.content)
      if title ~= "" then
        if block.identifier == "" then
          block.identifier = "act-print-section-" .. tostring(index)
        end
        table.insert(sections, { title = title, target = block.identifier })
      end
    end
  end

  if #sections == 0 then
    return nil
  end

  local blocks = {}
  for _, block in ipairs(doc.blocks) do
    table.insert(blocks, block)
    if block.t == "Header" and has_class(block.classes, "progress-overview") then
      table.insert(blocks, overview_list(sections))
    end
  end

  doc.blocks = blocks
  return doc
end
