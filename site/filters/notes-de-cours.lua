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
  if value.t == "MetaList" then
    return value
  end
  return { value }
end

local course_dir = "."

local function html_escape(text)
  if text == nil then
    return ""
  end
  return text
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
end

local function resolve_note_path(src)
  if src == nil or src == "" then
    return nil
  end
  if src:match("%.html$") then
    return src:gsub("%.html$", ".qmd")
  end
  if src:match("%.qmd$") then
    return src
  end
  if src:match("/$") then
    return src .. "diapos.qmd"
  end
  return src .. "/diapos.qmd"
end

local function resolve_diapo_output(src)
  if src == nil or src == "" then
    return nil
  end
  if src:match("%.qmd$") then
    return src:gsub("%.qmd$", ".html")
  end
  if src:match("%.html$") then
    return src
  end
  if src:match("/$") then
    return src .. "diapos.html"
  end
  return src .. "/diapos.html"
end

local function resolve_relative_path(src)
  if src == nil or src == "" then
    return nil
  end
  return pandoc.path.normalize(pandoc.path.join({ course_dir, src }))
end

local function read_note_title(src)
  local path = resolve_relative_path(resolve_note_path(src))
  if path == nil then
    return nil
  end

  local file = io.open(path, "r")
  if file == nil then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local yaml = content:match("^%-%-%-%s*\n(.-)\n%-%-%-%s*\n")
  if yaml == nil then
    return nil
  end

  local title = yaml:match('\ntitle:%s*"(.-)"')
    or yaml:match("\ntitle:%s*'(.-)'")
    or yaml:match("\ntitle:%s*(.-)\n")

  if title ~= nil then
    title = title:gsub("^%s+", ""):gsub("%s+$", "")
  end

  return title
end

local function render_diapo_embed(src)
  if src == nil or src == "" then
    return nil
  end

  local iframe_src = resolve_diapo_output(src)
  local title = read_note_title(src) or "Diapositives"

  return {
    pandoc.RawBlock(
    "html",
    string.format(
      '<div class="diapo-deck-frame"><iframe class="diapo-deck" src="%s" title="%s" loading="lazy" allowfullscreen></iframe></div>',
      iframe_src,
      html_escape(title)
    )
    )
  }
end

local course_notes = {}

function Meta(meta)
  if PANDOC_STATE ~= nil and PANDOC_STATE.input_files ~= nil and #PANDOC_STATE.input_files > 0 then
    course_dir = pandoc.path.directory(PANDOC_STATE.input_files[1])
  end
  course_notes = meta_list(meta["notes-de-cours"])
  return meta
end

function Div(div)
  if div.classes:includes("diapos") then
    local src = div.attributes.source or div.attributes.src or div.attributes.href
    return render_diapo_embed(src)
  end

  if div.classes:includes("notes-de-cours") then
    local blocks = {}

    for _, item in ipairs(course_notes) do
      if item.t == "MetaMap" then
        local src = meta_string(item.src or item.href or item.path)
        local rendered = render_diapo_embed(src)
        if rendered ~= nil then
          for _, block in ipairs(rendered) do
            blocks[#blocks + 1] = block
          end
        end
      end
    end

    return blocks
  end

  return nil
end
