-- Record opt-in role headers before Quarto's table/caption processing. A
-- `tbl-*` Div has already become a FloatRefTarget at Quarto's pre-filter
-- entry point, so record a stable header signature in document metadata
-- instead of relying on attributes that Quarto may consume.

local metadata_key = "smart-tables-header-role-signatures"
local role_signatures = {}

local function normalized_roles(attr)
  local attrs = (attr and attr.attributes) or {}
  local value = tostring(attrs["smart-tables-header-roles"] or "")
  value = value:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s*,%s*", ",")
  if value == "labels,calculations" then
    return value
  end
  return nil
end

local function header_signature(tbl)
  local parts = { tostring(#(tbl.head.rows or {})), tostring(#(tbl.colspecs or {})) }
  for _, row in ipairs(tbl.head.rows or {}) do
    table.insert(parts, tostring(#(row.cells or {})))
    for _, cell in ipairs(row.cells or {}) do
      local text = pandoc.utils.stringify(cell.contents or {})
      table.insert(parts, tostring(#text) .. ":" .. text)
    end
  end
  return table.concat(parts, "|")
end

local function direct_table(float)
  if float.content and float.content.t == "Table" then
    return float.content
  end
  for _, block in ipairs(float.content or {}) do
    if block.t == "Table" then
      return block
    end
  end
  return nil
end

return {
  {
    FloatRefTarget = function(float)
      local attr = pandoc.Attr(
        float.identifier or "",
        float.classes or {},
        float.attributes or {}
      )
      if normalized_roles(attr) then
        local tbl = direct_table(float)
        if tbl then
          table.insert(role_signatures, header_signature(tbl))
        end
      end
      return nil
    end,
    Div = function(div)
      if normalized_roles(div.attr) then
        for _, block in ipairs(div.content or {}) do
          if block.t == "Table" then
            table.insert(role_signatures, header_signature(block))
            break
          end
        end
      end
      return nil
    end,
    Table = function(tbl)
      if normalized_roles(tbl.attr) then
        table.insert(role_signatures, header_signature(tbl))
      end
      return nil
    end,
  },
  {
    Pandoc = function(doc)
      if #role_signatures > 0 then
        local entries = {}
        for _, signature in ipairs(role_signatures) do
          table.insert(entries, pandoc.MetaString(signature))
        end
        doc.meta[metadata_key] = pandoc.MetaList(entries)
      end
      return doc
    end,
  },
}
