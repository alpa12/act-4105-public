local metrics = require("text_metrics")

local M = {}

-- `smart-tables-header-roles="labels,calculations"` reserves the final two
-- *physical* Pandoc header rows for the column labels and their calculation
-- references.  Keep this opt-in deliberately narrow: unknown values retain
-- the ordinary, lowest-header-row behaviour.
function M.set_header_roles(model)
  local attrs = (model.attr and model.attr.attributes) or {}
  local value = tostring(attrs["smart-tables-header-roles"] or "")
  value = value:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s*,%s*", ",")

  if value == "labels,calculations" and #(model.header_rows or {}) >= 2 then
    local final_row = #model.header_rows
    model.header_roles = {
      labels = final_row - 1,
      calculations = final_row,
    }
    -- The Markdown reader represents a leading `(1)` in a grid-table cell
    -- as an ordered list. Rehydrate it only after this explicit opt-in, so
    -- ordinary tables retain their existing cell text exactly.
    for _, cell in ipairs(model.header_rows[final_row].cells or {}) do
      local calculation = M.calculation_text(cell)
      if calculation then
        cell.text = calculation
      end
    end
  else
    model.header_roles = nil
  end
  return model.header_roles
end

function M.header_row_role(model, row_index)
  local roles = model.header_roles
  if roles and row_index == roles.labels then
    return "labels"
  end
  if roles and row_index == roles.calculations then
    return "calculations"
  end
  return nil
end

-- In a grid-table cell Pandoc parses a leading `(1)` as an empty ordered-list
-- marker.  Calculation rows use that notation deliberately, so recover the
-- author-facing text before it reaches the layout engine or a renderer.  This
-- does not accept arbitrary lists: exactly one parenthesized list item is the
-- syntax produced by the Markdown reader for these references.
local function calculation_list_text(blocks)
  if blocks == nil or #blocks ~= 1 then
    return nil
  end
  local block = blocks[1]
  if block.t ~= "OrderedList" then
    return nil
  end
  local attributes = block.list_attributes or {}
  local start = attributes.start or attributes[1] or block.start
  local delimiter = tostring(attributes.delimiter or attributes[3] or block.delimiter or "")
  local items = block.content or {}
  if not start or #items ~= 1 or not delimiter:match("TwoParens") then
    return nil
  end

  local suffix = metrics.stringify_blocks(items[1])
  suffix = suffix:gsub("^%s+", ""):gsub("%s+$", "")
  local marker = "(" .. tostring(start) .. ")"
  if suffix == "" then
    return marker
  end
  if suffix:match("^[,;:%.%)%]%}]") then
    return marker .. suffix
  end
  return marker .. " " .. suffix
end

function M.calculation_text(cell)
  return calculation_list_text(cell and cell.contents)
end

local function cell_text(cell)
  return metrics.stringify_blocks(cell.contents)
end

local function rows_from_section(section)
  local rows = {}
  if section == nil or section.rows == nil then
    return rows
  end
  for _, row in ipairs(section.rows) do
    local cells = {}
    for _, cell in ipairs(row.cells) do
      table.insert(cells, {
        text = cell_text(cell),
        contents = cell.contents,
        align = tostring(cell.alignment or ""),
        col_span = cell.col_span or 1,
        row_span = cell.row_span or 1,
        attr = cell.attr,
      })
    end
    table.insert(rows, { cells = cells })
  end
  return rows
end

local function body_rows(tbl)
  local rows = {}
  for _, body in ipairs(tbl.bodies or {}) do
    for _, row in ipairs(body.body or {}) do
      local cells = {}
      for _, cell in ipairs(row.cells) do
        table.insert(cells, {
          text = cell_text(cell),
          contents = cell.contents,
          align = tostring(cell.alignment or ""),
          col_span = cell.col_span or 1,
          row_span = cell.row_span or 1,
          attr = cell.attr,
        })
      end
      table.insert(rows, { cells = cells })
    end
  end
  return rows
end

local function has_unsupported_blocks(cell, allow_calculation_syntax)
  if allow_calculation_syntax and M.calculation_text(cell) then
    return false
  end
  if cell.contents == nil then
    return false
  end
  if #cell.contents > 1 then
    return true
  end
  for _, block in ipairs(cell.contents) do
    if block.t ~= "Plain" and block.t ~= "Para" then
      return true
    end
    for _, inline in ipairs(block.content or {}) do
      if inline.t ~= "Str" and inline.t ~= "Space" and inline.t ~= "SoftBreak" and inline.t ~= "LineBreak" then
        return true
      end
    end
  end
  return false
end

