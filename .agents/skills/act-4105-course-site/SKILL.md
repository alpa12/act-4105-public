---
name: act-4105-course-site
description: "Use when working in this ACT-4105 / ACT-6006 Quarto course-site repository: site structure, Quarto pages, chapter presentations, RevealJS filters/styles/extensions, exercise conversion, legacy course material, dynamic dates, navigation, or the local `tarifr` R package."
---

# ACT-4105 Course Site

Use this skill as the project entry point. Keep it to shared invariants and load the smallest relevant reference before editing.

## Load References

- For ordinary site structure, shared filters/includes/styles, navigation, render rules, or verification, read `references/site-architecture.md`.
- For authoring or changing chapter `diapos.qmd` files, RevealJS styling, progress behavior, examples, subtitles, typography, MathJax, or clean-theme conventions, read `references/revealjs-presentations.md`.
- For converting legacy PowerPoint/PDF course notes to `site/chapitres/*/diapos.qmd`, read `references/legacy-diapos-conversion.md` plus `references/revealjs-presentations.md`.
- For converting or auditing exercise PDFs in `site/chapitres/*/exercices.qmd`, read `references/exercises-conversion.md`.
- For dynamic course years or dates, read `references/dynamic-dates.md`; if shortcode or R-helper syntax is needed, also read `site/_extensions/alpa12/dynamic-year/.agents/skills/dynamic-year-user/SKILL.md`.
- For creating or revising R/`ggplot2` graphics, read `references/graphiques.md`.
- For R-generated tables, reusable R helpers, or package maintenance, read `references/tarifr-package.md`.

## Core Rules

- Work from source files, not generated output. Treat `site/_site/` as render output used only for verification.
- Never modify `site/TODOs.md`; treat it as read-only project context.
- The repository has split licences: `LICENSE-CODE` applies only to original
  software; `LICENSE-CONTENT.md` applies only to eligible original pedagogical
  content; and `THIRD-PARTY-NOTICES.md` records excluded material and pending
  permissions. Do not imply that a repository-wide MIT or CC BY-SA licence
  covers third-party, adapted, or unverified resources.
- Prefer shared Lua filters, shared includes, and shared CSS for repeated behavior. Keep pedagogical `.qmd` files clean unless the change is content-specific.
- Follow `references/revealjs-presentations.md` for slide source conventions, visual styles, text scale, MathJax, tables in presentations, and PDF-specific behavior.
- Keep chapter-local CSS/Lua only for one-off presentation behavior; promote a repeated pattern to shared site code.
- `site/_extensions/` is immutable vendor code in this repository: never modify it. If an extension change is needed, write a precise request for its maintainer (problem, required behavior, regression tests, release and changelog), then integrate only the version delivered by that maintainer.
- Preserve relative paths between `site/cours/` pages and `site/chapitres/` pages, especially for `::: {.diapos source="..."}` embeds and links.
- Update `/README.md` and this skill whenever you introduce a project-wide workflow, structure, shared extension point, or implementation constraint.

## R-Generated Tables

- The authoritative table policy is `references/tarifr-package.md`.

## Quick Orientation

- Main Quarto website: `site/`.
- Canonical chapter sources: `site/chapitres/*/diapos.qmd` and `site/chapitres/*/exercices.qmd`; historical material: `site/vieux-materiel/`.
- Cross-chapter review decks live in `site/revisions/<review>/diapos.qmd`; include `revisions/**/*.qmd` in `project.render` and add each deck to the Révisions navbar menu in `site/_quarto.yml`.
- `scripts/render-pdfs` exports every review deck with the default batch to `site/pdfs/diapos/<review>.pdf`; use `--revision <review>` for one deck. This selector is incompatible with `--chapter` and supports only diapos.
- Shared transforms and browser behavior: `site/filters/` and `site/includes/`; shared styles: `site/styles/`.
- Local reusable R package: `tarifr/`.

## Verification

- For a narrow content change, render the affected document, for example `scripts/quarto render site/chapitres/01-introduction/diapos.qmd`.
- After shared site behavior, navigation, filters, includes, styles, or package changes, run the relevant audit/render command described in the loaded reference.
- Quarto **1.10.17 or newer** is required. Use `scripts/quarto`: it uses the selected Quarto binary and the local Sass executable; it does not reject newer Quarto versions.
- `site/chapitres/00-reference-typography/` is a versioned internal regression deck, excluded from normal project rendering and deployment. Render it explicitly with `scripts/quarto render site/chapitres/00-reference-typography` after typography or table changes it covers.
- The canonical chapter-slide audit covers chapters 01–09. Use `scripts/audit-chapter-slides`, `npm test`, and the PDF exporters as detailed in the site and RevealJS references.
