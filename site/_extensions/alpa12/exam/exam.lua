local stringify = pandoc.utils.stringify
local reader = "markdown+yaml_metadata_block+fenced_divs"

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function parent_dir(path)
  local normalized = path:gsub("\\", "/"):gsub("/$", "")
  return normalized:gsub("/[^/]+$", "")
end

local function current_dir()
  if pandoc.system and pandoc.system.get_working_directory then
    local cwd = pandoc.system.get_working_directory()
    if cwd and cwd ~= "" then
      return cwd
    end
  end

  local pwd = os.getenv("PWD")
  if pwd and pwd ~= "" then
    return pwd
  end

  return "."
end

local function find_project_root()
  if quarto.project.directory and quarto.project.directory ~= "" then
    return quarto.project.directory
  end

  local current = current_dir()
  for _ = 1, 12 do
    if file_exists(current .. "/_quarto.yml") then
      return current
    end
    local parent = parent_dir(current)
    if parent == current then
      break
    end
    current = parent
  end

  return current
end

local root = find_project_root()

local profiles = quarto.project.profile or {}
local teacher = false
local instructions_only = false
for _, profile in ipairs(profiles) do
  teacher = teacher or profile == "corrige"
  instructions_only = instructions_only or profile == "instructions"
end

local document_type
local is_homework = false
local is_exercise = false
local show_solutions = false
local show_grading = false
local document_title = ""
local document_pagetitle = ""
local chapter_order = ""
local chapter_label = ""

local function has_class(el, class)
  return el.classes and el.classes:includes(class)
end

local function is_true(value)
  return tostring(value) == "true" or tostring(value) == "yes" or tostring(value) == "1"
end

local function fail(message)
  io.stderr:write("\27[31;1mERROR:\27[0m " .. message .. "\n")
  os.exit(1)
end

local function warn(message)
  io.stderr:write("\27[33;1mWARN:\27[0m " .. message .. "\n")
end

local function read_file(path)
  local candidates = { path }
  if not path:match("^/") then
    table.insert(candidates, root .. "/" .. path)

    local input_files = PANDOC_STATE.input_files or {}
    local input_file = input_files[1]
    if input_file and input_file ~= "" then
      table.insert(candidates, root .. "/" .. parent_dir(input_file) .. "/" .. path)
    end
  end

  for _, candidate in ipairs(candidates) do
    local file = io.open(candidate, "r")
    if file then
      local text = file:read("*a")
      file:close()
      return text
    end
  end

  fail("Impossible de lire le fichier: " .. path)
end

local function meta_string(meta, name, default)
  local value = meta[name]
  if value == nil then
    return default or ""
  end
  return stringify(value)
end

local function meta_number(meta, name, default)
  local value = meta[name]
  if value == nil then
    return default
  end

  local number = tonumber(stringify(value))
  if number == nil then
    fail("La metadonnee `" .. name .. "` doit etre un nombre.")
  end

  if math.floor(number) ~= number then
    fail("La metadonnee `" .. name .. "` doit etre un entier.")
  end

  return number
end

local function meta_boolean(meta, name, default)
  local value = meta[name]
  if value == nil then
    return default
  end

  local text = stringify(value):lower()
  if text == "true" or text == "yes" or text == "1" then
    return true
  end
  if text == "false" or text == "no" or text == "0" then
    return false
  end

  fail("La metadonnee `" .. name .. "` doit etre booleenne (`true` ou `false`).")
end

local function shows_solutions()
  return teacher or (is_exercise and show_solutions)
end

local function shows_grading()
  return teacher or (is_exercise and show_grading)
end

local function hides_answer_spaces()
  return teacher or (is_exercise and show_solutions)
end

local function parse_date(date_value, name)
  local text = stringify(date_value)
  local year, month, day = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if year == nil then
    fail("La metadonnee `" .. name .. "` doit avoir le format AAAA-MM-JJ.")
  end

  local timestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = 12,
    min = 0,
    sec = 0
  })

  if timestamp == nil then
    fail("La metadonnee `" .. name .. "` contient une date invalide.")
  end

  return timestamp
end

local function format_date(timestamp)
  local date = os.date("*t", timestamp)
  return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

local function add_weeks_to_date(date_value, weeks, source_name)
  local timestamp = parse_date(date_value, source_name)
  return format_date(timestamp + (weeks * 7 * 24 * 60 * 60))
end

