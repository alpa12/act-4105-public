local metrics = require("text_metrics")
local table_ast = require("table_ast")

local M = {}

local function escape(text)
  text = tostring(text or "")
  text = text:gsub("\\", "\\\\")
  text = text:gsub("#", "\\#")
  text = text:gsub("%$", "\\$")
  text = text:gsub("%[", "\\[")
  text = text:gsub("%]", "\\]")
  return text
end

local function align(value)
  if value == "right" then
    return "right"
  end
  if value == "center" then
    return "center"
  end
  return "left"
end

local function caption_text(caption)
  if caption == nil or caption.long == nil or #caption.long == 0 then
    return nil
  end
  return pandoc.utils.stringify(caption.long)
end

local function identifier(attr)
  if attr and attr.identifier and attr.identifier ~= "" then
    return attr.identifier
  end
  return nil
end

local function cell(line)
  return "    " .. line
end

local function typst_align(value)
  if value == "left" then
    return "left"
  end
  if value == "right" then
    return "right"
  end
  return "center"
end

local function text_size_arg(value)
  if value == nil or value == "" or value == "auto" then
    return ""
  end
  return ", text-size: " .. value
end

local function cell_text(text, kind)
  if kind == "numeric" or kind == "currency" or kind == "percentage" then
    return metrics.keep_digit_group_spaces(text)
  end
  return text
end

local function header_text(text, lines, wrap)
  if not wrap then
    return escape(text)
  end
  local escaped_lines = {}
  for _, line in ipairs(lines or {}) do
    table.insert(escaped_lines, (escape(line):gsub(" ", "~"):gsub("%-", "‑")))
  end
  return table.concat(escaped_lines, "#linebreak()")
end

local function grouped_header_items(model, plan, p)
  local geometry = model.header_geometry
  local items = {}
  table.insert(items, "table.header(")
  table.insert(items, "  repeat: " .. tostring(plan.repeat_header) .. ",")
  for row_index, row in ipairs(geometry.rows) do
    for _, logical in ipairs(row) do
      local source = logical.cell
      local col_span, row_span = source.col_span or 1, source.row_span or 1
      local grouped = col_span ~= 1 or row_span ~= 1
      local args = {
        "align: " .. (grouped and "center" or align((plan.header_align and plan.header_align[logical.column]) or plan.col_align[logical.column])),
        "fill: " .. p .. ".grouped-header-fill",
      }
      if col_span > 1 then table.insert(args, "colspan: " .. tostring(col_span)) end
      if row_span > 1 then table.insert(args, "rowspan: " .. tostring(row_span)) end
      table.insert(items, string.format(
        "  table.cell(%s)[#strong[%s]],",
        table.concat(args, ", "),
        header_text(source.text, plan.header_lines[logical.column], not grouped)
      ))
    end
  end
  table.insert(items, "),")
  for _, line in ipairs(geometry.vlines or {}) do
    table.insert(items, string.format(
      "table.vline(x: %d, start: %d, end: %d, stroke: %s.group-boundary-stroke),",
      line.x, line.start_row, line.end_row, p
    ))
  end
  return items
end

-- A roles header is still a single Typst `table.header`, but its last two
-- physical rows have separate responsibilities.  Labels receive the shared
-- layout plan; calculation references are emitted from their source text
-- without line balancing or substitution.
local function roles_header_items(model, plan, p)
  local geometry = model.header_geometry
  local items = {}
  local grouped_fill = geometry.has_grouped_headers and ".grouped-header-fill" or ".header-fill"
  table.insert(items, "table.header(")
  table.insert(items, "  repeat: " .. tostring(plan.repeat_header) .. ",")

  for row_index, row in ipairs(geometry.rows) do
    local row_role = table_ast.header_row_role(model, row_index)
    for _, logical in ipairs(row) do
      local source = logical.cell
      local col_span, row_span = source.col_span or 1, source.row_span or 1
      local grouped = col_span ~= 1 or row_span ~= 1
      local args = {
        "align: " .. (grouped and "center" or align((plan.header_align and plan.header_align[logical.column]) or plan.col_align[logical.column])),
        "fill: " .. p .. grouped_fill,
      }
      if col_span > 1 then table.insert(args, "colspan: " .. tostring(col_span)) end
      if row_span > 1 then table.insert(args, "rowspan: " .. tostring(row_span)) end

      local content
      if row_role == "calculations" then
        -- Keep the same header emphasis as ordinary tables while leaving the
        -- calculation text itself unwrapped and otherwise untouched.
        content = "#strong[" .. escape(source.text) .. "]"
      elseif row_role == "labels" then
        content = "#strong[" .. header_text(source.text, plan.header_lines[logical.column], true) .. "]"
      else
        -- Rows before the two declared roles remain grouped headers and keep
        -- their original text rather than borrowing a column-label wrap.
        content = "#strong[" .. header_text(source.text, nil, false) .. "]"
      end
      table.insert(items, string.format(
        "  table.cell(%s)[%s],",
        table.concat(args, ", "),
        content
      ))
    end
  end
  table.insert(items, "),")
  for _, line in ipairs(geometry.vlines or {}) do
    table.insert(items, string.format(
      "table.vline(x: %d, start: %d, end: %d, stroke: %s.group-boundary-stroke),",
      line.x, line.start_row, line.end_row, p
    ))
  end
  return items
