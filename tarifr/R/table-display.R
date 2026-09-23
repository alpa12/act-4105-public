#' Format Numbers for Course Tables
#'
#' Format numeric values with a French decimal mark and non-breaking digit
#' groups. Missing values remain blank so a table can use sparse cells.
#'
#' @param x Numeric values.
#' @param digits Number of decimal places.
#'
#' @return A character vector formatted for a Pandoc table.
#' @export
format_nombre <- function(x, digits = 2) {
  out <- rep("", length(x))
  present <- !is.na(x)

  out[present] <- formatC(
    as.numeric(x[present]),
    format = "f",
    digits = digits,
    big.mark = "\u00A0",
    decimal.mark = ","
  )
  out
}

#' Format Monetary Values for Course Tables
#'
#' @param x Numeric values.
#' @param digits Optional number of decimal places. When omitted, whole values
#'   have no decimal places and other values have two.
#' @param symbole Whether to append a non-breaking space and an escaped dollar
#'   symbol.
#'
#' @return A character vector formatted for a Pandoc table.
#' @export
format_montant <- function(x, digits = NULL, symbole = FALSE) {
  out <- rep("", length(x))
  present <- !is.na(x)

  out[present] <- vapply(x[present], function(value) {
    value_digits <- if (is.null(digits)) {
      if (isTRUE(all.equal(value, round(value)))) 0 else 2
    } else {
      digits
    }
    formatC(
      as.numeric(value),
      format = "f",
      digits = value_digits,
      big.mark = "\u00A0",
      decimal.mark = ","
    )
  }, character(1))

  if (symbole) {
    out[present] <- paste0(out[present], "\u00A0\\$")
  }
  out
}

#' Format Percentages for Course Tables
#'
#' @param x Numeric proportions.
#' @param digits Number of decimal places after converting to percent.
#' @param symbole Whether to append a non-breaking space and percent sign.
#'
#' @return A character vector formatted for a Pandoc table.
#' @export
format_pourcentage <- function(x, digits = 1, symbole = TRUE) {
  out <- format_nombre(x * 100, digits = digits)
  present <- !is.na(x)
  if (symbole) {
    out[present] <- paste0(out[present], "\u00A0%")
  }
  out
}

normaliser_format_table <- function(format, n_colonnes) {
  if (!is.list(format) || is.null(format$colonnes) || is.null(format$type)) {
    stop("Chaque format doit définir `colonnes` et `type`.", call. = FALSE)
  }

  colonnes <- as.integer(format$colonnes)
  if (!length(colonnes) || anyNA(colonnes) || any(colonnes < 1 | colonnes > n_colonnes)) {
    stop("`colonnes` doit contenir des indices de colonnes valides.", call. = FALSE)
  }

  type <- match.arg(format$type, c("nombre", "montant", "pourcentage"))
  list(
    colonnes = colonnes,
    type = type,
    digits = format$digits,
    symbole = format$symbole
  )
}

