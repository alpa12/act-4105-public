---
name: act-4105-course-site
description: "Use when working in this ACT-4105 / ACT-6006 Quarto course-site repository: site structure, Quarto pages, chapter presentations, RevealJS filters/styles/extensions, exercise conversion, legacy course material, dynamic dates, navigation, or the local `tarifr` R package."
---

# ACT-4105 Course Site

Use this skill as the project entry point for this repository. Load the smallest relevant reference file before editing.

## Load References

- For ordinary site structure, shared filters/includes/styles, navigation, render rules, or verification, read `references/site-architecture.md`.
- For authoring or changing chapter `diapos.qmd` files, RevealJS styling, progress bar behavior, examples, subtitles, section titles, text scaling, or clean theme conventions, read `references/revealjs-presentations.md`.
- For converting legacy PowerPoint/PDF course notes to `site/chapitres/*/diapos.qmd`, read `references/legacy-diapos-conversion.md` plus `references/revealjs-presentations.md`.
- For converting or auditing exercise PDFs in `site/chapitres/*/exercices.qmd`, read `references/exercises-conversion.md`.
- For dynamic course years or dates, read `references/dynamic-dates.md`; if shortcode or R-helper syntax is needed, also read `site/_extensions/alpa12/dynamic-year/.agents/skills/dynamic-year-user/SKILL.md`.
- For reusable R helpers, plots, or package maintenance, read `references/tarifr-package.md`.

## Core Rules

- Work from source files, not generated output. Treat `site/_site/` as render output used only for verification.
- Never modify `site/TODOs.md`; treat it as read-only project context.
- The repository has split licences: `LICENSE-CODE` applies only to original
  software; `LICENSE-CONTENT.md` applies only to eligible original pedagogical
  content; and `THIRD-PARTY-NOTICES.md` records excluded material and pending
  permissions. Do not imply that a repository-wide MIT or CC BY-SA licence
  covers third-party, adapted, or unverified resources.
