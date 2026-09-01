#set text(size: 10.5pt)
#set par(justify: true)

#let exam-workbook-cover-title() = [
  #align(center)[#text(size: 22pt, weight: "bold")[Cahier d'exercices]]
]

#let exam-workbook-cover-subtitle(subtitle) = [
  #v(3mm)
  #align(center)[#text(size: 14pt)[#subtitle]]
]

#let exam-workbook-running-title() = [
  #text(size: 11pt)[Cahier d'exercices]
]

#let exam-section(title) = [
  #v(0.8em)
  #block(width: 100%)[#text(size: 16pt, weight: "bold")[#title]]
  #v(0.35em)
]

#let exam-question-heading(number: "", points: "", bonus: false) = [
  #v(0.8em)
  #block(width: 100%)[
    #text(weight: "bold")[#number.]
    #if bonus [
      #h(0.45em)
      #text(size: 8pt, weight: "bold", fill: rgb("#9a3412"))[BONUS]
    ]
    #if points != "" [
      #h(1fr)
      #text(size: 8pt, weight: "bold")[
        [#if bonus [+]#points]
      ]
    ]
  ]
  #v(0.25em)
]

#let exam-points-label(points: "", bonus: false) = [
  #if points != "" [
    #text(size: 8pt, weight: "bold")[
      [#if bonus [+]#points]
    ]
  ]
]

#let exam-question-line(label: "", points: "", bonus: false, body) = [
  #grid(
    columns: (1fr, 10mm),
    column-gutter: 0mm,
    align: top,
    [
      #grid(
        columns: (auto, 1fr),
        column-gutter: 0.35em,
        align: top,
        [#text(weight: "bold")[#label]],
        [#block(width: 100%)[#body]],
      )
    ],
    [#align(right)[#exam-points-label(points: points, bonus: bonus)]],
  )
]

#let exam-nested-question-heading(label: "", points: "", bonus: false) = [
  #v(0.45em)
  #block(width: 100%)[
    #text(weight: "bold")[#label]
    #if bonus [
      #h(0.45em)
      #text(size: 8pt, weight: "bold", fill: rgb("#9a3412"))[BONUS]
    ]
    #h(1fr)
    #exam-points-label(points: points, bonus: bonus)
  ]
  #v(0.15em)
]

#let exam-answer-box(height: 8em) = [
  #block(width: 100%, height: height, stroke: 0.45pt + rgb("#777777"), inset: 3pt)[]
]

#let exam-answer-box-fill() = [
  #block(width: 100%, stroke: 0.45pt + rgb("#777777"), inset: 3pt)[#v(1fr)]
]

#let exam-answer-line(width: 8cm) = [
  #v(1.6em)
  #line(length: width, stroke: 0.45pt + rgb("#777777"))
]

#let exam-answer-lines(lines: 4, full: false, width: 8cm) = [
  #v(1.6em)
  #for i in range(lines) [
    #line(length: if full { 100% } else { width }, stroke: 0.45pt + rgb("#777777"))
    #v(1.15em)
  ]
]

#let exam-answer-lines-fill(full: false, width: 8cm) = [
  #v(1.6em)
  #block(width: if full { 100% } else { width }, height: 1fr, clip: true)[
    #for i in range(60) [
      #line(length: 100%, stroke: 0.45pt + rgb("#777777"))
      #v(1.15em)
    ]
  ]
]

#let exam-solution-title(title) = [
  #v(0.55em)
  #text(weight: "bold", fill: rgb("#b91c1c"))[#title]
  #v(0.2em)
]

#let exam-grading-title() = [
  #v(0.55em)
  #text(weight: "bold", fill: rgb("#1d4ed8"))[Barème de correction]
  #v(0.2em)
]

#let exam-solution-block(body) = [
  #v(0.75em)
  #block(width: 100%, inset: (left: 7mm))[
    #text(fill: rgb("#b91c1c"))[#body]
  ]
  #v(0.9em)
]

#let exam-grading-block(body) = [
  #v(0.6em)
  #block(width: 100%, inset: (left: 7mm))[
    #text(fill: rgb("#1d4ed8"))[#body]
  ]
  #v(1.15em)
]

#let exam-choice-mark(selected: false) = {
  if selected {
    [#box(width: 1.35em, height: 1.15em, align(center + horizon)[#text(size: 15pt)[◉]])]
  } else {
    [#box(width: 1.35em, height: 1.15em, align(center + horizon)[#text(size: 15pt)[○]])]
  }
}

#let exam-plot-area(height: 12cm) = [
  #v(0.4em)
  #block(width: 100%, height: height, stroke: 0.45pt + rgb("#777777"), inset: 0pt)[
    #place(top + center)[#text(size: 8pt, fill: rgb("#666666"))[Espace pour graphique]]
  ]
]

#let exam-table-area(rows: 10) = [
  #v(0.4em)
  #table(
    columns: (1fr,),
    stroke: 0.35pt + rgb("#999999"),
    inset: 3pt,
    ..range(rows).map(_ => [#v(0.85em)])
  )
]

#let exam-table-area-fill() = [
  #v(0.4em)
  #block(width: 100%, height: 1fr, clip: true)[
    #table(
      columns: (1fr,),
      stroke: 0.35pt + rgb("#999999"),
      inset: 3pt,
      ..range(60).map(_ => [#v(0.85em)])
    )
  ]
]

#let exam-lined-area(lines: 24) = [
  #for i in range(lines) [
    #line(length: 100%, stroke: 0.35pt + rgb("#999999"))
    #v(0.85em)
  ]
]

#let exam-lined-area-fill() = [
  #block(width: 100%, height: 1fr, clip: true)[
    #for i in range(60) [
      #line(length: 100%, stroke: 0.35pt + rgb("#999999"))
      #v(0.85em)
    ]
  ]
]

#let exam-extra-work-page(kind: "blank") = [
  #pagebreak()
  #align(center)[#text(weight: "bold")[ESPACE ADDITIONNEL]]
  #v(5mm)
  #if kind == "lines" [
    #exam-lined-area-fill()
  ] else [
    #block(width: 100%, stroke: 0.45pt + rgb("#777777"))[#v(1fr)]
  ]
]
