function Header(header)
  if header.level ~= 1 then
    return nil
  end

  local subtitle = header.attributes["subtitle"]
  if subtitle == nil or subtitle == "" then
    return nil
  end

  header.attributes["subtitle"] = nil

  return {
    header,
    pandoc.Div(
      { pandoc.Plain({ pandoc.Str(subtitle) }) },
      pandoc.Attr("", { "section-subtitle" })
    ),
  }
end
