local stringify = pandoc.utils.stringify

local function to_text(value)
  if type(value) == "string" then
    return value
  end

  return stringify(value)
end

local function fail(message)
  io.stderr:write("\27[31;1mERROR:\27[0m " .. message .. "\n")
  os.exit(1)
end

local function meta_integer(meta, name)
  local value = meta[name]
  if value == nil then
    return nil
  end

  local number = tonumber(to_text(value))
  if number == nil or math.floor(number) ~= number then
    fail("La metadonnee `" .. name .. "` doit etre un entier.")
  end

  return number
end

local function read_integer_arg(args, index, default, shortcode)
  local raw_value = quarto.shortcode.read_arg(args, index)
  if raw_value == nil then
    return default
  end

  local value = tonumber(to_text(raw_value))
  if value == nil or math.floor(value) ~= value then
    fail("Le shortcode `{{< " .. shortcode .. " >}}` exige un decalage entier.")
  end

  return value
end

local function base_year(meta)
  local value = meta_integer(meta, "base-year")
  if value == nil then
    fail("Les shortcodes `dynamic-year` et `dynamic-date` exigent la metadonnee `base-year` dans `_quarto.yml` ou dans le document.")
  end

  return value
end

local function is_leap_year(year)
  return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function days_in_month(year, month)
  if month == 2 then
    return is_leap_year(year) and 29 or 28
  end

  if month == 4 or month == 6 or month == 9 or month == 11 then
    return 30
  end

  return 31
end

local function next_month_start(year, month)
  if month == 12 then
    return year + 1, 1, 1
  end

  return year, month + 1, 1
end

local function format_date(year, month, day)
  return string.format("%04d-%02d-%02d", year, month, day)
end

local function invalid_mode(kwargs, raw_args)
  local raw_mode = nil
  if kwargs ~= nil then
    raw_mode = kwargs["invalid"]
  end
  local mode = raw_mode ~= nil and to_text(raw_mode) or "error"
  if (mode == "" or mode == "error") and raw_args ~= nil then
    local raw_text = to_text(raw_args)
    mode = raw_text:match("invalid%s*=%s*[\"']([^\"']+)[\"']") or raw_text:match("invalid%s*=%s*([^%s]+)") or mode
  end
  if mode == "" then
    mode = "error"
  end
  mode = mode:gsub("^['\"]", ""):gsub("['\"]$", "")
  if mode:match("previous%-month%-end") then
    mode = "previous-month-end"
  elseif mode:match("next%-month%-start") then
    mode = "next-month-start"
  elseif mode:match("^error") then
    mode = "error"
  end
  if mode ~= "error" and mode ~= "previous-month-end" and mode ~= "next-month-start" then
    fail("Le parametre `invalid` doit valoir `error`, `previous-month-end` ou `next-month-start`.")
  end

  return mode
end

local function dynamic_date(template, year, mode)
  local month_text, day_text = template:match("^YYYY%-(%d%d)%-(%d%d)$")
  if month_text == nil then
    fail("Le shortcode `{{< dynamic-date >}}` exige une date sous la forme `YYYY-MM-DD`, par exemple `YYYY-10-15`.")
  end

  local month = tonumber(month_text)
  local day = tonumber(day_text)
  if month < 1 or month > 12 then
    fail("Le shortcode `{{< dynamic-date >}}` contient un mois invalide.")
  end

  local max_day = days_in_month(year, month)
  if day >= 1 and day <= max_day then
    return format_date(year, month, day)
  end

  if day < 1 then
    fail("Le shortcode `{{< dynamic-date >}}` contient un jour invalide.")
  end

  if mode == "previous-month-end" then
    return format_date(year, month, max_day)
  end

  if mode == "next-month-start" then
    local next_year, next_month, next_day = next_month_start(year, month)
    return format_date(next_year, next_month, next_day)
  end

  fail("La date `" .. format_date(year, month, day) .. "` est invalide. Utilisez `invalid=\"previous-month-end\"` ou `invalid=\"next-month-start\"` pour la corriger automatiquement.")
end

return {
  ["dynamic-year"] = function(args, _kwargs, meta, _raw_args, _context)
    local offset = read_integer_arg(args, 1, 0, "dynamic-year x")
    return pandoc.Str(tostring(base_year(meta) + offset))
  end,
  ["dynamic-date"] = function(args, kwargs, meta, raw_args, _context)
    local raw_template = quarto.shortcode.read_arg(args, 1)
    if raw_template == nil then
      fail("Le shortcode `{{< dynamic-date >}}` exige une date sous la forme `YYYY-MM-DD`, par exemple `YYYY-10-15`.")
    end

    local offset = read_integer_arg(args, 2, 0, "dynamic-date \"YYYY-MM-DD\" x")
    local year = base_year(meta) + offset
    local mode = invalid_mode(kwargs, raw_args)

    return pandoc.Str(dynamic_date(to_text(raw_template), year, mode))
  end
}
