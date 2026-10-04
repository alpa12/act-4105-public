# Local R Package

Use `tarifr/` for reusable R helpers called by Quarto documents.

## Package Rules

- Put reusable site-specific R code in `tarifr/R/`.
- For deployment, install `tarifr` from `github::alpa12/act-4105-public/tarifr@main`, run `renv::snapshot(prompt = FALSE)`, then run `rsconnect::writeManifest(appDir = "site", appPrimaryDoc = "_quarto.yml", appMode = "quarto-static", contentCategory = "site", dependencyResolution = "strict")`. Do not edit `renv.lock` or `site/manifest.json` by hand. This generated metadata records `tarifr` as the only GitHub dependency, with `RemoteRef: main` and its matching SHA; all other dependencies resolve from CRAN.
- Export only functions needed by Quarto documents through `tarifr/NAMESPACE`.
- Quarto documents should assume `tarifr` is installed. Do not install it or call `pkgload::load_all()` during render.
- Load the package in a hidden chunk near the top of a document when needed:

````qmd
```{r}
#| echo: false
#| include: false

library(tarifr)
```
````

- If `tarifr/R/` changes, reinstall explicitly before rendering affected documents:

```r
source("scripts/install-tarifr.R")
install_tarifr()
```

## Table Helpers

- Audit every table in a target chapter before editing. Keep a short, one-off, non-calculated table in Markdown; use R when data, rows, or calculations recur, including across a question and solution.
- `afficher_table()` is the shared R renderer for course tables. It emits a native Pandoc pipe table with `knitr::kable(..., format = "pipe")`; chapters must not call `knitr::kable()` directly. The sole exception is the labelled comparison chunk in the internal `00-reference-typography` deck, which intentionally tests raw Pandoc output.
- Pass `align` explicitly. Use `formats` as a list of specifications with positional `colonnes`, `type` (`"nombre"`, `"montant"`, or `"pourcentage"`), and optional `digits` or `symbole`; use `lignes_gras = "derniere"` or row positions for totals.
- `format_nombre()`, `format_montant()`, and `format_pourcentage()` use French decimal marks and non-breaking spaces. Use them directly only when formatting an embedded value outside a simple table cell.
- `tarifr` does not own table widths, wrapping, alignment inference, scroll containers, CSS, or RevealJS geometry. Those are handled only by `smart-typst-tables` and shared presentation styles. Do not duplicate this behavior in chapter code.
- Keep table calculations and selection positional (`[[2]]`, `2:4`), then assign visible names only at final preparation. Keep the hidden data/calculation chunk immediately before the first table using it, except for data genuinely shared across sections or chapters.
- For repeated or calculated tables, derive each visible subset, factor, projection, and total from one underlying data frame. Repeat the same input table in every sub-question and bold the values used in that step. Show a total in the question when it is needed to understand or verify the calculation.
- Reproduce source headers and visible multi-column groups through `entetes_groupes`. Use `entetes_calculs` for one free-text label per calculated column; `smart-typst-tables` supplies the resulting `labels` and `calculations` rows, so never author that structure by hand.
- `smart-typst-tables` owns rendered table geometry: inferred types, final display alignment, natural width, header wrapping, `.smart-table` markup, scroll wrappers, and RevealJS layout. Do not duplicate it in `tarifr`, chapter CSS, or source tables. The shared grouped-header theme lives in `site/styles/diapos-clean/content.css`; a chapter may add only a pedagogical vertical divider scoped to one table class.
- Give each table chunk a `#| label:` and `#| output: asis`. Prefer document-level `execute.echo: false` when it applies to the complete deck; otherwise use a chunk-level `#| echo: false`. Do not use `cat()` or `sep` to emit a table.
- To keep a single calculation header on one line, wrap its emitting chunk in `.tableau-calculs-sur-une-ligne`; otherwise let the extension use its horizontal scroll container. The original request is `docs/smart-typst-tables-calculation-headers-request.md`.
- After a table change, render its deck and inspect generated HTML for `�`, transformed `.smart-table` markup, and no `.cell-output-display` around R tables. Inspect RevealJS and PDF when a table is in columns or has long headers.
- Chapters 4 and 5 share annual, semiannual, and premium-policy facts in `site/chapitres/donnees-exemple.R`. Build a wide calculated data frame only when several slides reuse the rows; the displayed `afficher_table()` pattern is a baseline, not a compulsory fixed shape.

```r
afficher_table(
  tableau,
  align = c("l", "r", "r"),
  formats = list(
    list(colonnes = 2, type = "montant", symbole = TRUE),
    list(colonnes = 3, type = "pourcentage", digits = 1)
  ),
  lignes_gras = "derniere"
)
```

## Diagram Helpers

- Use `tarifr::rate_level_diagram()` for rate-level, benefit-level, law-change, parallelogram-style, or exposure-line visuals.
- Its `experience_period` argument is one of `calendar`, `policy`, `accident`, or `reporting`; this controls the label prefix (`AC`, `AA`, `AP`, `AR`) and shape.
- Only `policy` periods are parallelograms. Other experience periods are rectangles.
- Keep this function visually opinionated. Do not vary colors, line types, backgrounds, period labels, or change-line styling in chapter code unless the user asks for a new global style.
- Use `period_months`, `minor_grid_months`, `analyzed_start`, `analyzed_end`, `view_start`, and `view_end` for common period controls.
- For exposure diagrams, use `policies`, `points`, `reference_lines`, and `show_date_labels = TRUE`. Use `mar` only when a RevealJS slide needs compact margins.
- Use `tarifr::trend_period_diagram()` for reusable trend date-calculation diagrams. It supports premium/loss trend and calendar/policy/accident experience bases.
- Use `site/chapitres/05-primes/test.qmd` as the visual validation page for `rate_level_diagram()` variants. Update it when refactoring the helper for annual calendar, annual policy, quarterly calendar, quarterly policy, vertical changes, diagonal changes, or non-12-month policy terms.
- If recurring visuals cannot be expressed cleanly with existing helpers, add a small reusable plotting function to `tarifr/R/`, export it, and update `/README.md` plus this skill.
