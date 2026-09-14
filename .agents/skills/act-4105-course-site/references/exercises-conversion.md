# Exercise Conversion

Use this workflow when converting or reviewing exercise PDFs in `site/chapitres/*/exercices.qmd`.

## Source Material

- Use `site/vieux-materiel/exercices/chapN-exercices.pdf` as the primary source for chapter N exercises and solutions.
- Use matching course notes in `site/vieux-materiel/diapos/pdf/` only to resolve ambiguous extraction, terminology, or conceptual context.
- Do not add extra instructional material to exercise files unless needed to faithfully represent or clarify the exercise/solution.
- Inspect non-PDF support material when relevant, such as `site/vieux-materiel/exercices/solution-14.1-a.xlsx`.

## Required Header

Every exercise file must start with:

```yaml
---
metadata-files:
  - ../_exercices.yml
---
```

## Authoring Pattern

```qmd
::: {.question}
Texte de la question.

::: {.solution}
Texte de la solution.
:::
:::
```

- Keep only exercise questions and their solutions.
- Preserve nested question structure with nested `::: {.question}` blocks. Match the source hierarchy exactly instead of flattening subparts.
- Preserve French accents, typography, and meaningful bold/italic emphasis.
- Normalize numeric dates in authored course content to `yyyy/mm/dd`, for example `2013/07/01`.
- Add a short HTML comment near the top of the `.qmd` when intentionally omitting a source element such as a screenshot, decorative diagram, duplicated note, or low-value scanned artifact.

## Remove

- Remove PDF titles such as `Exercices Chapitre X` and `Solutions Chapitre X`.
- Remove page headers, footers, page numbers, and general notes not part of a question or solution.
- Do not add `.grading` blocks during PDF conversion.
- If a PDF contains image-based solution pages, do not rely only on `pdftotext`; verify visually or with OCR before considering the QMD complete.

## Interactions And Numbering

- `site/filters/exercices-questions.lua` normalizes question containers and grading blocks.
- `site/includes/site-behavior.html` automatically numbers nested questions by depth: `1.`, `a)`, `i)`, then repeats.
- The same include folds each direct solution, and optional grading block if present, into one collapsed solution area.

## Audit

Run from the repository root after conversion or review:

```bash
bash scripts/audit-exercices.sh
```

The script currently checks chapters 1-9. It verifies the required YAML header, expected top-level question counts, forbidden PDF title/header/footer residue, absence of `.grading`, common French/transcription issue patterns, and whether source PDFs contain images that need visual/OCR review.
