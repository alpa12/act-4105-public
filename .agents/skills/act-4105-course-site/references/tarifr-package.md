# Local R Package

Use `tarifr/` for reusable R helpers called by Quarto documents.

## Package Rules

- Put reusable site-specific R code in `tarifr/R/`.
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

- `afficher_table()` is the shared R renderer for course tables. It emits a native Pandoc pipe table with `knitr::kable(..., format = "pipe")`; chapters must not call `knitr::kable()` directly.
- Pass `align` explicitly. Use `formats` as a list of specifications with positional `colonnes`, `type` (`"nombre"`, `"montant"`, or `"pourcentage"`), and optional `digits` or `symbole`; use `lignes_gras = "derniere"` or row positions for totals.
- `format_nombre()`, `format_montant()`, and `format_pourcentage()` use French decimal marks and non-breaking spaces. Use them directly only when formatting an embedded value outside a simple table cell.
- `tarifr` does not own table widths, wrapping, alignment inference, scroll containers, CSS, or RevealJS geometry. Those are handled only by `smart-typst-tables` and shared presentation styles. Do not duplicate this behavior in chapter code.
- Keep table calculations and selection positional (`[[2]]`, `2:4`), then assign visible names only at final preparation. Keep the hidden data/calculation chunk immediately before the first table using it, except for data genuinely shared across sections or chapters.

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
