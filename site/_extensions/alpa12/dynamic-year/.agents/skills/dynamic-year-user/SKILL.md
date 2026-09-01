---
name: dynamic-year-user
description: Use the Dynamic Year Quarto extension in Quarto projects and documents. Use when Codex needs to install or configure the extension, add `base-year`, write `dynamic-year` or `dynamic-date` shortcodes, source the R helpers, or explain the extension's basic usage to a Quarto author.
---

# Dynamic Year User

## Quick Use

Install the extension in a Quarto project with:

```bash
quarto add alpa12/dynamic-year
```

Define the reference year in `_quarto.yml` or in a document front matter:

```yaml
base-year: 2026
```

Use `dynamic-year` for year-only values:

```markdown
{{< dynamic-year >}}
{{< dynamic-year -1 >}}
{{< dynamic-year 1 >}}
```

Use `dynamic-date` when only the year should move:

```markdown
{{< dynamic-date "YYYY-10-15" >}}
{{< dynamic-date "YYYY-10-15" -1 >}}
```

Handle impossible dates explicitly when needed:

```markdown
{{< dynamic-date "YYYY-02-30" invalid="previous-month-end" >}}
{{< dynamic-date "YYYY-02-30" invalid="next-month-start" >}}
```

## R Chunks

Source the helper file from a Quarto chunk:

```r
source("_extensions/dynamic-year/dynamic-year.R")

dynamic_year()
dynamic_year(-1)
dynamic_date("YYYY")
dynamic_date("YYYY-10-15")
dynamic_date("YYYY-02-30", invalid = "previous-month-end")
```

## Rules

Use integer offsets only. Keep date templates in `YYYY-MM-DD` form for shortcodes. Set `invalid` only to `error`, `previous-month-end`, or `next-month-start`.