local function resolve_week_id_date(doc, week_id_name, target_name, first_class_date)
  local week_id = meta_number(doc.meta, week_id_name, nil)
  if week_id == nil then
    return ""
  end

  if first_class_date == "" then
    fail("La metadonnee `first-class-date` est requise pour calculer `" .. target_name .. "` a partir de `" .. week_id_name .. "`.")
  end

  if week_id < 1 then
    fail("La metadonnee `" .. week_id_name .. "` doit etre superieure ou egale a 1.")
  end

  return add_weeks_to_date(first_class_date, week_id - 1, "first-class-date")
end

local function resolve_assessment_dates(doc, document_type)
  if document_type == "exercice" then
    return
  end

  local first_class_date = meta_string(doc.meta, "first-class-date", "")

  if document_type == "exam" then
    local exam_date = meta_string(doc.meta, "exam-date", "")
    if exam_date == "" then
      exam_date = resolve_week_id_date(doc, "week-id", "exam-date", first_class_date)
    end
    if exam_date == "" then
      fail("Un document `exam` doit definir `exam-date` ou `week-id`.")
    end
    doc.meta["exam-date"] = pandoc.MetaString(exam_date)
    return
  end

  local exam_date = meta_string(doc.meta, "exam-date", "")
  if exam_date == "" then
    exam_date = resolve_week_id_date(doc, "given-week-id", "exam-date", first_class_date)
  end
  if exam_date == "" then
    fail("Un document `homework` doit definir `exam-date` ou `given-week-id`.")
  end
  doc.meta["exam-date"] = pandoc.MetaString(exam_date)

  local due_date = meta_string(doc.meta, "due-date", "")
  if due_date == "" then
    due_date = resolve_week_id_date(doc, "due-week-id", "due-date", first_class_date)
  end
  if due_date == "" then
    fail("Un document `homework` doit definir `due-date` ou `due-week-id`.")
  end
  doc.meta["due-date"] = pandoc.MetaString(due_date)
end

local function typst_escape(text)
  text = tostring(text or "")
  text = text:gsub("\\", "\\\\")
  text = text:gsub('"', '\\"')
  text = text:gsub("%[", "\\[")
  text = text:gsub("%]", "\\]")
  text = text:gsub("#", "\\#")
  return text
end

local function typst_string_escape(text)
  text = tostring(text or "")
  text = text:gsub("\\", "\\\\")
  return text:gsub('"', '\\"')
end

local function typst_bool(value)
  return value and "true" or "false"
end

local function attr_number(div, name, required, default)
  local raw = div.attributes[name]
  if raw == nil or raw == "" then
    if required then
      fail("Le bloc ." .. table.concat(div.classes, ".") .. " doit declarer `" .. name .. "`.")
    end
    return default
  end
  local value = tonumber(raw)
  if value == nil then
    fail("La valeur `" .. name .. "=\"" .. tostring(raw) .. "\"` doit etre numerique.")
  end
  return value
end

local function is_fill(value)
  return tostring(value or ""):lower() == "fill"
end

local function attr_length(div, name, default)
  local value = div.attributes[name]
  if value == nil or value == "" then
    return default
  end
  if is_fill(value) then
    return "1fr"
  end
  if value:match("^[%d%.]+$") then
    return value .. "cm"
  end
  return value
end

local question_points

local function points_in_child_questions(blocks)
  local total = 0
  local found = false
  for _, block in ipairs(blocks) do
    if block.t == "Div" and has_class(block, "question") then
      total = total + question_points(block)
      found = true
    end
  end
  return total, found
end