function M.from_pandoc_table(tbl)
  local colspecs = {}
  for _, spec in ipairs(tbl.colspecs or {}) do
    local width = spec[2] or 0
    table.insert(colspecs, {
      align = tostring(spec[1]),
      width = width,
    })
  end

  local model = {
    attr = tbl.attr,
    caption = tbl.caption,
    colspecs = colspecs,
    header_rows = rows_from_section(tbl.head),
    body_rows = body_rows(tbl),
    footer_rows = rows_from_section(tbl.foot),
    n_cols = #colspecs,
    features = {
      has_spans = false,
      has_header_spans = false,
      has_body_spans = false,
      has_footer_spans = false,
      has_complex_content = false,
      has_explicit_widths = false,
      has_pandoc_widths = false,
    },
  }

  M.set_header_roles(model)

  if tbl.attr and tbl.attr.attributes then
    if tbl.attr.attributes["tbl-colwidths"] or tbl.attr.attributes.widths then
      model.features.has_explicit_widths = true
    end
  end
  for _, spec in ipairs(model.colspecs) do
    if tonumber(spec.width) and tonumber(spec.width) ~= 0 then
      model.features.has_pandoc_widths = true
    end
  end

  for section_index, section in ipairs({ model.header_rows, model.body_rows, model.footer_rows }) do
    for row_index, row in ipairs(section) do
      for _, cell in ipairs(row.cells) do
        if cell.col_span ~= 1 or cell.row_span ~= 1 then
          model.features.has_spans = true
          if section_index == 1 then
            model.features.has_header_spans = true
          elseif section_index == 2 then
            model.features.has_body_spans = true
          else
            model.features.has_footer_spans = true
          end
        end
        local is_calculation = section_index == 1
          and M.header_row_role(model, row_index) == "calculations"
        if has_unsupported_blocks(cell, is_calculation) then
          model.features.has_complex_content = true
        end
      end
    end
  end

  model.header_geometry = M.header_geometry(model)

  -- A direct table already has its attributes at this point. A containing
  -- Div can add header roles later in the orchestration layer, which then
  -- calls this same refresh after merging its attributes.
  M.refresh_complex_content(model)

  return model
end

function M.refresh_complex_content(model)
  model.features.has_complex_content = false
  for section_index, section in ipairs({ model.header_rows, model.body_rows, model.footer_rows }) do
    for row_index, row in ipairs(section) do
      for _, cell in ipairs(row.cells) do
        local is_calculation = section_index == 1
          and M.header_row_role(model, row_index) == "calculations"
        if has_unsupported_blocks(cell, is_calculation) then
          model.features.has_complex_content = true
          return true
        end
      end
    end
  end
  return false
end

function M.header_texts(model)
  local headers = {}
  for i = 1, model.n_cols do
    headers[i] = ""
  end

  -- When roles are declared, only the labels row is evidence for layout and
  -- type inference.  In particular, a calculation such as `(3) = (1) + (2)`
  -- must never turn an otherwise numeric column into a formula column.
  local roles = model.header_roles
  if roles and model.header_geometry and model.header_geometry.rows[roles.labels] then
    for _, logical in ipairs(model.header_geometry.rows[roles.labels]) do
      local span = logical.cell.col_span or 1
      for col = logical.column, logical.column + span - 1 do
        headers[col] = logical.cell.text
      end
    end
    return headers
  end

  local best = {}
  for row_index, row in ipairs(M.logical_rows(model.header_rows)) do
    for _, logical in ipairs(row) do
      local span = logical.cell.col_span or 1
      for col = logical.column, logical.column + span - 1 do
        -- The lowest physical header is the column label.  On a tie, the
        -- narrowest span is the most specific label.
        local previous = best[col]
        if not previous or row_index > previous.row
          or (row_index == previous.row and span < previous.span) then
          best[col] = { row = row_index, span = span, text = logical.cell.text }
        end
      end
    end
  end
  for col, value in pairs(best) do
    headers[col] = value.text
  end
  return headers
end

-- Pandoc stores physical cells only. Resolve their logical column positions so
-- HTML styling remains correct when rows contain rowspan or colspan cells.
function M.logical_rows(rows)
  local out, occupied = {}, {}
  for _, row in ipairs(rows or {}) do
    local cells, column = {}, 1
    for _, cell in ipairs(row.cells or {}) do
      while occupied[column] and occupied[column] > 0 do
        column = column + 1
      end
      table.insert(cells, { cell = cell, column = column })
      local col_span, row_span = cell.col_span or 1, cell.row_span or 1
      if row_span > 1 then
        for offset = 0, col_span - 1 do
          occupied[column + offset] = math.max(occupied[column + offset] or 0, row_span)
        end
      end
      column = column + col_span
    end
    table.insert(out, cells)
    for key, remaining in pairs(occupied) do
      occupied[key] = remaining - 1
      if occupied[key] <= 0 then
        occupied[key] = nil
      end
    end
  end
  return out
