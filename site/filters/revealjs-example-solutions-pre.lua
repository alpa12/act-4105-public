-- Quarto treats `.solution` as a proof and consumes its first heading as the
-- proof caption. Chapter examples use that heading to split slides and carry
-- presentation classes such as `.text-xs`.
--
-- Mark direct question solutions before Quarto normalizes the AST so the
-- example filter, rather than Quarto's proof renderer, owns their title.

local function has_class(classes, class_name)
  return classes:includes(class_name)
end

local function is_solution(div)
  return div.t == "Div" and has_class(div.classes, "solution")
end

function Div(question)
  if not has_class(question.classes, "question") then
    return nil
  end

  for _, block in ipairs(question.content) do
    if is_solution(block) then
      block.classes = block.classes:filter(function(class)
        return class ~= "solution"
      end)
      block.classes:insert("act-example-solution")
    end
  end

  return question
end
