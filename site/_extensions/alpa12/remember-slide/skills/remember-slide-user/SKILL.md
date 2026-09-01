---
name: remember-slide-user
description: Use the remember-slide Quarto extension in revealjs presentations. Use when Codex needs to add, configure, explain, troubleshoot, or refactor progressive cumulative recap slides marked with .remember-slide in a .qmd revealjs deck.
---

# Remember Slide User

## Quick Use

Enable the extension in a revealjs `.qmd` presentation:

```yaml
---
title: "My Talk"
format: revealjs
filters:
  - remember-slide
remember-slide:
  title: "Key points to remember"
---
```

Add a remember marker where a recap slide should appear:

```markdown
## {.remember-slide}

This is the point the audience should carry forward.
```

The marker slide is replaced by a generated recap slide. Its content becomes the current item in a cumulative unordered list. Earlier items remain visible with a faded style.

## Authoring Rules

Use short, complete recap points. The extension is meant for memorable ideas, not full slide transcripts.

Use the no-title heading marker as the default:

```markdown
## {.remember-slide}

Short point with **bold**, *emphasis*, `code`, [links](https://quarto.org), or inline math such as $n + 1$.
```

Use a fenced Div marker when generated content or templates make that easier:

```markdown
::: {.remember-slide}
This point is also turned into a generated recap slide.
:::
```

Use a plural marker for a final summary slide. It does not add a new item; it displays all remembered items with the current-item style:

```markdown
## Conclusion {.remember-slides}
```

Do not add normal slide titles to marker slides. The visible recap title comes from `remember-slide.title`.

## Options

Common options:

```yaml
remember-slide:
  title: "Remember this"
  previous-opacity: 0.35
  current-opacity: 1
  current-font-weight: inherit
  font-size: 0.72em
  dense-font-size: 0.62em
  dense-threshold: 4
  list-style-type: disc
  list-gap: 0.35em
  content-width: 100%
  content-max-width: none
  title-margin-bottom: 0.35em
  item-line-height: 1.15
  list-padding-left: 1.05em
  summary-class: "remember-slides"
```

Advanced options:

```yaml
remember-slide:
  enabled: true
  include-css: true
  class: "remember-slide"
  previous-class: "remember-slide-previous"
  current-class: "remember-slide-current"
  content-class: "remember-slide-content"
  recap-class: "remember-slide-recap"
  summary-recap-class: "remember-slides-recap"
  slide-level: 2
  fit-text: false
  fit-threshold: 3
  fit-class: "r-fit-text"
```

Set `include-css: false` only when providing equivalent custom CSS yourself. Set `enabled: false` to temporarily disable the transform for a deck.

## Troubleshooting

If marker slides still appear as normal slides, check that `filters: [remember-slide]` is present and that the installed extension folder is available under `_extensions/remember-slide/`.

If the recap slide appears but styles are missing, check whether `include-css: false` was set. By default, the Lua filter loads `remember-slide.css` automatically.

If recap slides contain many points, prefer explicit stable sizes with `font-size`, `dense-font-size`, and `dense-threshold`. Avoid `fit-text` unless the deck author specifically accepts revealjs text fitting behavior. Increase `content-width`, leave `content-max-width: none`, and lower `list-padding-left` to avoid wasting horizontal slide space.

If fenced Div markers produce recap slides at the wrong heading level, set `remember-slide.slide-level` to the revealjs slide level used by the deck.

The extension targets revealjs output only. For non-revealjs formats it warns and leaves the document unchanged.
