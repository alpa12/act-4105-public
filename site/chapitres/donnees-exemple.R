tableau_polices <- function(polices, colonne, nom_colonne) {
  valeur <- polices[[colonne]]
  affichage <- data.frame(
    "Police" = polices$label,
    "Date effective" = polices$start,
    "Date d’expiration" = polices$expiration,
    check.names = FALSE
  )
  affichage[[nom_colonne]] <- valeur
  affichage
}

tableau_primes <- function(polices, valeurs, entetes) {
  resultat <- data.frame(
    "Police" = polices$label,
    "Date effective" = polices$start,
    "Date d’expiration" = polices$expiration,
    "Prime" = polices$prime,
    check.names = FALSE
  )
  for (i in seq_along(entetes)) {
    resultat[[entetes[[i]]]] <- valeurs[, i]
  }
  total <- resultat[1, , drop = FALSE]
  total[1, ] <- ""
  total[[1]] <- "Total"
  total[[4]] <- sum(polices$prime)
  total[5:ncol(total)] <- as.list(colSums(valeurs))
  rbind(resultat, total)
}

tableau_unites <- function(
    polices,
    valeurs,
    entetes,
    nom_unite = "Unité d’exposition"
) {
  resultat <- data.frame(
    "Police" = polices$label,
    "Date effective" = polices$start,
    "Date d’expiration" = polices$expiration,
    check.names = FALSE
  )
  resultat[[nom_unite]] <- polices$unite
  for (i in seq_along(entetes)) {
    resultat[[entetes[[i]]]] <- valeurs[, i]
  }

  total <- resultat[1, , drop = FALSE]
  total[1, ] <- ""
  total[[1]] <- "Total"
  total[[4]] <- sum(polices$unite)
  total[5:ncol(total)] <- as.list(colSums(valeurs))
  rbind(resultat, total)
}

polices_annuelles <- data.frame(
  start = c(
    dynamic_date("YYYY-10-01", -2),
    dynamic_date("YYYY-01-01", -1),
    dynamic_date("YYYY-04-01", -1),
    dynamic_date("YYYY-07-01", -1),
    dynamic_date("YYYY-10-01", -1),
    dynamic_date("YYYY-01-01", 0)
  ),
  expiration = c(
    dynamic_date("YYYY-09-30", -1),
    dynamic_date("YYYY-12-31", -1),
    dynamic_date("YYYY-03-31", 0),
    dynamic_date("YYYY-06-30", 0),
    dynamic_date("YYYY-09-30", 0),
    dynamic_date("YYYY-12-31", 0)
  ),
  label = LETTERS[1:6],
  unite = 1
)

polices_semiannuelles <- transform(
  polices_annuelles,
  expiration = c(
    dynamic_date("YYYY-03-31", -1),
    dynamic_date("YYYY-06-30", -1),
    dynamic_date("YYYY-09-30", -1),
    dynamic_date("YYYY-12-31", -1),
    dynamic_date("YYYY-03-31", 0),
    dynamic_date("YYYY-06-30", 0)
  ),
  unite = 0.5
)

polices_primes <- data.frame(
  label = polices_annuelles$label,
  start = polices_annuelles$start,
  expiration = polices_annuelles$expiration,
  prime = c(200, 250, 300, 400, 350, 225)
)

unites_annuelles <- list(
  ac_ecrites = matrix(c(
    1, 0, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 0, 1
  ), ncol = 3, byrow = TRUE),
  ac_acquises = matrix(c(
    .25, .75, 0,
    0, 1, 0,
    0, .75, .25,
    0, .5, .5,
    0, .25, .75,
    0, 0, 1
  ), ncol = 3, byrow = TRUE),
  ap_ecrites = matrix(c(
    1, 0, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 0, 1
  ), ncol = 3, byrow = TRUE),
  ap_acquises = matrix(c(
    1, 0, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 0, 1
  ), ncol = 3, byrow = TRUE),
  en_force = matrix(c(
    1, 1, 0,
    1, 1, 0,
    0, 1, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1
  ), ncol = 3, byrow = TRUE)
)

unites_semiannuelles <- list(
  ac_ecrites = matrix(c(
    .5, 0, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, 0, .5
  ), ncol = 3, byrow = TRUE),
  ac_acquises = matrix(c(
    .25, .25, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, .25, .25,
    0, 0, .5
  ), ncol = 3, byrow = TRUE),
  ap_ecrites = matrix(c(
    .5, 0, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, 0, .5
  ), ncol = 3, byrow = TRUE),
  ap_acquises = matrix(c(
    .5, 0, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, .5, 0,
    0, 0, .5
  ), ncol = 3, byrow = TRUE),
  en_force = matrix(c(
    1, 0, 0,
    1, 1, 0,
    0, 1, 0,
    0, 0, 0,
    0, 0, 1,
    0, 0, 1
  ), ncol = 3, byrow = TRUE)
)

primes_exemple <- list(
  ac_ecrites = matrix(c(200, 0, 0, 0, 250, 0, 0, 300, 0, 0, 400, 0, 0, 350, 0, 0, 0, 225), ncol = 3, byrow = TRUE),
  ac_acquises = matrix(c(50, 150, 0, 0, 250, 0, 0, 225, 75, 0, 200, 200, 0, 87.5, 262.5, 0, 0, 225), ncol = 3, byrow = TRUE),
  ap_ecrites = matrix(c(200, 0, 0, 0, 250, 0, 0, 300, 0, 0, 400, 0, 0, 350, 0, 0, 0, 225), ncol = 3, byrow = TRUE),
  ap_acquises = matrix(c(200, 0, 0, 0, 250, 0, 0, 300, 0, 0, 400, 0, 0, 350, 0, 0, 0, 225), ncol = 3, byrow = TRUE),
  en_force = matrix(c(200, 200, 0, 250, 250, 0, 0, 300, 300, 0, 0, 400, 0, 0, 350, 0, 0, 225), ncol = 3, byrow = TRUE)
)

points_2011 <- data.frame(
  date = c(
    dynamic_date("YYYY-01-01", -1),
    dynamic_date("YYYY-04-01", -1),
    dynamic_date("YYYY-07-01", -1),
    dynamic_date("YYYY-10-01", -1)
  )
)

donnees_projection_une_etape <- data.frame(
  "Trimestre" = paste0(
    rep(vapply(-5:-3, dynamic_year, integer(1)), each = 4),
    " - T",
    rep(1:4, times = 3)
  ),
  "Primes écrites au taux courant" = c(
    323189.17, 328324.81, 333502.30, 338721.94,
    343666.70, 348696.47, 353027.03, 358098.58,
    361754.88, 367654.15, 372305.01, 377253.00
  ),
  "Unités écrites" = c(453, 458, 463, 468, 472, 477, 481, 485, 488, 493, 497, 501),
  check.names = FALSE
)

marge_schema_exposition <- c(3.8, 5.4, 2.2, 3.0)
