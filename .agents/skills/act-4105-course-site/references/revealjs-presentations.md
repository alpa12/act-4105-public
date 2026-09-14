# RevealJS Presentations

Use these conventions for `site/chapitres/*/diapos.qmd`.

## Required Header

```yaml
---
title: "Chapitre N: Titre"
format:
  revealjs: default
metadata-files:
  - ../_diapos.yml
---
```

Chapter `_metadata.yml` supplies listing metadata. Update it when replacing placeholder content with real content.

## Shared Configuration

- `site/chapitres/_diapos.yml` configures both `revealjs` and `clean-revealjs`.
- Presentations are top aligned by default with `center: false`; use `.center` on a heading for an exceptional centered content slide.
- Use `revealjs: default`; the shared metadata supplies the local Clean theme and presentation CSS.
- If local chapter CSS is needed, load `/styles/diapos.css`, `/styles/diapos-clean.css`, then the chapter-local `diapos.css`.
- Keep `progress: false` and the `revealjs-progress-bar` filter in shared config. Do not repeat shared progress-bar config in individual decks unless overriding intentionally.
- Keep site-root paths such as `/styles/diapos.css` for shared assets in `_diapos.yml`.
- Keep Quarto's `auto-stretch: true` as the shared default: it applies `.r-stretch` to a lone top-level image and sizes it to the remaining slide area. It overrides explicit display dimensions such as `width` or `out-width`.
- To honor explicit dimensions for a static image, use Quarto's built-in `.nostretch` attribute, for example `![](assets/image.png){.nostretch width=92%}`. For an exceptional code-generated figure, apply `.nostretch` to the slide title when its direct image output must retain `out-width` or `out-height`, for example `## Title {.nostretch}`. Do not introduce wrapper classes solely for this opt-out.

## Structure And Progress

- Include exactly one overview slide marked `.progress-overview`, usually `## Contenu du chapitre {.progress-overview}` after readings/introduction.
- Use top-level `#` headings for major progress sections after the overview slide.
- Add `data-progress-label="Court"` to long section headings so the progress bar remains readable.
- Use `.hide-progress-bar` only for special slides that need an uncluttered stage; the slide still counts.
- The local `title-prefix` extension prefixes the document title with `Chapitre <order> :` and numbers top-level `#` sections. Add `{.unnumbered}` to a section title, for example `# Section {.unnumbered}`, to omit its number without advancing the section counter. The chapter number comes from document `order` metadata or sibling `_metadata.yml`.
- The `cascade` extension repeats consecutive slide titles separated by `---`. Write a new heading when classes or attributes change, such as `.english-subtitle`, `.text-small`, or background attributes.
- Chapter decks load the shared `site/mathjax-config.js` and the local MathJax 4 bundle from `site/assets/vendor/mathjax/`. Keep `html-math-method: mathjax` and `mathjax: false` in the shared RevealJS metadata: Pandoc emits MathJax delimiters while the manual bundle handles typesetting without the incompatible RevealMathJS v2 plugin. Never use `html-math-method: plain`, because it converts some equations to text before MathJax can process them.

## Shared Styling

- `site/styles/diapos.css` is the base presentation CSS manifest and imports `site/styles/diapos/`.
- `site/styles/diapos-clean.css` contains `clean-revealjs` overrides and imports `site/styles/diapos-clean/`; load it after the base layer and before chapter-local CSS.
- `site/styles/diapos-clean/print.css` is imported last by `diapos-clean.css` and owns clean-theme PDF export mode. It must target only `html.reveal-print` and `html.print-pdf`, turning each printed slide into a full-page white card while hiding the external presentation chrome. `pdf-separate-fragments` may be `true` for one printed page per fragment state or `false` for the final state; print CSS must preserve fragments reveal.js marks `.visible`, `.current-fragment`, or `data-act-print-visible-fragment`.
- `site/filters/revealjs-print-overview.lua` inserts a source-level print-only `.act-print-overview-list` into each `.progress-overview` slide before the `revealjs-progress-bar` extension runs.
- `site/includes/revealjs-print-preflight.html` is loaded with `include-in-header` before RevealJS initializes. It refreshes the print overview list and neutralizes artificial overview fragments in print mode.
- `docs/revealjs-pdf-export-debug-notes.md` is retained until the Chrome Print Preview workflow confirms the export fix; do not delete it without user confirmation.
- `scripts/revealjs-pdf` is the deterministic author-side PDF export path. It renders `.qmd` inputs, serves the built HTML locally, injects the print preflight if needed, and prints through Chrome/Chromium headless with `?print-pdf`.
- The clean palette is in `site/styles/diapos-clean/variables.css`: Laval-inspired red primary accent, gold secondary rules/markers, and blue complementary states.
- Keep CSS local to a chapter when it represents a semantic visual used only by that presentation. Promote to shared CSS only for repeated patterns.
- Shared presentation CSS sets knitr's RevealJS outputs (`figure-revealjs/`) to the card content width with `height: auto !important`, retaining their proportions without relying on RevealJS's `.r-stretch` calculation. Do not add per-figure width workarounds merely to prevent horizontal overflow. Use chapter-local CSS only when a deck needs a deliberate narrower width.
- Shared presentation CSS renders tables at their intrinsic width, centered in their slide or Quarto column, and uses a compact font and row spacing. Do not set a table to full width unless that width is essential to its content.
- Avoid inline styles in `.qmd` and Lua filters. Use classes plus CSS unless the adjustment is tiny and clearly local.
- Do not override generic Reveal internals such as `.r-stretch` for chapter-specific image sizing. Prefer Quarto's built-in `.nostretch` for opt-out; introduce an opt-in class such as `.compact-slide-image` only for genuinely new image behavior.

