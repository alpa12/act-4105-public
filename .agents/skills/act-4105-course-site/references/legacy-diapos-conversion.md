# Legacy Diapos Conversion

Use this workflow when converting legacy course-note material into `site/chapitres/*/diapos.qmd`.

## Source Material

- Prefer local legacy files over external or personal copies.
- Use `site/vieux-materiel/diapos/pptx/chapN-*.pptx` as the primary source when available because it exposes slide order, hidden-slide status, shapes, text boxes, and speaker notes.
- Use `site/vieux-materiel/diapos/pdf/chapN-*.pdf` as a rendered reference for formulas and layout.
- Convert only the requested chapter. Do not opportunistically convert later chapters.
- Treat existing presentation files as templates when they contain placeholders; replace the content rather than preserving filler.

## Preserve

- Reproduce the source slide order and core pedagogical content faithfully.
- Keep definitions, formulas, examples, terminology, ratios, tables, and meaningful emphasis.
- Do not invent or paraphrase new visible slide text. Copy or faithfully transcribe visible content from source slides.
- Convert visible PowerPoint slides by default. Do not include hidden slides or slides marked `NE PAS IMPRIMER` unless explicitly asked.
- Put substantive speaker-note content in `::: {.notes}`. Omit repeated footers and non-pedagogical notes.
- Preserve French accents and correct obvious transcription, spelling, terminology, and notation errors.
- Prefer editable native Quarto content: Markdown, LaTeX, tables, columns, callouts, Mermaid, and simple semantic classes.
- Extract meaningful PPTX images into chapter-local assets such as `site/chapitres/01-introduction/assets/` and reference them with paths relative to `diapos.qmd`.
- For complex grouped PowerPoint shapes, first try transparent image/vector extraction. Avoid opaque white slide screenshots unless they are acceptable for the visual. Flag any important visual that needs manual validation.

## Avoid

- Do not do visual theme work during content conversion. Keep style decisions in shared Quarto theme/CSS work.
- Do not add custom CSS, layout hacks, raw HTML, or one-off styling to chapter `diapos.qmd` unless the user asks.
- Do not preserve PDF page numbers, headers, footers, or decorative artifacts.
- Do not hard-code numbering in content titles, section headings, overview lists, or example headings, such as `Chapitre 1:`, `# I.`, numbered outline lists, or `Exemple 1.1`.

## Links And Navigation

- If adding or renaming a chapter presentation, update any `site/cours/*.qmd` embed written as `::: {.diapos source="..."}`.
- The navbar configured in `site/_quarto.yml` is the sole global navigation; no generated navigation update is required for a new `diapos.qmd`.
- Search for stale references to old presentation paths before finishing.

## Verification

- Render at least the converted presentation, for example `quarto render site/chapitres/01-introduction/diapos.qmd`.
- When shared behavior changed, run `quarto render site` from the repository root when feasible.
