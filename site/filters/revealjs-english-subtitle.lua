function Header(el)
  if not el.classes:includes("english-subtitle") then
    return nil
  end

  local subtitle = el.attributes["subtitle"]
  if not subtitle or subtitle == "" then
    return nil
  end

  el.content:insert(pandoc.Space())
  el.content:insert(
    pandoc.Span(
      { pandoc.Str("(Ang. : " .. subtitle .. ")") },
      pandoc.Attr("", { "english-subtitle-text" })
    )
  )
  el.attributes["subtitle"] = nil

  return el
end
