local function has_class(classes, class)
  for _, value in ipairs(classes) do
    if value == class then
      return true
    end
  end
  return false
end

local function is_valid_scale(value)
  return type(value) == "string" and value:match("^%d+%.?%d*$") ~= nil
end

local function append_style(existing, addition)
  if existing == nil or existing == "" then
    return addition
  end
  if existing:match(";%s*$") then
    return existing .. " " .. addition
  end
  return existing .. "; " .. addition
end

local function apply_scale(el, css_variable)
  if not has_class(el.classes, "text-scale") then
    return nil
  end

  local scale = el.attributes.scale

  if not is_valid_scale(scale) then
    quarto.log.warning("Ignoring invalid text-scale value: " .. tostring(scale))
    return el
  end

  el.attributes["data-text-scale"] = scale
  el.attributes.style = append_style(
    el.attributes.style,
    css_variable .. ": " .. scale .. ";"
  )
  el.attributes.scale = nil

  return el
end

function Header(el)
  return apply_scale(el, "--act-slide-text-scale")
end

function Div(el)
  return apply_scale(el, "--act-text-scale")
end