- `website.navbar` in `site/_quarto.yml` is the sole global navigation. Its course, notes, and exercises dropdowns link directly to every session and chapter resource; its global footer identifies the course author and states that Brio, the official Université Laval course site, prevails in case of a discrepancy.
- `site/filters/course-overview.lua` builds the HTML-only `Cours X : titre` heading, date and chapter-resource table from `first-class-date`, `week-id`, and each course’s `chapitres` list of `path`/ `title` maps. Course pages must not embed RevealJS iframes.
- `site/filters/exercise-study-view.lua` adds the optional study-view controls only to HTML output for `exercices.qmd`, keeping the pedagogical sources and exercise PDFs free of UI markup. Its paired include builds the DOM after generic exercise behavior has folded solutions, and creates the local `diapos.html` iframe only when the user requests notes on a desktop viewport. It then enables RevealJS’s native edge controls on that iframe instance only; below 992 px it returns to exercises only.
- Prefer shared Lua filters, shared includes, and shared CSS for repeated behavior. Keep pedagogical `.qmd` files clean unless the change is content-specific.
- `site/filters/chapter-pagetitle.lua` sets the browser and PDF title for canonical chapter documents from their raw `order` and `label` metadata: `<order>. <label> - Notes` for `diapos.qmd` and `<order>. <label> - Exercices` for `exercices.qmd`. `_diapos.yml` and `_exercices.yml` remove the website title prefix; the reference deck restores it explicitly. The filter itself only applies when both metadata values exist.
- In chapter slide sources (`site/chapitres/*/diapos.qmd`), start every list item with a capital letter. End a list item with a period when it is a complete sentence; omit the period when it is a fragment. Omit semicolons at the end of list items and replace typographic em dashes with parentheses when applicable. Preserve em dashes that serve as table placeholders or mathematical symbols.
- In visible French prose and table labels, use non-breaking spaces before `:`, `;`, `?`, and `!`, between digit groups, and before units or symbols. Do not introduce these spaces into R code, shortcodes, or LaTeX source.
- When revising a chapter deck, use the immediately preceding chapter as the visual and pedagogical model, and preserve visible bold and italics from the source material.
- In chapter slide titles, express English translations with `{.english-subtitle subtitle="..."}` on the heading instead of a following `(Ang. : ...)` line.
- Every RevealJS section title (`#`) must set `data-progress-label`. Use a concise non-empty label normally, or an empty value for a very short section when hiding the label improves the progress bar.
- Keep a short equation on the same line as its introductory sentence when that remains legible. For a displayed formula containing long, complete terms, use an aligned multi-line equation and begin every term with a capital letter. Put visible breaks between long additive or subtractive terms with `\\` and aligned `&+` or `&-`; when a long fraction needs those breaks, use an inner `gathered` or `aligned` numerator and/or denominator rather than merely wrapping the source line.
- In a worked calculation, show the symbolic formula first, then substitute the numerical values on successive aligned rows. Preserve the French labels from the source, but omit transitional prose such as “Ou, écrit autrement” when the aligned calculation already makes the equivalence explicit.
- When consecutive slides repeat the exact same title and attributes, use the `cascade` extension: keep the first heading and replace later repeated headings with `---`. This also applies inside a chapter `.question` example and its `.solution`, where `cascade` repeats the generated `Exemple` or `Solution` title. Retain a new heading whenever its classes or attributes differ.
- In a chapter-example `.solution`, never set `name`. The shared example filter owns the generated `Solution <chapter>.<example>` title. Keep any size class or `.text-scale scale="..."` on the first internal `##`; the shared pre-AST filter marks chapter solutions before Quarto’s proof normalization so that heading is preserved.
- Keep chapter-local CSS/Lua only for one-off presentation behavior; promote it to shared site code only when the pattern repeats.
- Use a `::: {.center}` div to horizontally center a group of inline media in a RevealJS slide.
- Reserve RevealJS `.r-stack` for layered media such as images or generated figures. Chrome PDF export can omit HTML text, callouts, and `.absolute.fragment` blocks nested inside its CSS grid. To annotate an image, keep the `.nostretch` image and native Quarto `.absolute` fragments as direct slide children; use custom classes only for semantic or visual styling, not as print-layout wrappers.
- When creating a slide that introduces definitions, use Pandoc definition-list syntax (`**Terme**` followed by `: Définition`). Definition lists are styled for every RevealJS deck by `site/styles/diapos/definitions.css`.
- Keep the `clean-revealjs` slide-type palette centralized. `site/styles/diapos-clean/variables.css` defines the semantic palettes (pedagogical content: gold, example: blue, solution: green, recap: red); `site/styles/diapos-clean/backgrounds.css` maps each slide class to its active-stage background and to `--act-slide-accent`. The same accent must be used by the `h2` underline in `headings.css`. To add a slide type, declare its accent, surface start/end, and glow once in `variables.css`, then add its section and active-stage selectors in `backgrounds.css`; do not duplicate complete gradient declarations or change the white card styles.
- `site/styles/diapos-clean/title-pages.css` owns the screen-only design of Quarto covers (light University Laval surface, red and gold glows, and Overpass). `print.css` mirrors that cover background for PDF; keep level-1 section title pages in their standard course style.
- Keep RevealJS `auto-stretch: true` in the shared presentation metadata. Use Quarto's built-in `.nostretch` attribute on a specific image or slide when explicit display dimensions must be honored; do not add wrapper classes solely to opt out.
- Do not add text-size classes in chapter presentations (`.text-*`, `.smaller`, or `.text-scale`) unless the current user request explicitly asks for one. Keep existing text-size classes unchanged; text-size decisions are reserved for the course author.
- `site/_extensions/` is immutable vendor code in this repository: never modify it. If an extension change is needed, write a precise request for its maintainer (problem, required behavior, regression tests, release and changelog), then integrate only the version delivered by that maintainer.
- Maintain MathJax settings only in `site/mathjax-config.js`. It is published by `site/_quarto.yml` and loaded for regular HTML pages and chapter RevealJS decks; it disables the expression explorer while retaining MathJax 4 rendering with local `mathjax-newcm` assets. Chapter decks use `html-math-method: mathjax`, set `mathjax: false` to disable RevealMathJS v2, and load the local MathJax 4 bundle explicitly. Never use `html-math-method: plain` for chapter decks and never edit generated `mathjax-config.js` copies beside rendered decks.
- Preserve relative paths between `site/cours/` pages and `site/chapitres/` pages, especially for `::: {.diapos source="..."}` embeds and links.
- Update `/README.md` and this skill whenever you introduce a project-wide workflow, structure, shared extension point, or implementation constraint.

## R-Generated Tables

- A non-chapter RevealJS deck inheriting the shared diapos metadata sets suppress-title-prefix: true; the shared post-filter then removes the fallback Chapitre 0 : without affecting canonical chapter decks.