end

function M.render(model, plan, options)
  local p = "smart-table-profile(\"" .. escape(plan.profile) .. "\")"
  local scope_args = "profile: \"" .. escape(plan.profile) .. "\"" .. text_size_arg(plan.text_size)
  local items = {}

  if model.header_roles then
    items = roles_header_items(model, plan, p)
  elseif model.header_geometry and model.header_geometry.has_grouped_headers then
    items = grouped_header_items(model, plan, p)
  else
    table.insert(items, "table.header(")
    table.insert(items, "  repeat: " .. tostring(plan.repeat_header) .. ",")
    for col = 1, model.n_cols do
      local comma = col == model.n_cols and "" or ","
      table.insert(items, string.format(
        "  table.cell(align: %s, fill: %s.header-fill)[#strong[%s]]%s",
        align((plan.header_align and plan.header_align[col]) or plan.col_align[col]),
        p,
        header_text("", plan.header_lines[col], true),
        comma
      ))
    end
    table.insert(items, "),")
  end
  table.insert(items, "table.hline(stroke: " .. p .. ".header-stroke),")

  for row_index, row in ipairs(model.body_rows) do
    for col = 1, model.n_cols do
      local source = row.cells[col]
      local fill = ""
      if plan.stripe and row_index % 2 == 0 then
        fill = ", fill: " .. p .. ".stripe-fill"
      end
      local comma = ","
      table.insert(items, string.format(
        "table.cell(align: %s%s)[%s]%s",
        align(plan.col_align[col]),
        fill,
        escape(cell_text(source and source.text or "", plan.types[col] and plan.types[col].type)),
        comma
      ))
    end
    if plan.row_rules and row_index < #model.body_rows then
      table.insert(items, "table.hline(stroke: " .. p .. ".row-stroke),")
    end
  end

  local table_expression = table.concat({
    "#table(",
    "    columns: (" .. table.concat(plan.columns, ", ") .. (model.n_cols == 1 and "," or "") .. "),",
    "    column-gutter: " .. p .. ".gutter,",
    "    stroke: none,",
    "    inset: (x: " .. p .. ".inset-x, y: " .. p .. ".inset-y),",
    cell(table.concat(items, "\n    ")),
    "  )"
  }, "\n")

  if plan.table_width == "full" then
    table_expression = table.concat({
      "#block(width: 100%)[",
      "  " .. table_expression:gsub("\n", "\n  "),
      "]"
    }, "\n")
  end

  local table_code = table.concat({
    "smart-table-scope(" .. scope_args .. ")[",
    "  " .. table_expression:gsub("\n", "\n  "),
    "]"
  }, "\n")

  local cap = caption_text(model.caption)
  local id = identifier(model.attr)
  local wrapped_table = "#" .. table_code
  if plan.align and plan.align ~= "none" then
    wrapped_table = "#align(" .. typst_align(plan.align) .. ")[\n  " .. wrapped_table:gsub("\n", "\n  ") .. "\n]"
  end

  if cap then
    local label = id and (" <" .. id .. ">") or ""
    return table.concat({
      "#align(" .. typst_align(plan.align) .. ")[",
      "  #figure(",
      "    " .. table_code:gsub("\n", "\n    "),
      "    ,",
      "    kind: table,",
      "    caption: [" .. escape(cap) .. "]",
      "  )" .. label,
      "]"
    }, "\n")
  end

  return wrapped_table
end

M.escape = escape

return M
