local function meta_string(value)
  if value == nil then
    return nil
  end

  return pandoc.utils.stringify(value)
end

local function meta_list(value)
  if value == nil then
    return {}
  end

  if type(value) == "table" then
    return value
  end

  return { value }
end

local function current_input_file()
  if quarto and quarto.doc and quarto.doc.input_file ~= nil then
    return quarto.doc.input_file
  end

  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    return PANDOC_STATE.input_files[1]
  end

  return nil
end

local function is_html_output()
  if quarto and quarto.doc and quarto.doc.is_format then
    return quarto.doc.is_format("html")
  end

  return FORMAT ~= nil and FORMAT:match("html") ~= nil
end

local function is_course_page()
  local input_file = current_input_file()
  if input_file == nil then
    return false
  end

  local normalized = input_file:gsub("\\", "/")
  return normalized:match("cours/%d%d%.qmd$") ~= nil
end

local function html_escape(text)
  return (text or "")
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
end

local function course_date(first_class_date, week_id)
  local year, month, day = first_class_date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  local week = tonumber(week_id)

  if year == nil or month == nil or day == nil or week == nil then
    return nil
  end

  local timestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day) + ((week - 1) * 7),
    hour = 12
  })

  return os.date("%Y-%m-%d", timestamp)
end

local function chapter_field(chapter, field)
  if type(chapter) ~= "table" then
    return nil
  end

  return meta_string(chapter[field])
end

local function chapter_number(path)
  local number = path:match("/(%d+)-")
  return number and tostring(tonumber(number)) or nil
end

local function resource_path(path, resource)
  local normalized = path:gsub("^/", ""):gsub("/$", "")
  return "../" .. normalized .. "/" .. resource
end

function Meta(meta)
  if not is_course_page() then
    return meta
  end

  local week_id = meta_string(meta["week-id"])
  local title = meta_string(meta.title)

  if week_id ~= nil and title ~= nil then
    meta.title = pandoc.MetaString("Cours " .. week_id .. " : " .. title)
  end

  return meta
end

function Pandoc(document)
  if not is_html_output() or not is_course_page() then
    return document
  end

  local first_class_date = meta_string(document.meta["first-class-date"])
  local week_id = meta_string(document.meta["week-id"])
  local date = first_class_date and week_id and course_date(first_class_date, week_id) or nil
  local chapters = meta_list(document.meta.chapitres)
  local html = { '<section class="course-overview" aria-label="Ressources du cours">' }

  if date ~= nil then
    table.insert(
      html,
      string.format(
        '<p class="course-date"><strong>Date&nbsp;:</strong> <time datetime="%s">%s</time></p>',
        html_escape(date),
        html_escape(date)
      )
    )
  end

  if #chapters > 0 then
    table.insert(html, '<div class="course-resources">')
    table.insert(html, '<table class="course-resources-table table">')
    table.insert(html, '<thead><tr><th scope="col">Chapitre</th><th scope="col">Notes</th><th scope="col">Exercices</th></tr></thead>')
    table.insert(html, '<tbody>')

    for _, chapter in ipairs(chapters) do
      local path = chapter_field(chapter, "path")
      local title = chapter_field(chapter, "title")

      if path ~= nil and title ~= nil then
        local number = chapter_number(path)
        local label = number and ("Chapitre " .. number .. " — " .. title) or title

        table.insert(
          html,
          string.format(
            '<tr><td>%s</td><td><a href="%s">Notes</a></td><td><a href="%s">Exercices</a></td></tr>',
            html_escape(label),
            html_escape(resource_path(path, "diapos.html")),
            html_escape(resource_path(path, "exercices.html"))
          )
        )
      end
    end

    table.insert(html, '</tbody></table></div>')
  end

  table.insert(html, '</section>')
  table.insert(document.blocks, 1, pandoc.RawBlock("html", table.concat(html)))

  return document
end
