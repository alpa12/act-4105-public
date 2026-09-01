local function is_html_output()
  if quarto ~= nil
    and quarto.doc ~= nil
    and quarto.doc.is_format ~= nil
  then
    return quarto.doc.is_format("html")
  end

  return FORMAT ~= nil and FORMAT:match("html") ~= nil
end

local function current_input_file()
  if quarto ~= nil and quarto.doc ~= nil and quarto.doc.input_file ~= nil then
    return quarto.doc.input_file
  end

  if PANDOC_STATE ~= nil
    and PANDOC_STATE.input_files ~= nil
    and #PANDOC_STATE.input_files > 0
  then
    return PANDOC_STATE.input_files[1]
  end

  return nil
end

local function is_exercise_document()
  local input_file = current_input_file()
  return input_file ~= nil and pandoc.path.filename(input_file) == "exercices.qmd"
end

local study_view = [[
<section class="exercise-study-view" aria-label="Mode d’étude">
  <div class="exercise-study-controls" role="group" aria-label="Affichage des exercices">
    <button class="exercise-study-control" type="button" data-exercise-study-mode="exercises" aria-pressed="true" aria-expanded="false" aria-controls="exercise-study-notes">Exercices seulement</button>
    <button class="exercise-study-control" type="button" data-exercise-study-mode="notes" aria-pressed="false" aria-expanded="false" aria-controls="exercise-study-notes">Exercices et notes</button>
  </div>
  <aside id="exercise-study-notes" class="exercise-study-notes" role="region" aria-label="Notes du chapitre" aria-hidden="true" data-diapos-src="diapos.html" hidden></aside>
</section>
]]

function Pandoc(document)
  if not is_html_output() or not is_exercise_document() then
    return document
  end

  table.insert(document.blocks, 1, pandoc.RawBlock("html", study_view))
  return document
end