local function has_child_question(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Div" and has_class(block, "question") then
      return true
    end
  end
  return false
end

function question_points(div)
  local own = div.attributes.points and tonumber(div.attributes.points) or nil
  if div.attributes.points and own == nil then
    fail("La valeur `points=\"" .. tostring(div.attributes.points) .. "\"` doit etre numerique.")
  end

  local child_total, has_children = points_in_child_questions(div.content)
  if div.attributes.points and has_children then
    fail("Une question qui contient d'autres questions ne doit pas declarer `points`. Retirez `points=\"" .. tostring(div.attributes.points) .. "\"` du bloc `.question`; seul le niveau le plus bas peut avoir des points. Le total sera calcule automatiquement avec la somme des questions enfants (" .. tostring(child_total) .. ").")
  end
  if own then
    return own
  end
  if has_children then
    return child_total
  end
  return attr_number(div, "points", not is_exercise, 0)
end

local function question_points_label(div)
  if has_child_question(div.content) then
    return ""
  end
  if is_exercise and (div.attributes.points == nil or div.attributes.points == "") then
    return ""
  end
  return tostring(question_points(div))
end

local function alpha(number)
  local letters = ""
  repeat
    local remainder = (number - 1) % 26
    letters = string.char(97 + remainder) .. letters
    number = math.floor((number - 1) / 26)
  until number == 0
  return letters
end

local function roman(number)
  local values = {
    { 1000, "m" }, { 900, "cm" }, { 500, "d" }, { 400, "cd" },
    { 100, "c" }, { 90, "xc" }, { 50, "l" }, { 40, "xl" },
    { 10, "x" }, { 9, "ix" }, { 5, "v" }, { 4, "iv" }, { 1, "i" }
  }
  local out = ""
  for _, pair in ipairs(values) do
    while number >= pair[1] do
      out = out .. pair[2]
      number = number - pair[1]
    end
  end
  return out
end

local function nested_question_label(depth, number)
  local style = (depth - 1) % 3
  if style == 0 then
    return alpha(number) .. ")"
  end
  if style == 1 then
    return roman(number) .. ")"
  end
  return tostring(number) .. ")"
end

local function next_nested_question(ctx)
  local depth = (ctx.question_depth or 0) + 1
  ctx.question_counters = ctx.question_counters or {}
  ctx.question_counters[depth] = (ctx.question_counters[depth] or 0) + 1
  for index = depth + 1, #ctx.question_counters do
    ctx.question_counters[index] = nil
  end
  return depth, ctx.question_counters[depth]
end

local function child_context(ctx, depth)
  local next_ctx = {}
  for key, value in pairs(ctx) do
    next_ctx[key] = value
  end
  next_ctx.question_depth = depth
  next_ctx.inside_question = true
  return next_ctx
end

local function raw_block(code)
  return pandoc.RawBlock("typst", code)
end

local function raw_inline(code)
  return pandoc.RawInline("typst", code)
end

local function reject_removed_div_syntax(div)
  if has_class(div, "short-answer") then
    fail("Syntaxe de question invalide: utilisez `.question` avec les attributs d'espace de reponse, par exemple `::: {.question points=\"2\" width=\"8cm\"}`.")
  end

  if has_class(div, "exam-questions") then
    fail("Syntaxe d'inclusion invalide: ajoutez les questions avec des inclusions Quarto dans `index.qmd`, par exemple `{{< include questions/q01.qmd >}}`.")
  end
end

local function wrap_question_line(blocks, label, points, bonus)
  blocks:insert(1, raw_block("#exam-question-line(label: \"" .. typst_escape(label) .. "\", points: \"" .. typst_escape(points) .. "\", bonus: " .. typst_bool(bonus) .. ")["))
  blocks:insert(3, raw_block("]"))
  return blocks
end

local function prepend_question_label(blocks, number, points, bonus)
  if #blocks == 0 or blocks[1].t ~= "Para" then
    blocks:insert(1, raw_block("#exam-question-heading(number: \"" .. typst_escape(number) .. "\", points: \"" .. typst_escape(points) .. "\", bonus: " .. typst_bool(bonus) .. ")"))
    return blocks
  end

  if bonus then
    blocks[1].content:insert(1, pandoc.Space())
    blocks[1].content:insert(1, raw_inline("#text(size: 8pt, weight: \"bold\", fill: rgb(\"#9a3412\"))[BONUS]"))
  end
  return wrap_question_line(blocks, tostring(number) .. ".", points, bonus)
end

local function prepend_nested_question_label(blocks, label, points, bonus)
  if #blocks == 0 or blocks[1].t ~= "Para" then
    blocks:insert(1, raw_block("#exam-nested-question-heading(label: \"" .. typst_escape(label) .. "\", points: \"" .. typst_escape(points) .. "\", bonus: " .. typst_bool(bonus) .. ")"))
    return blocks
  end

  if bonus then
    blocks[1].content:insert(1, pandoc.Space())
    blocks[1].content:insert(1, raw_inline("#text(size: 8pt, weight: \"bold\", fill: rgb(\"#9a3412\"))[BONUS]"))
  end
  return wrap_question_line(blocks, label, points, bonus)
end

local transform_question_like_content

local function transform_nested_question(div, ctx)
  local depth, number = next_nested_question(ctx)
  local points = question_points_label(div)
  local bonus = is_true(div.attributes.bonus)
  local inset = math.min(depth * 7, 21)
  local blocks = pandoc.List:new({ raw_block("#block(width: 100%, inset: (left: " .. tostring(inset) .. "mm))[") })
  local content = transform_question_like_content(div, child_context(ctx, depth))
  prepend_nested_question_label(content, nested_question_label(depth, number), points, bonus)
  blocks:extend(content)
  blocks:insert(raw_block("]"))
  return blocks
end

local function is_solution_div(div)
  return has_class(div, "solution") or (has_class(div, "proof") and has_class(div, "solution"))
end

local function strip_quarto_solution_label(blocks)
  if #blocks == 0 or blocks[1].t ~= "Para" then
    return blocks
  end

  local inlines = blocks[1].content
  if #inlines < 2 then
    return blocks
  end

  if inlines[1].t == "Emph" and stringify(inlines[1]) == "Solution" then
    inlines:remove(1)
    if #inlines > 0 and inlines[1].t == "Str" and inlines[1].text:match("^%.") then
      local rest = inlines[1].text:gsub("^%.%s*", "")
      inlines:remove(1)
      if rest ~= "" then
        inlines:insert(1, pandoc.Str(rest))
      end
    end
  end

  return blocks
end

local function is_solution_para(block)
  if block.t ~= "Para" or #block.content == 0 then
    return false
  end
  return block.content[1].t == "Emph" and stringify(block.content[1]) == "Solution"
end

local function strip_solution_para_label(block)
  local inlines = block.content
  inlines:remove(1)
  if #inlines > 0 and inlines[1].t == "Str" and inlines[1].text:match("^%.") then
    local rest = inlines[1].text:gsub("^%.%s*", "")
    inlines:remove(1)
    if rest ~= "" then
      inlines:insert(1, pandoc.Str(rest))
    end
  end
  return block
end

local function typst_setup(doc)
  local header_title
  if is_exercise then
    header_title = "#exam-workbook-running-title()"
  else
    header_title = "#text(size: 11pt)[" .. typst_escape(meta_string(doc.meta, "exam-date", "")) .. "]"
  end

  local footer_body
  if is_homework or is_exercise then
    footer_body = table.concat({
      "      #align(center)[#text(size: 10pt)[#counter(page).display() de #counter(page).final().first()]]"
    }, "\n")
  else
    footer_body = table.concat({
      "      #grid(columns: (1fr, auto, 1fr), align: horizon,",
      "        [],",
      "        [#text(size: 10pt)[#counter(page).display() de #counter(page).final().first()]],",
      "        [#align(right)[#grid(columns: (auto, 16mm), column-gutter: 2mm, align: horizon,",
      "          [#box(height: 8mm)[#align(horizon)[#text(size: 10pt)[Initiales]]]],",
      "          [#box(width: 16mm, height: 8mm, stroke: 0.4pt)[]],",
      "        )]],",
      "      )"
    }, "\n")
  end

  return raw_block(table.concat({
    document_pagetitle ~= "" and "#set document(title: \"" .. typst_string_escape(document_pagetitle) .. "\")" or "",
    "#set table(",
    "  inset: (x: 5.5pt, y: 4.5pt),",
    "  stroke: 0.4pt + rgb(\"#b8c1cc\"),",
    "  fill: (x, y) => if y == 0 { rgb(\"#eef2f7\") } else { none },",
    ")",
    "#show table: set text(size: 11pt)",
    "#show table.cell.where(y: 0): set text(weight: \"semibold\")",
    "#set page(",
    "  paper: \"us-letter\",",
    "  margin: (top: 28.5mm, bottom: 27mm, left: 21mm, right: 21mm),",
    "  header: context [",
    "    #if counter(page).get().first() > 1 [",
    "      #align(center)[#block(width: 162mm)[",
    "        #v(9.5mm)",
    "        #box(width: 100%)[",
    "          #text(size: 11pt)[" .. typst_escape(meta_string(doc.meta, "course-number", "")) .. "]",
    "          #h(1fr)",
    "          " .. header_title,
    "        ]",
    "        #v(-1.8mm)",
    "        #line(length: 100%, stroke: 0.55pt)",
    "      ]]",
    "    ]",
    "  ],",
    "  footer: context [",
    "    #if counter(page).get().first() > 1 [",
    footer_body,
    "    ]",
    "  ],",
    ")"
  }, "\n"))
end

local function answer_space_from_attrs(attrs)
  if hides_answer_spaces() then
    return pandoc.List:new()
  end

  local raw_lines = attrs.lines
  local lines = tonumber(raw_lines or "")
  local width = attrs.width or "8cm"
  local kind = attrs.type or "line"
  local height = attrs.height
  local full = is_true(attrs["full-width"])
  if kind == "lines" and is_fill(height) and attrs.width == nil and attrs["full-width"] == nil then
    full = true
  end

  if kind == "lines" then
    if is_fill(height) or is_fill(raw_lines) then
      return pandoc.List:new({
        raw_block("#exam-answer-lines-fill(full: " .. typst_bool(full) .. ", width: " .. width .. ")")
      })
    end
    if lines then
      return pandoc.List:new({
        raw_block("#exam-answer-lines(lines: " .. tostring(lines) .. ", full: " .. typst_bool(full) .. ", width: " .. width .. ")")
      })
    end
    return pandoc.List:new({ raw_block("#exam-answer-line(width: " .. width .. ")") })
  end

  if kind == "box" or height ~= nil then
    if is_fill(height) then
      return pandoc.List:new({ raw_block("#exam-answer-box-fill()") })
    end
    if not height then
      height = tostring(lines or 8) .. "em"
    end
    return pandoc.List:new({ raw_block("#exam-answer-box(height: " .. height .. ")") })
  end

  if is_fill(raw_lines) then
    return pandoc.List:new({
      raw_block("#exam-answer-lines-fill(full: " .. typst_bool(full) .. ", width: " .. width .. ")")
    })
  end

  if lines then
    return pandoc.List:new({
      raw_block("#exam-answer-lines(lines: " .. tostring(lines) .. ", full: " .. typst_bool(full) .. ", width: " .. width .. ")")
    })
  end

  return pandoc.List:new({ raw_block("#exam-answer-line(width: " .. width .. ")") })
end

local transform_blocks

local function is_answer_space_fill(div)
  return has_class(div, "answer-space")
    and (is_fill(div.attributes.height) or is_fill(div.attributes.lines))
end

local function has_answer_space_attrs(div)
  return div.attributes.lines ~= nil
    or div.attributes.width ~= nil
    or div.attributes["full-width"] ~= nil
    or div.attributes.type ~= nil
    or (div.attributes.height ~= nil and not has_class(div, "plot-area"))
end

local function plot_area_from_attrs(div)
  if hides_answer_spaces() then
    return pandoc.List:new()
  end
  local height = attr_length(div, "height", "12cm")
  return pandoc.List:new({ raw_block("#exam-plot-area(height: " .. height .. ")") })
end

local function table_area_from_attrs(div)
  if hides_answer_spaces() then
    return pandoc.List:new()
  end
  if is_fill(div.attributes.rows) then
    return pandoc.List:new({ raw_block("#exam-table-area-fill()") })
  end
  local rows = attr_number(div, "rows", false, 10)
  return pandoc.List:new({ raw_block("#exam-table-area(rows: " .. tostring(rows) .. ")") })
end

local function trueorfalse_blocks(div)
  local correct = div.attributes.correct
  local inlines = pandoc.List:new({
    raw_inline("#exam-choice-mark(selected: " .. typst_bool(shows_solutions() and correct == "true") .. ")"),
    pandoc.Space(),
    pandoc.Str("Vrai"),
    pandoc.Space(),
    raw_inline("#h(0.8em)"),
    raw_inline("#exam-choice-mark(selected: " .. typst_bool(shows_solutions() and correct == "false") .. ")"),
    pandoc.Space(),
    pandoc.Str("Faux")
  })
  return pandoc.List:new({ pandoc.Para(inlines) })
end

local function choice_para(choice)
  local selected = shows_solutions() and is_true(choice.attributes.correct)
  return pandoc.Para({
    raw_inline("#exam-choice-mark(selected: " .. typst_bool(selected) .. ")"),
    pandoc.Space(),
    pandoc.Str(stringify(choice.content))
  })
end

local function transform_choices_content(div, ctx)
  local blocks = pandoc.List:new()
  for _, block in ipairs(div.content) do
    if block.t == "Div" and has_class(block, "choice") then
      blocks:insert(choice_para(block))
    else
      blocks:extend(transform_blocks(pandoc.List:new({ block }), ctx))
    end
  end
  return blocks
end

transform_question_like_content = function(div, ctx)
  local blocks
  if has_class(div, "choices") then
    blocks = transform_choices_content(div, ctx)
  else
    blocks = transform_blocks(div.content, ctx)
  end

  if has_class(div, "trueorfalse") then
    blocks:extend(trueorfalse_blocks(div))
  end
  if has_class(div, "plot-area") then
    blocks:extend(plot_area_from_attrs(div))
  elseif has_class(div, "table-area") then
    blocks:extend(table_area_from_attrs(div))
  elseif has_answer_space_attrs(div) then
    blocks:extend(answer_space_from_attrs(div.attributes))
  end

  return blocks
end

local function transform_div(div, ctx)
  reject_removed_div_syntax(div)

  if has_class(div, "student-only") then
    if teacher then
      return pandoc.List:new()
    end
    return transform_blocks(div.content, ctx)
  end

  if has_class(div, "teacher-only") then
    if not teacher then
      return pandoc.List:new()
    end
    return transform_blocks(div.content, ctx)
  end

  if is_solution_div(div) then
    if not shows_solutions() then
      return pandoc.List:new()
    end
    local blocks = pandoc.List:new({
      raw_block("#exam-solution-block(["),
      raw_block("#exam-solution-title(\"Solution\")")
    })
    blocks:extend(transform_blocks(strip_quarto_solution_label(div.content), ctx))
    blocks:insert(raw_block("])"))
    return blocks
  end

  if has_class(div, "grading") then
    if not shows_grading() then
      return pandoc.List:new()
    end
    local blocks = pandoc.List:new({
      raw_block("#exam-grading-block(["),
      raw_block("#exam-grading-title()")
    })
    blocks:extend(transform_blocks(div.content, ctx))
    blocks:insert(raw_block("])"))
    return blocks
  end

  if has_class(div, "answer") then
    if shows_solutions() then
      local blocks = pandoc.List:new({
        raw_block("#exam-solution-block(["),
        raw_block("#exam-solution-title(\"Réponse\")")
      })
      blocks:extend(transform_blocks(div.content, ctx))
      blocks:insert(raw_block("])"))
      return blocks
    end
    return answer_space_from_attrs(div.attributes)
  end

  if has_class(div, "answer-space") then
    return answer_space_from_attrs(div.attributes)
  end

  if has_class(div, "extra-work") then
    if teacher then
      return pandoc.List:new()
    end
    local pages = attr_number(div, "pages", false, 1)
    local kind = div.attributes.type or "blank"
    if kind ~= "blank" and kind ~= "lines" then
      fail("Le type de .extra-work doit etre `blank` ou `lines`.")
    end
    local blocks = pandoc.List:new()
    for _ = 1, pages do
      blocks:insert(raw_block("#exam-extra-work-page(kind: \"" .. kind .. "\")"))
    end
    return blocks
  end

  if has_class(div, "question") and ctx.inside_question then
    return transform_nested_question(div, ctx)
  end

  if has_class(div, "plot-area") then
    return transform_question_like_content(div, ctx)
  end

  if has_class(div, "table-area") then
    return transform_question_like_content(div, ctx)
  end

  if has_class(div, "trueorfalse") then
    return transform_question_like_content(div, ctx)
  end

  if has_class(div, "choices") then
    return transform_question_like_content(div, ctx)
  end

  div.content = transform_blocks(div.content, ctx)
  return pandoc.List:new({ div })
end

transform_blocks = function(blocks, ctx)
  local out = pandoc.List:new()
  for _, block in ipairs(blocks) do
    if block.t == "Div" then
      if has_class(block, "answer-space") then
        if not hides_answer_spaces() and ctx.previous_answer_space_fill then
          out:insert(raw_block("#pagebreak()"))
        end
        out:extend(transform_div(block, ctx))
        ctx.previous_answer_space_fill = not hides_answer_spaces() and is_answer_space_fill(block)
      else
        out:extend(transform_div(block, ctx))
        if not (has_class(block, "solution") or has_class(block, "proof") or has_class(block, "teacher-only") or has_class(block, "grading")) then
          ctx.previous_answer_space_fill = false
        end
      end
    elseif is_solution_para(block) then
      if shows_solutions() then
        out:insert(raw_block("#exam-solution-title(\"Solution\")"))
        out:insert(strip_solution_para_label(block))
      end
      ctx.previous_answer_space_fill = false
    else
      out:insert(block)
      ctx.previous_answer_space_fill = false
    end
  end
  return out
end

local function validate_removed_syntax(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Div" then
      reject_removed_div_syntax(block)
      validate_removed_syntax(block.content)
    end
  end
end

local function is_question_block(block)
  return block.t == "Div" and has_class(block, "question")
end

local function collect_questions(blocks)
  local questions = {}
  local regular_total = 0
  local regular_number = 0
  local bonus_number = 0
  for _, block in ipairs(blocks) do
    if is_question_block(block) then
      local points = question_points(block)
      local bonus = is_true(block.attributes.bonus)
      local number
      if bonus then
        bonus_number = bonus_number + 1
        number = "B" .. tostring(bonus_number)
      else
        regular_number = regular_number + 1
        number = tostring(regular_number)
      end
      local item = {
        number = number,
        points = points,
        bonus = bonus
      }
      table.insert(questions, item)
      if not bonus then
        regular_total = regular_total + points
      end
    end
  end
  return questions, regular_total
end

local function cover(doc, questions, regular_total)
  if is_exercise then
    local logo = meta_string(doc.meta, "title-logo", "")
    local logo_block = "#block(width: 100%, height: 34mm)[]"
    if logo ~= "" then
      logo_block = table.concat({
        "#block(width: 100%, height: 34mm)[",
        "  #align(left + top)[#image(\"" .. logo .. "\", width: 70%)]",
        "]"
      }, "\n")
    end

    local subtitle = ""
    if chapter_order ~= "" then
      subtitle = "Chapitre " .. chapter_order
      if document_title ~= "" then
        subtitle = subtitle .. " : " .. document_title
      end
    elseif document_title ~= "" then
      subtitle = document_title
    else
      subtitle = meta_string(doc.meta, "exam-title", "")
    end
    local subtitle_block = ""
    if subtitle ~= "" then
      subtitle_block = "#exam-workbook-cover-subtitle(\"" .. typst_escape(subtitle) .. "\")"
    end

    local blocks = pandoc.List:new({
      raw_block(table.concat({
        logo_block,
        "#v(8mm)",
        "#exam-workbook-cover-title()",
        subtitle_block,
        "#v(10mm)",
        "#align(center)[",
        "  #table(",
        "    columns: (72mm, 45mm),",
        "    stroke: none,",
        "    fill: none,",
        "    inset: 0pt,",
        "    row-gutter: 4mm,",
        "    [#strong[Cours]\\ " .. typst_escape(meta_string(doc.meta, "course-number", "")) .. "],",
        "    [#strong[Enseignant]\\ " .. typst_escape(meta_string(doc.meta, "instructor", "")) .. "],",
        "  )",
        "]",
        "#v(8mm)",
        "#align(center)[#strong[Instructions]]",
        "#align(center)[",
        "  #block(width: 126mm)[",
        "    #set align(left)"
      }, "\n"))
    })

    local instructions_file = meta_string(doc.meta, "instructions-file", "instructions.qmd")
    blocks:extend(pandoc.read(read_file(instructions_file), reader).blocks)
    if instructions_only then
      blocks:insert(raw_block("  ]\n]"))
    else
      blocks:insert(raw_block("  ]\n]\n#pagebreak(weak: false)"))
    end
    return blocks
  end

  local question_cells = {}
  local point_cells = {}
  local columns = { "auto" }
  for _, question in ipairs(questions) do
    local label = tostring(question.number)
    local points = tostring(question.points)
    if question.bonus then
      points = "+" .. points
    end
    table.insert(question_cells, "[#align(center)[" .. typst_escape(label) .. "]]")
    table.insert(point_cells, "[#align(center)[" .. typst_escape(points) .. "]]")
    table.insert(columns, "12mm")
  end
  table.insert(columns, "auto")

  local title_kind = is_homework and "Travail" or "Examen"
  local date_label = "Durée"
  local date_value = meta_string(doc.meta, "duration", "")
  if is_homework and meta_string(doc.meta, "due-date", "") ~= "" then
    date_label = "Date de remise"
    date_value = meta_string(doc.meta, "due-date", "")
    local due_time = meta_string(doc.meta, "homework-due-time", "")
    if due_time ~= "" then
      date_value = date_value .. " " .. due_time
    end
  end

  local label = is_homework and "TRAVAIL PRATIQUE" or "QUESTIONNAIRE"
  if teacher then
    label = "CORRIGÉ"
  elseif instructions_only then
    label = "INSTRUCTIONS"
  end
  local logo = meta_string(doc.meta, "title-logo", "")
  local logo_block = "#block(width: 100%, height: 34mm)[]"
  if logo ~= "" then
    logo_block = table.concat({
      "#block(width: 100%, height: 34mm)[",
      "  #align(left + top)[#image(\"" .. logo .. "\", width: 70%)]",
      "]"
    }, "\n")
  end
  local student_identity = ""
  if not teacher and not instructions_only and not is_homework then
    student_identity = table.concat({
      "#v(6mm)",
      "#align(center)[",
      "  #block(width: 115mm)[",
      "    #grid(columns: (auto, 1fr), column-gutter: 5mm, row-gutter: 4mm,",
      "      [#block(height: 7mm)[#align(horizon)[#strong[Nom]]]], [#box(width: 92mm, height: 7mm, stroke: 0.4pt)[]],",
      "      [#block(height: 7mm)[#align(horizon)[#strong[NI]]]], [#box(width: 92mm, height: 7mm, stroke: 0.4pt)[]],",
      "    )",
      "  ]",
      "]"
    }, "\n")
  end

  local blocks = pandoc.List:new({
    raw_block(table.concat({
      logo_block,
      "#v(8mm)",
      "#align(center)[",
      "  #table(",
      "    columns: (72mm, 45mm),",
      "    stroke: none,",
      "    row-gutter: 4mm,",
      "    [#strong[Cours]\\ " .. typst_escape(meta_string(doc.meta, "course-number", "")) .. "],",
      "    [#strong[" .. title_kind .. "]\\ " .. typst_escape(meta_string(doc.meta, "exam-title", "")) .. "],",
      "    [#strong[Enseignant]\\ " .. typst_escape(meta_string(doc.meta, "instructor", "")) .. "],",
      "    [#strong[" .. date_label .. "]\\ " .. typst_escape(date_value) .. "],",
      "  )",
      "]",
      "#v(6mm)",
      "#align(center)[#box(stroke: 0.6pt, inset: 5pt)[#strong[" .. label .. "]]]",
      student_identity,
      "#v(6mm)",
      "#align(center)[#strong[Instructions]]",
      "#align(center)[",
      "  #block(width: 126mm)[",
      "    #set align(left)",
    }, "\n"))
  })

  local instructions_file = meta_string(doc.meta, "instructions-file", "instructions.qmd")
  blocks:extend(pandoc.read(read_file(instructions_file), reader).blocks)

  if instructions_only then
    blocks:insert(raw_block("  ]\n]"))
    return blocks
  end

  if is_homework then
    blocks:insert(raw_block(table.concat({
      "  ]",
      "]",
      "#pagebreak(weak: false)"
    }, "\n")))
    return blocks
  end

  local total_cells = "[#align(center)[#strong[" .. tostring(regular_total) .. "]]]"
  blocks:insert(raw_block(table.concat({
    "  ]",
    "]",
    "#v(8mm)",
    "#align(center)[",
    "  #table(",
    "    columns: (" .. table.concat(columns, ", ") .. "),",
    "    stroke: 0.4pt,",
    "    inset: 3.5pt,",
    "    [#align(center)[#strong[Question]]], " .. table.concat(question_cells, ", ") .. ", [#align(center)[#strong[Total]]],",
    "    [#align(center)[#strong[Points]]], " .. table.concat(point_cells, ", ") .. ", " .. total_cells .. ",",
    "  )",
    "]",
    "#pagebreak(weak: false)"
  }, "\n")))

  return blocks
end

local function transform_exam_body(blocks, questions)
  local out = pandoc.List:new()
  local question_index = 0

  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 2 then
      out:insert(raw_block("#exam-section(\"" .. typst_escape(stringify(block.content)) .. "\")"))
    elseif is_question_block(block) then
      question_index = question_index + 1
      local q = questions[question_index]
      local ctx = { question_depth = 0, question_counters = {}, inside_question = true }
      local transformed = transform_question_like_content(block, ctx)
      prepend_question_label(transformed, q.number, question_points_label(block), q.bonus)
      out:extend(transformed)
    elseif block.t == "Div" then
      out:extend(transform_div(block, { question_depth = 0, question_counters = {} }))
    else
      out:insert(block)
    end
  end

  return out
end

function Pandoc(doc)
  document_type = meta_string(doc.meta, "document-type", "exam")
  if document_type ~= "exam" and document_type ~= "homework" and document_type ~= "exercice" then
    fail("La metadonnee `document-type` doit etre `exam`, `homework` ou `exercice`.")
  end
  is_homework = document_type == "homework"
  is_exercise = document_type == "exercice"
  show_solutions = is_exercise and meta_boolean(doc.meta, "show-solutions", false)
  show_grading = is_exercise and meta_boolean(doc.meta, "show-grading", false)
  document_title = meta_string(doc.meta, "title", "")
  chapter_order = meta_string(doc.meta, "order", "")
  chapter_label = meta_string(doc.meta, "label", "")
  document_pagetitle = meta_string(doc.meta, "pagetitle", "")
  if is_exercise and chapter_order ~= "" and chapter_label ~= "" then
    document_pagetitle = chapter_order .. ". " .. chapter_label .. " - Exercices"
  end
  if document_pagetitle == "" then
    document_pagetitle = document_title
  end

  if is_exercise then
    -- The workbook provides its own cover; suppress Quarto's otherwise empty title page.
    doc.meta.title = nil
  end

  if is_homework and instructions_only then
    fail("Rendre un travail pratique en mode `instructions` n'est pas utile. Utilisez `questionnaire` ou `corrige`.")
  end

  resolve_assessment_dates(doc, document_type)

  if doc.meta.questions ~= nil then
    fail("Configuration de questions invalide: ajoutez les questions avec des inclusions Quarto dans `index.qmd`, par exemple `{{< include questions/q01.qmd >}}`.")
  end

  validate_removed_syntax(doc.blocks)

  local questions, regular_total = collect_questions(doc.blocks)

  if #questions == 0 then
    warn("Aucun bloc `.question` trouve.")
  end

  local blocks = pandoc.List:new()
  blocks:insert(typst_setup(doc))
  blocks:extend(cover(doc, questions, regular_total))
  if not instructions_only then
    blocks:extend(transform_exam_body(doc.blocks, questions))
  end
  doc.blocks = blocks

  return doc
end