end

-- Build the header grid once so both renderers reason about physical Pandoc
-- cells rather than guessing from HTML positions.  `roles` marks the cells
-- that continue a grouped header's left or right edge on every relevant row;
-- `vlines` is the same geometry as de-duplicated Typst line segments.
function M.header_geometry(model)
  local logical_rows = M.logical_rows(model.header_rows)
  local geometry = {
    rows = logical_rows,
    groups = {},
    roles = {},
    vlines = {},
    has_grouped_headers = false,
  }
  local physical = {}
  local n_rows = #logical_rows

  for row_index, row in ipairs(logical_rows) do
    geometry.roles[row_index] = {}
    for cell_index, logical in ipairs(row) do
      local cell = logical.cell
      local col_span = cell.col_span or 1
      local row_span = cell.row_span or 1
      local entry = {
        row = row_index,
        cell_index = cell_index,
        cell = cell,
        column = logical.column,
        end_column = logical.column + col_span - 1,
        end_row = math.min(n_rows, row_index + row_span - 1),
        col_span = col_span,
        row_span = row_span,
      }
      table.insert(physical, entry)
      geometry.roles[row_index][cell_index] = { start = false, finish = false }
      if col_span ~= 1 or row_span ~= 1 then
        geometry.has_grouped_headers = true
        table.insert(geometry.groups, entry)
      end
    end
  end

  local segments = {}
  local function add_segment(x, start_row, end_row)
    segments[x] = segments[x] or {}
    table.insert(segments[x], { start_row = start_row, end_row = end_row })
  end

  for _, group in ipairs(geometry.groups) do
    local last_row = group.end_row
    if group.col_span > 1 then
      -- A colspan group owns all of its descendants.  Continue its boundaries
      -- through the deepest physical cells wholly inside its column interval.
      for _, candidate in ipairs(physical) do
        if candidate.row >= group.row
          and candidate.column >= group.column
          and candidate.end_column <= group.end_column then
          last_row = math.max(last_row, candidate.end_row)
        end
      end
    end

    for _, candidate in ipairs(physical) do
      if candidate.row >= group.row and candidate.row <= last_row then
        local role = geometry.roles[candidate.row][candidate.cell_index]
        if candidate.column == group.column then
          role.start = true
        end
        if candidate.end_column == group.end_column then
          role.finish = true
        end
      end
    end

    -- Typst positions vlines between zero-indexed tracks; the end is
    -- exclusive in rows and therefore equals the final one-indexed row.
    add_segment(group.column - 1, group.row - 1, last_row)
    add_segment(group.end_column, group.row - 1, last_row)
  end

  for x, ranges in pairs(segments) do
    table.sort(ranges, function(a, b) return a.start_row < b.start_row end)
    local merged = nil
    for _, range in ipairs(ranges) do
      if not merged or range.start_row > merged.end_row then
        if merged then table.insert(geometry.vlines, { x = x, start_row = merged.start_row, end_row = merged.end_row }) end
        merged = { start_row = range.start_row, end_row = range.end_row }
      else
        merged.end_row = math.max(merged.end_row, range.end_row)
      end
    end
    if merged then table.insert(geometry.vlines, { x = x, start_row = merged.start_row, end_row = merged.end_row }) end
  end
  table.sort(geometry.vlines, function(a, b)
    if a.x == b.x then return a.start_row < b.start_row end
    return a.x < b.x
  end)

  return geometry
end

function M.column_values(model, col)
  local values = {}
  for _, row in ipairs(M.logical_rows(model.body_rows)) do
    for _, logical in ipairs(row) do
      if logical.column == col then
        table.insert(values, logical.cell.text)
      end
    end
  end
  return values
end

function M.is_eligible(model, options, target)
  if model.n_cols == 0 then
    return false, "no columns"
  end
  if target == "html" then
    -- Browser table layout supports rich blocks, spans, explicit widths, and
    -- wide tables, so Typst's safety restrictions do not apply here.
    return true
  end
  if model.n_cols > 14 then
    return false, "too many columns"
  end
  if model.features.has_body_spans or model.features.has_footer_spans then
    return false, "body or footer spans are not supported yet"
  end
  if model.features.has_complex_content then
    return false, "complex cell content is not supported yet"
  end
  -- Grid tables receive non-zero Pandoc colspecs from the reader even when
  -- their widths were never authored. Header roles explicitly request a new
  -- labels-driven layout, so do not let those synthetic colspecs suppress the
  -- Typst renderer. Deliberate `tbl-colwidths`/`widths` attributes still win.
  if (model.features.has_explicit_widths
      or (model.features.has_pandoc_widths and not model.header_roles))
    and options.explicit_widths ~= "optimize" then
    return false, "explicit source widths respected"
  end
  return true
end

return M
