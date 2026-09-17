test_that("French table values use protected spaces and expected symbols", {
  expect_identical(format_nombre(c(1234.5, NA_real_), digits = 1), c("1\u00A0234,5", ""))
  expect_identical(format_montant(c(1250, 12.5), symbole = TRUE), c("1\u00A0250\u00A0\\$", "12,50\u00A0\\$"))
  expect_identical(format_pourcentage(c(0.151, NA_real_)), c("15,1\u00A0%", ""))
})

test_that("afficher_table formats indexed columns and total rows", {
  tableau <- data.frame(
    Libelle = c("A", "Total"),
    Montant = c(1000, 1000),
    Ratio = c(0.125, 0.125),
    check.names = FALSE
  )
  names(tableau)[[1]] <- ""

  sortie <- paste(
    capture.output(
    afficher_table(
      tableau,
      align = c("l", "r", "r"),
      formats = list(
        list(colonnes = 2, type = "montant", symbole = TRUE),
        list(colonnes = 3, type = "pourcentage", digits = 1)
      ),
      lignes_gras = "derniere"
    )
    ),
    collapse = "\n"
  )

  expect_match(sortie, "1\u00A0000\u00A0\\$", fixed = TRUE)
  expect_match(sortie, "12,5\u00A0%", fixed = TRUE)
  expect_match(sortie, "**Total**", fixed = TRUE)
})

test_that("afficher_table never renders inherited row names", {
  tableau <- data.frame(Libelle = c("A", "B", "C"), Montant = c(1, 2, 3))

  sortie <- paste(
    capture.output(afficher_table(tableau[2:3, ], align = c("l", "r"))),
    collapse = "\n"
  )

  expect_false(grepl("^\\|[[:space:]]*2[[:space:]]*\\|", sortie, perl = TRUE))
})

test_that("afficher_table renders native grouped headers", {
  tableau <- data.frame(
    Libelle = c("A", "B"),
    Annee_1 = c(0.1, 0.2),
    Annee_2 = c(0.15, 0.25),
    Selection = c(0.2, 0.3),
    check.names = FALSE
  )
  names(tableau)[[1]] <- ""

  sortie <- paste(
    capture.output(
      afficher_table(
        tableau,
        align = c("l", "r", "r", "r"),
        formats = list(list(colonnes = 2:4, type = "pourcentage", digits = 1)),
        entetes_groupes = list(list(
          label = "Ratio des frais variables",
          colonnes = 2:4
        ))
      )
    ),
    collapse = "\n"
  )

  expect_match(sortie, "Ratio des frais variables", fixed = TRUE)
  expect_match(sortie, "Annee_1", fixed = TRUE)
  expect_match(sortie, "10,0\u00A0%", fixed = TRUE)
  expect_false(grepl('c\\("A", "B"', sortie))
})

test_that("grouped headers keep a zero monetary value as text", {
  tableau <- data.frame(
    Libelle = "Commissions",
    Annee_1 = 0,
    Annee_2 = 0,
    check.names = FALSE
  )
  names(tableau)[[1]] <- ""

  sortie <- paste(
    capture.output(
      afficher_table(
        tableau,
        align = c("l", "r", "r"),
        formats = list(list(colonnes = 2:3, type = "montant", symbole = TRUE)),
        entetes_groupes = list(list(label = "Frais fixes", colonnes = 2:3))
      )
    ),
    collapse = "\n"
  )

  expect_match(sortie, "| 0\u00A0\\$", fixed = TRUE)
  expect_false(grepl("\\| {4,}0\u00A0\\\\$", sortie, perl = TRUE))
})

test_that("afficher_table rejects invalid grouped headers", {
  tableau <- data.frame(A = 1, B = 2, C = 3)

  expect_error(
    afficher_table(
      tableau,
      align = c("l", "r", "r"),
      entetes_groupes = list(list(label = "Invalide", colonnes = c(2, 4)))
    ),
    "contiguës"
  )
})

test_that("afficher_table renders calculation headers as native Pandoc metadata", {
  tableau <- data.frame(
    Territoire = "1",
    Unites = 294,
    `Unités ajustées` = 295,
    check.names = FALSE
  )

  sortie <- afficher_table(
    tableau,
    align = c("l", "r", "r"),
    entetes_calculs = c("(1)", "(2)", "(3) = (1) + (2)")
  )

  expect_s3_class(sortie, "knit_asis")
  expect_match(
    sortie,
    '::: {.tableau-colonnes-calculees smart-tables-header-roles="labels,calculations"}',
    fixed = TRUE
  )
  expect_match(sortie, "| Territoire", fixed = TRUE)
  expect_match(sortie, "| (1)", fixed = TRUE)
  expect_false(grepl("\\| {4,}\\(1\\)", sortie, perl = TRUE))
  expect_match(sortie, "(3) = (1) + (2)", fixed = TRUE)
})

test_that("calculation headers can follow grouped headers", {
  tableau <- data.frame(
    Territoire = "1",
    Unites = 294,
    `Unités ajustées` = 295,
    check.names = FALSE
  )

  sortie <- afficher_table(
    tableau,
    align = c("l", "r", "r"),
    entetes_groupes = list(list(label = "Calcul", colonnes = 2:3)),
    entetes_calculs = c("(1)", "(2)", "(3) = (1) + (2)")
  )

  expect_match(sortie, "Calcul", fixed = TRUE)
  expect_match(sortie, "(3) = (1) + (2)", fixed = TRUE)
  expect_s3_class(sortie, "knit_asis")
})

test_that("afficher_table validates calculation headers", {
  tableau <- data.frame(A = 1, B = 2)

  expect_error(
    afficher_table(
      tableau,
      align = c("l", "r"),
      entetes_calculs = "(1)"
    ),
    "une par colonne"
  )
  expect_error(
    afficher_table(
      tableau,
      align = c("l", "r"),
      entetes_calculs = c("(1)", NA_character_)
    ),
    "non manquantes"
  )
})