appliquer_format_table <- function(tableau, format) {
  format <- normaliser_format_table(format, ncol(tableau))
  digits <- format$digits
  symbole <- format$symbole

  for (colonne in format$colonnes) {
    valeurs <- tableau[[colonne]]
    tableau[[colonne]] <- switch(
      format$type,
      nombre = format_nombre(valeurs, digits = digits %||% 2),
      montant = format_montant(valeurs, digits = digits, symbole = symbole %||% FALSE),
      pourcentage = format_pourcentage(valeurs, digits = digits %||% 1, symbole = symbole %||% TRUE)
    )
  }
  tableau
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

mettre_en_gras <- function(tableau, lignes) {
  if (identical(lignes, "derniere")) {
    lignes <- nrow(tableau)
  }

  lignes <- as.integer(lignes)
  if (anyNA(lignes) || any(lignes < 1 | lignes > nrow(tableau))) {
    stop("`lignes_gras` doit contenir des indices de lignes valides.", call. = FALSE)
  }

  for (ligne in lignes) {
    valeurs <- as.character(tableau[ligne, , drop = FALSE])
    tableau[ligne, ] <- lapply(valeurs, function(valeur) {
      if (is.na(valeur) || identical(valeur, "")) "" else paste0("**", valeur, "**")
    })
  }
  tableau
}

normaliser_entetes_groupes <- function(entetes_groupes, n_colonnes) {
  if (is.null(entetes_groupes)) {
    return(list())
  }
  if (!is.list(entetes_groupes)) {
    stop("`entetes_groupes` doit être une liste.", call. = FALSE)
  }

  colonnes_utilisees <- integer()
  groupes <- lapply(entetes_groupes, function(groupe) {
    if (!is.list(groupe) || is.null(groupe$label) || is.null(groupe$colonnes)) {
      stop(
        "Chaque en-tête groupé doit définir `label` et `colonnes`.",
        call. = FALSE
      )
    }

    label <- as.character(groupe$label)
    colonnes <- as.integer(groupe$colonnes)
    if (length(label) != 1L || is.na(label) || !nzchar(label)) {
      stop("Le libellé d'un en-tête groupé doit être une chaîne non vide.", call. = FALSE)
    }
    if (
      length(colonnes) < 2L || anyNA(colonnes) || any(colonnes < 1L) ||
        any(colonnes > n_colonnes) || !identical(colonnes, sort(unique(colonnes))) ||
        any(diff(colonnes) != 1L)
    ) {
      stop(
        "Les colonnes d'un en-tête groupé doivent être contiguës, uniques et valides.",
        call. = FALSE
      )
    }
    if (length(intersect(colonnes_utilisees, colonnes)) > 0L) {
      stop("Les en-têtes groupés ne peuvent pas se chevaucher.", call. = FALSE)
    }
    colonnes_utilisees <<- c(colonnes_utilisees, colonnes)

    list(label = label, colonnes = colonnes)
  })

  groupes[order(vapply(groupes, function(groupe) groupe$colonnes[[1]], integer(1)))]
}

bordure_table_grille <- function(largeurs, caractere = "-") {
  paste0("+", paste(strrep(caractere, largeurs + 2L), collapse = "+"), "+")
}

cellule_table_grille <- function(texte, largeur, alignement = "l") {
  texte <- gsub("\\n", " ", as.character(texte))
  texte[is.na(texte)] <- ""
  texte <- gsub("|", "\\\\|", texte, fixed = TRUE)
  espace <- max(largeur - nchar(texte), 0L)

  if (alignement == "r") {
    # In a Pandoc grid-table cell, four leading spaces turn a short value
    # such as `0 \$` into a code block. Smart tables infer the final numeric
    # alignment, so preserve the grid width with trailing padding instead.
    paste0(texte, strrep(" ", espace))
  } else if (alignement == "c") {
    gauche <- floor(espace / 2)
    paste0(strrep(" ", gauche), texte, strrep(" ", espace - gauche))
  } else {
    paste0(texte, strrep(" ", espace))
  }
}

normaliser_entetes_calculs <- function(entetes_calculs, n_colonnes) {
  if (is.null(entetes_calculs)) {
    return(NULL)
  }
  if (!is.character(entetes_calculs) || length(entetes_calculs) != n_colonnes || anyNA(entetes_calculs)) {
    stop(
      "`entetes_calculs` doit être un vecteur de chaînes non manquantes, une par colonne.",
      call. = FALSE
    )
  }
  unname(entetes_calculs)
}

echapper_entete_calcul <- function(texte) {
  # In a Pandoc grid-table cell, a leading `(1)` becomes an ordered list.
  # Escape only that opening parenthesis so every output target receives the
  # author-facing calculation text, including Typst when smart tables are off.
  sub("^\\(", "\\\\(", texte)
}

table_grille_entetes <- function(tableau, align, entetes_groupes, entetes_calculs = NULL) {
  noms <- names(tableau)
  contenu <- as.data.frame(lapply(tableau, as.character), check.names = FALSE)
  names(contenu) <- noms
  contenu[is.na(contenu)] <- ""
  n_colonnes <- ncol(contenu)
  alignements <- rep_len(align, n_colonnes)
  alignements[!(alignements %in% c("l", "r", "c"))] <- "l"

  largeurs <- vapply(seq_len(n_colonnes), function(colonne) {
    max(
      3L,
      nchar(noms[[colonne]]),
      nchar(contenu[[colonne]]),
      if (is.null(entetes_calculs)) 0L else nchar(echapper_entete_calcul(entetes_calculs[[colonne]]))
    )
  }, integer(1))
  for (groupe in entetes_groupes) {
    largeur_groupe <- sum(largeurs[groupe$colonnes]) + 3L * (length(groupe$colonnes) - 1L)
    manque <- nchar(groupe$label) - largeur_groupe
    if (manque > 0L) {
      derniere_colonne <- groupe$colonnes[[length(groupe$colonnes)]]
      largeurs[[derniere_colonne]] <- largeurs[[derniere_colonne]] + manque
    }
  }

  groupes_par_depart <- setNames(
    seq_along(entetes_groupes),
    vapply(
      entetes_groupes,
      function(groupe) as.character(groupe$colonnes[[1]]),
      character(1)
    )
  )
  cellules_groupe <- character()
  colonne <- 1L
  while (colonne <= n_colonnes) {
    index_groupe <- groupes_par_depart[as.character(colonne)]
    if (!is.na(index_groupe)) {
      groupe <- entetes_groupes[[index_groupe]]
      largeur <- sum(largeurs[groupe$colonnes]) + 3L * (length(groupe$colonnes) - 1L)
      cellules_groupe <- c(cellules_groupe, cellule_table_grille(groupe$label, largeur, "l"))
      colonne <- max(groupe$colonnes) + 1L
    } else {
      cellules_groupe <- c(cellules_groupe, cellule_table_grille("", largeurs[[colonne]]))
      colonne <- colonne + 1L
    }
  }

  lignes <- bordure_table_grille(largeurs)
  if (length(entetes_groupes)) {
    lignes <- c(
      lignes,
      paste0("| ", paste(cellules_groupe, collapse = " | "), " |"),
      bordure_table_grille(largeurs)
    )
  }
  cellules_entete <- vapply(seq_len(n_colonnes), function(colonne) {
    cellule_table_grille(noms[[colonne]], largeurs[[colonne]], "l")
  }, character(1))
  lignes <- c(
    lignes,
    paste0("| ", paste(cellules_entete, collapse = " | "), " |")
  )

  if (!is.null(entetes_calculs)) {
    cellules_calculs <- vapply(seq_len(n_colonnes), function(colonne) {
      # Keep calculation references as literal text in every Pandoc output.
      cellule_table_grille(
        echapper_entete_calcul(entetes_calculs[[colonne]]),
        largeurs[[colonne]],
        "l"
      )
    }, character(1))
    lignes <- c(
      lignes,
      bordure_table_grille(largeurs),
      paste0("| ", paste(cellules_calculs, collapse = " | "), " |")
    )
  }
  lignes <- c(lignes, bordure_table_grille(largeurs, "="))

  for (ligne in seq_len(nrow(contenu))) {
    cellules <- vapply(seq_len(n_colonnes), function(colonne) {
      cellule_table_grille(contenu[[colonne]][[ligne]], largeurs[[colonne]], alignements[[colonne]])
    }, character(1))
    lignes <- c(
      lignes,
      paste0("| ", paste(cellules, collapse = " | "), " |"),
      bordure_table_grille(largeurs)
    )
  }

  sortie <- paste(lignes, collapse = "\n")
  if (!is.null(entetes_calculs)) {
    sortie <- paste(
      '::: {.tableau-colonnes-calculees smart-tables-header-roles="labels,calculations"}',
      sortie,
      ":::",
      sep = "\n"
    )
    return(knitr::asis_output(sortie))
  }

  structure(
    sortie,
    class = "knitr_kable",
    format = "pipe"
  )
}

#' Render a Course Table as Native Pandoc Markdown
#'
#' Apply semantic display formats to indexed columns, optionally emphasize
#' rows, and emit a native Pandoc pipe table. The site-wide
#' `smart-typst-tables` extension owns all table geometry and RevealJS styling.
#'
#' @param tableau A data frame or matrix containing table content.
#' @param align Explicit Pandoc alignments, one per column.
#' @param formats A list of format specifications. Each specification contains
#'   `colonnes`, numeric column indices, and `type`, one of `"nombre"`,
#'   `"montant"`, or `"pourcentage"`; it may also set `digits` and `symbole`.
#' @param lignes_gras Numeric row indices or `"derniere"`.
#' @param escape Whether `knitr::kable()` should escape Markdown in values.
#' @param entetes_groupes Optional list of grouped headers. Each element must
#'   contain a `label` and contiguous `colonnes`, for example
#'   `list(list(label = "Ratios", colonnes = 2:4))`.
#' @param entetes_calculs Optional character vector with one visible calculation
#'   label per column. When supplied, the table uses two semantic header rows:
#'   the data-frame names (`labels`) and these free-text labels
#'   (`calculations`). For example,
#'   `c("(1)", "(2)", "(3) = (1) + (2)")`.
#'
#' @return Invisibly, the generated Pandoc pipe table.
#' @export
afficher_table <- function(tableau,
                            align,
                            formats = list(),
                            lignes_gras = integer(),
                            escape = FALSE,
                            entetes_groupes = NULL,
                            entetes_calculs = NULL) {
  tableau <- as.data.frame(tableau, check.names = FALSE, stringsAsFactors = FALSE)
  rownames(tableau) <- NULL

  if (length(align) != ncol(tableau)) {
    stop("`align` doit contenir un alignement pour chaque colonne.", call. = FALSE)
  }

  for (format in formats) {
    tableau <- appliquer_format_table(tableau, format)
  }
  if (length(lignes_gras)) {
    tableau <- mettre_en_gras(tableau, lignes_gras)
  }

  entetes_groupes <- normaliser_entetes_groupes(entetes_groupes, ncol(tableau))
  entetes_calculs <- normaliser_entetes_calculs(entetes_calculs, ncol(tableau))

  if (length(entetes_groupes) || !is.null(entetes_calculs)) {
    table_grille_entetes(tableau, align, entetes_groupes, entetes_calculs)
  } else {
    knitr::kable(tableau, format = "pipe", align = align, escape = escape)
  }
}
