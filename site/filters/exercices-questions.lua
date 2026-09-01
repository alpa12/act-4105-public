local function is_div(block, class_name)
  return block.t == "Div" and block.classes:includes(class_name)
end

local function copy_without_class(classes, class_name)
  local out = pandoc.List()
  for _, class in ipairs(classes) do
    if class ~= class_name then
      out:insert(class)
    end
  end
  return out
end

local function is_revealjs()
  return quarto ~= nil
    and quarto.doc ~= nil
    and quarto.doc.is_format ~= nil
    and quarto.doc.is_format("revealjs")
end

function Div(div)
  if is_revealjs() then
    return nil
  end

  if is_div(div, "question") then
    div.classes = copy_without_class(div.classes, "question")
    div.classes:insert("question-block")
    return div
  end

  if is_div(div, "grading") then
    div.classes = copy_without_class(div.classes, "grading")
    div.classes:insert("question-grading")
    return div
  end

  return nil
end
