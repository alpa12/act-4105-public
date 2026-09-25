# Site Architecture

## Project Layout

- `site/_quarto.yml` configures the Quarto website, its navbar, global filters, global CSS, resources, and render targets.
- `site/cours/*.qmd` are course/session pages. They use front matter such as `week-id`, `label`, and `chapitres`; each chapter entry is a `path`/ `title` map.
- `site/chapitres/*/_metadata.yml` provides chapter metadata. Use `label` for compact navigation/listing text, `title` for the full title, and `description` for longer summaries.
- `site/chapitres/*/diapos.qmd` are chapter RevealJS presentations. `site/chapitres/*/exercices.qmd` are exercises.
- `site/revisions/*/diapos.qmd` are cross-chapter RevealJS review decks. They are standalone resources: add the folder glob to `project.render` and each deck to the Révisions menu in `website.navbar`.
- `site/filters/` contains Pandoc/Lua transforms. `site/includes/` contains late browser-side DOM adjustments for HTML shape that Quarto creates after filters.
- `site/styles/site.css` styles the HTML website. Presentation styling lives under `site/styles/diapos*.css`.
- `site/_extensions/` contains immutable vendor code used by the site. Never edit it locally; request required changes from the extension maintainer and integrate only the version they deliver.
- `site/_site/` is generated output. Inspect it after render, but edit sources.

## Render Targets

- `project.render` intentionally excludes `chapitres/00-reference-typography/`. This versioned internal deck must never be rendered or deployed with the site. Its local Quarto project renders only itself through `scripts/quarto render site/chapitres/00-reference-typography`, writing to the ignored, non-published `_reference/chapitres/00-reference-typography/` tree.
- Render every document through `scripts/quarto`. Quarto **1.10.17 or newer** is required; the wrapper selects the configured Quarto binary and local Sass but does not reject newer compatible versions.
- `scripts/render-pdfs` exports chapter PDFs and every `revisions/*/diapos.qmd` deck by default. A targeted review export uses `--revision <review>` and writes `site/pdfs/diapos/<review>.pdf`; it cannot be combined with `--chapter` or `--type exercices`.

## Navigation

- `website.navbar` in `site/_quarto.yml` is the only global navigation. Its Cours, Notes, and Exercices dropdowns link to every session and chapter resource; its global footer names Alexandre Parent, the year 2026, and states that Brio, the official Université Laval course site, prevails in case of a discrepancy.
- Course and chapter pages retain their own links and diapo embeddings; they do not require a generated navigation structure.

## Site Behaviors

- Diapo embeds are authored in `.qmd` as `::: {.diapos source="..."}` and rendered by `site/filters/notes-de-cours.lua`.
- `site/filters/course-overview.lua` sets the `Cours X : titre` heading and injects the date and a Notes/Exercices table only for HTML numeric course pages. It derives the ISO date from inherited `first-class-date` and `week-id`, and uses the course’s `chapitres` maps; course sources therefore have no RevealJS iframe embeds.
- Exercise question and grading classes are normalized by `site/filters/exercices-questions.lua`.
- `site/includes/site-behavior.html` contains only generic post-render behavior: question numbering, folded exercise feedback (Quarto emits `.proof.solution` late), and links to rendered `diapos.html` pages opening in a separate tab/window.
- `site/filters/exercise-study-view.lua` injects accessible study-view controls only for HTML `exercices.qmd` pages, leaving the pedagogical sources and exercise PDFs free of UI markup. `site/includes/exercise-study-mode.html` then wraps the exercise body after generic behavior has run, lazily creates a sibling `diapos.html` iframe only in the desktop notes mode, and enables RevealJS’s native edge controls only on that iframe instance after it initializes; below 992 px it returns to exercises only.
- `site/_quarto.yml` restricts direct rendering to `.qmd` files. Do not render `*.ejs.md` listing templates as standalone pages.

## Maintenance

- Update `/README.md` when project structure, workflow, conventions, or cross-cutting features change.
- Update the skill when adding a new project-specific pattern, shared extension point, or important implementation constraint.
- If both project docs and this skill are stale, refresh both in the same task.

## Verification

- For a narrow change, run `scripts/quarto render PATH` and inspect matching `site/_site/` output. For navbar changes or shared filters/includes/styles, run `scripts/quarto render site` when feasible.
- Inspect relevant files in `site/_site/` to confirm the expected markup and links were produced.
- Run `bash scripts/audit-exercices.sh` after converting or materially reviewing exercises.
- `scripts/audit-chapter-slides` covers chapters 01–09 only. It renders each source with `scripts/quarto render ... --no-cache`, checks source and generated HTML, then checks Chrome at `1440×900` and `1024×768`. Set `CSK_CHROME` to Chrome/Chromium; supported options are `--chapter 06`, `--skip-render`, `--browser-only`, `--report FILE`, and `--wait MS`.
- A passing audit has no console errors, JavaScript exceptions, failed required display resources, Reveal initialization failures, invalid natural image sizes, or significant descendant overflow. External pedagogical links are allowed when they are not required display resources.
- Run `npm test` for native RevealJS tests. Use `scripts/revealjs-pdf` for one deck and `scripts/render-pdfs` for all chapter and review PDFs, targeted `--chapter`, `--revision`, or `--type` exports; inspect PDF output proportionately to the change.