## Headings, Subtitles, And Text Scale

- Text-size classes (`.text-*`, `.smaller`, and `.text-scale`) are reserved for manual course-author adjustments. Do not add, remove, or modify them unless the current user explicitly requests it.
- Section title slides can use a subtitle only with a heading `subtitle` attribute, for example `# Objectifs {subtitle="Pourquoi le prix d'assurance est prospectif"}`.
- `site/filters/revealjs-section-subtitle.lua` creates `.section-subtitle`; styling lives in `site/styles/diapos-clean/section-titles.css`. Do not use this for labels, punchlines, or keyword lists.
- Clean level-2 heading underlines are styled by `site/styles/diapos-clean/headings.css` and sized at runtime by `site/includes/revealjs-heading-underlines.html`. Keep underline sizing in that shared include/CSS pair.
- English subtitles use `.english-subtitle subtitle="English term"` on a heading. `site/filters/revealjs-english-subtitle.lua` adds `.english-subtitle-text`; CSS owns the appearance.
- Text-size presets live in `site/styles/diapos/text-scale.css`: `.text-xs`, `.text-smaller`, `.text-small`, `.text-medium`, `.text-large`, `.text-larger`, `.text-xl`, with `.smaller` as an alias. They use a 1.1 ratio around `.text-medium`.
- Put text-size classes on a heading to resize slide content without changing the fixed, equal level-1 and level-2 title sizes, or on an inner fenced div to resize only that block. Lower-level headings inherit the selected text size.
- For precise scaling, add `.text-scale scale=0.84` to a heading or block. `site/filters/revealjs-text-scale.lua` accepts non-negative decimal values and converts the attribute to a CSS variable.
- `site/chapitres/00-reference-typography/diapos.qmd` is an unpublished visual regression deck for this scale. It is deliberately absent from the sidebar and chapter metadata; render it explicitly after shared typography changes.

## Examples And Math

- Author examples as `:::: {.question title="Title"}` with an optional nested `::: {.solution}` block.
- `site/filters/revealjs-exemples.lua` rewrites slide titles to `Exemple <order>.<n> - Title` or `Solution <order>.<n> - Title`.
- Internal level-2 headings split an example into slides; their text is ignored, but heading classes are preserved.
- Never set `name` on a chapter-example `.solution`: `site/filters/revealjs-exemples.lua` owns the visible `Solution <chapter>.<example>` title. Keep a size class or precise `.text-scale scale="..."` on the first internal heading, for example `## {.text-xs}`. `site/filters/revealjs-example-solutions-pre.lua` marks chapter solutions before Quarto’s proof normalization, allowing the example filter to turn that heading into the generated RevealJS slide.
- Display equations inherit the selected text size directly, without an additional equation-scale factor.
- In RevealJS display equations, use `\textbf{...}` for bold text. Avoid `\mathbf{\text{...}}` inside `\text{...}`.
- Write decimal points directly as `.` in equations; do not use `{.}` as a separator.
- Long equations should be split across lines in source when practical.

## Cards, Media, Controls, And Absolute Blocks

- The internal vertical gap in slide content is controlled by `--act-slide-top-offset` in `site/styles/diapos/foundations.css`.
- Clean slide cards are styled in `site/styles/diapos-clean/cards.css`; dimensional variables live in `site/styles/diapos-clean/variables.css`.
- Keep card padding in viewport-relative or `rem` units, not `em`, so `.text-*` and `.title-*` do not alter card alignment.
- Do not force RevealJS section height with `!important`; RevealJS temporarily sets section height to `auto` while sizing `.r-stretch`.
- To fill the clean card area, use `## {.card-fill}` with `::: {.card-fill-content}`. Add `.card-contain` to keep full media visible without cropping. Use `.card-fill-caption` for visible media captions.
- Floating extension buttons are normalized by `site/includes/revealjs-extension-controls.html` and styled by `site/styles/diapos/extension-controls.css`.
- For future local extension controls, wrap launcher buttons in `.slide-extension-controls` or add `data-act-extension-controls`.
- For one-off visible references, use Quarto native absolute positioning, for example `::: {.absolute bottom=20 left=0 width="100%"}`. Do not wrap `.aside` inside `.absolute`, because Quarto extracts asides from the wrapper.
- Use RevealJS `.r-stack` only to layer media such as images or R-generated figures. Its CSS grid can cause Chrome's PDF renderer to omit nested HTML text even when a fragment is `.visible`, opaque, in bounds, and above the image. For image annotations, make the `.nostretch` image and native Quarto `.absolute.fragment` blocks direct children of the slide. Keep custom classes limited to the annotation's visual semantics; do not add a print-only wrapper or clone the fragments.

## Chapter-Specific Notes

- In chapter 4 and 5 diapo files, name every R chunk with `#| label:` so setup, figure, and table chunks remain traceable.
- Pandoc definition lists are styled for every RevealJS deck by `site/styles/diapos/definitions.css`. Definition terms remain unbolded by default, so author explicit emphasis when required, for example `**Unités écrites** *(Ang. : Written exposures)*`.
