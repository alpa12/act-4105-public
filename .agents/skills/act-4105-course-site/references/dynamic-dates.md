# Dynamic Dates

Use these rules for course examples that should remain current when `base-year` changes.

## Project Configuration

- The local extension lives in `site/_extensions/alpa12/dynamic-year`.
- `base-year` is defined in `site/_quarto.yml` and is currently `2026`.
- Read `site/_extensions/alpa12/dynamic-year/.agents/skills/dynamic-year-user/SKILL.md` when exact shortcode or R-helper syntax is needed.

## Choosing Static Versus Dynamic

- Keep dates static when they describe the document itself, bibliographic sources, or fixed historical facts.
- Use dynamic dates for examples, data periods, effective dates, transaction dates, valuation dates, evaluation dates, labels in diagrams, table values, axis annotations, and `reference_lines` that should track the course year.
- Decide by meaning, not by syntax convenience.

## Shortcodes

- Use `dynamic-year` only when the visible value is a year.
- Use `dynamic-date` for complete visible dates.
- Write dynamic-date templates in `YYYY-MM-DD` form with an integer offset only.
- Avoid `{{< dynamic-year x >}}` inside equations; keep the year outside the math block or rewrite the label so the equation remains plain TeX.

## Offsets

- With `base-year: 2026`, current examples often land in 2024-2026, so offsets like `-2`, `-1`, and `0` are often right.
- When a legacy example would render in the future relative to `base-year`, shift the whole example coherently into the past. Preserve internal spacing between years/dates.