- Audit every table in the target chapter before editing. Keep a short, one-off table in Markdown. Generate a table in R when the same data, rows, or calculations recur in another slide, including a question/solution pair.
- `smart-typst-tables`, configured in `site/chapitres/_diapos.yml`, exclusively owns structural display: inferred types, final alignment, natural widths, header wrapping, `.smart-table` classes, scroll wrappers, and RevealJS geometry. Do not recreate these behaviors in `tarifr`, chapter CSS, or source tables. As vendor code under `site/_extensions/`, it is never modified locally; send required enhancements to its maintainer. A one-off pedagogical vertical divider may use a selector scoped to one table class in chapter-local CSS; do not use this exception for geometry.
- The `clean-revealjs` palette for grouped smart-table headers is defined once in `site/styles/diapos-clean/content.css` through the extension’s public grouped-header variables. Its gradient is painted once on the full `thead`, so it does not restart on each physical header row; the inter-level rule appears only below merged group cells, never below an unrelated empty header cell. Group boundaries appear only inside the table (never on its outer edges); smart-table wrappers have no drop shadow and smart tables suppress the base theme’s grey bottom border. Do not duplicate that styling in a chapter.
- For a repeated or calculated table, define one underlying data frame and derive each visible column subset from it. Place its hidden data/calculation chunk immediately before the first table in the same example or section; only data truly shared between chapters belongs earlier in `site/chapitres/donnees-exemple.R`. Keep every visible renderer beside its slide.
- In a multi-part example, repeat the same input table for each sub-question and bold the values used in that step's calculation.
- Derive factors, projections, and totals from the underlying input table; do not hard-code a separate result matrix.
- Show a total in the question table whenever it is needed to understand or verify the requested calculation, not only in the solution.
- Use `tarifr::afficher_table()` for every R-generated table. It is the shared R layer for native Pandoc serialization, French number/money/percentage formatting, indexed column-format specifications, grouped headers, two-row calculation headers, and bold total rows. For a calculated table, pass `entetes_calculs` as one free-text label per column (for example `c("(1)", "(2)", "(3) = (1) + (2)")`); its source titles form the `labels` row and these values form the `calculations` row. Do not hand-author this structure in a chapter, call `knitr::kable()` directly, or add CSS, width, wrapping, overflow, or HTML-table logic to `tarifr`.
- Pass display formats declaratively, for example `formats = list(list(colonnes = 2:4, type = "montant", symbole = TRUE))`, and set `lignes_gras = "derniere"` for totals. Keep calculations and column selection positional (`[[2]]`, `2:4`); use visible names only when setting final headers or labels.
- Reproduce source-table headers, including visible multi-column groups, faithfully. Pass groups to `afficher_table()` with `entetes_groupes`, for example `list(list(label = "Ratios", colonnes = 2:4))`.
- Set `#| output: asis` on each R table chunk. Set `execute.echo: false` in document metadata when it applies to the whole deck instead of repeating `#| echo: false`; `output: asis` prevents Quarto from adding `.cell-output-display`. Do not add `cat()` or `sep`.
- `entetes_calculs` relies on the integrated `smart-typst-tables` 0.3 support for `smart-tables-header-roles`; its source titles form the `labels` row and its values form the `calculations` row. To keep calculations on one line in one specific RevealJS table, wrap its emitting chunk in a `.tableau-calculs-sur-une-ligne` Div in the `.qmd`; a genuinely over-wide table uses the extension's horizontal scroll container rather than breaking a formula. The original feature request is retained in `docs/smart-typst-tables-calculation-headers-request.md`.
- Give every table chunk a `#| label:` and render the affected deck after changes. Check generated HTML for `�`, transformed `.smart-table` markup, and no `.cell-output-display` enclosing R tables; inspect both RevealJS and PDF when a table is in columns or has long headers.

### Chapters 4 and 5

- `site/chapitres/donnees-exemple.R` is the common source for the annual, semiannual, and premium policy examples used by the two chapters. Keep start/end dates, labels, units, premiums, and shared points there; avoid copying date rows between the decks.
- Use the shared data to build a wide calculated data frame when several slides reuse the same policy rows, then select and rename only the visible columns in each table chunk. Keep formulas or small pedagogical derivations local when they occur once.
- The chapter 4 and 5 table chunks must follow this compact shape:

```r
#| label: chapter-table-name
#| echo: false
#| output: asis

afficher_table(
  data,
  align = c("l", "r", "r"),
  formats = list(list(colonnes = 2:3, type = "montant", symbole = TRUE)),
  lignes_gras = "derniere"
)
```

## Quick Orientation

- Main Quarto website: `site/`.
- Course pages: `site/cours/*.qmd`.
- Chapter content: `site/chapitres/*/diapos.qmd` and `site/chapitres/*/exercices.qmd`.
- Legacy source material: `site/vieux-materiel/diapos/pptx/`, `site/vieux-materiel/diapos/pdf/`, and `site/vieux-materiel/exercices/`.
- Shared Pandoc/Lua transforms: `site/filters/`.
- Late DOM adjustments: `site/includes/`.
- Shared website CSS: `site/styles/site.css`; shared presentation CSS: `site/styles/diapos*.css` and imported subdirectories.
- The unified `scripts/render-pdfs` exporter writes presentation and exercise PDFs for every numeric chapter except `00` to the Git-ignored `site/pdfs/diapos/` and `site/pdfs/exercices/` directories by default. Use `--chapter 06` to select one chapter and `--type diapos` or `--type exercices` to select one PDF type. Presentation exports delegate to `scripts/revealjs-pdf` and enable an H1/H2 PDF navigation outline (consecutive duplicate H2 entries are grouped). Exercise exports use the `exercices-pdf` profile, which activates `alpa12/exam`, sets common course metadata, enables `show-solutions` and `show-grading`, and uses `site/instructions-exercices.qmd` for common cover instructions; only the PDF output is retained. The presentation export inserts invisible soft breaks in printed headings so Chrome retains spaces in outline labels when a title wraps. The rows in the printed chapter overview are internal PDF links to their H1 sections. Direct `scripts/revealjs-pdf` calls remain outline-free unless they pass `--outline-h1-h2`.
- `site/styles/diapos-clean/backgrounds.css` owns full-stage `clean-revealjs` backgrounds (normal slides, examples, solutions, and recap slides); it must not style the white slide cards.
- The generated example filter assigns `.act-example-slide` and `.act-example-solution-slide`; recap slides use `.remember-slide`, `.remember-slides`, or `.remember-slides-recap`. Ordinary slide content is the pedagogical (gold) default.
- Local reusable R package: `tarifr/`, including `two_step_trend_diagram()` for two-step premium trend timelines.

## Verification

- For a narrow content change, render the affected document, for example `quarto render site/chapitres/01-introduction/diapos.qmd`.
- After shared site behavior, navigation, filters, includes, styles, or package changes, run the relevant audit/render command described in the loaded reference.
### Canonical chapter-slide validation

Restore the project environment with `renv::restore()`, then run `npm ci`. Quarto **1.10.17** is required. Use `scripts/quarto` so the wrapper rejects another Quarto version and points Quarto at the local Sass binary from `node_modules/.bin/sass`.

The canonical audit is `scripts/audit-chapter-slides`. With no option it discovers exactly chapters 01 through 09, renders every `diapos.qmd` separately with `scripts/quarto render ... --no-cache`, and checks source conventions, local `chapter-css` and display resources, `fig-alt`/`alt`, CSS ordering and markers, local MathJax, error markers, and Chrome behavior at `1440×900` and `1024×768`. It uses `CSK_CHROME` for Chrome/Chromium and writes only the compact synthesis to `docs/rapport-audit-presentations.md`; raw logs and captures belong in ignored temporary paths. Chapter `00-reference-typography` is intentionally excluded.

Supported options are `--chapter 06`, `--skip-render`, `--browser-only`, `--report FILE`, and `--wait MS`. A passing report means there were no console errors, JavaScript exceptions, failed or remote-required display requests, Reveal initialization failures, invalid natural image sizes, or significant descendant overflows during horizontal, vertical, and fragment traversal. External pedagogical links may remain when they are not required display resources.

Run `npm test` for the native Node tests covering the shared RevealJS modules. Export a deck with `scripts/revealjs-pdf ... --out FILE`, all chapter PDFs with `scripts/render-pdfs`, or use its `--chapter` and `--type` selectors for a targeted export. Validate PDF page count, file size, landscape dimensions, title pages, overview slides, tables, formulas, images, and dense slides. Modify sources (`.qmd`, CSS, Lua, includes, scripts and local assets), never generated `site/_site/` HTML, and never `site/_extensions/` or `site/TODOs.md`.
