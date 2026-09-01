# tarifr

Package R local minimal pour les fonctions reutilisables du site de cours ACT-4105 / ACT-6006.

## Installation locale

Depuis la racine du depot :

```r
source("scripts/install-tarifr.R")
install_tarifr()
```

Relancer `install_tarifr()` apres toute modification du code dans `tarifr/R/` qui doit etre visible pendant un rendu Quarto.

## Usage dans les documents Quarto

Les documents Quarto supposent que le package est deja installe. Charger le package dans un chunk cache, puis appeler les fonctions exportees avec leur namespace :

```r
library(tarifr)
tarifr::rate_level_diagram(
  start_date = "2014-01-01",
  end_date = "2015-01-01",
  experience_period = "accident",
  period_months = 3,
  analyzed_start = "2014-10-01"
)
tarifr::rate_level_diagram(
  start_date = "2010-01-01",
  end_date = "2013-01-01",
  experience_period = "calendar",
  policies = data.frame(
    start = c("2010-10-01", "2011-01-01"),
    label = c("A", "B")
  ),
  show_date_labels = TRUE,
  hide_after_date = "2011-12-31",
  highlight_earned_start = "2011-01-01",
  highlight_earned_end = "2012-01-01"
)
tarifr::trend_period_diagram(
  experience_start = "2018-01-01",
  experience_end = "2019-01-01",
  prospective_start = "2021-01-01",
  experience_period_type = "calendar",
  trend_type = "premium"
)
```

## Tableaux Pandoc

`afficher_table()` est la couche R commune pour les tableaux des présentations. Elle produit une table pipe Pandoc, applique des formats français par indices de colonnes et peut mettre une ligne de total en gras. La géométrie RevealJS (largeur, retours d’en-têtes, scroll et CSS) reste exclusivement gérée par l’extension `smart-typst-tables` du site.

```r
tableau <- data.frame(
  Libellé = c("A", "Total"),
  Montant = c(1250, 1250),
  Ratio = c(0.151, 0.151)
)

tarifr::afficher_table(
  tableau,
  align = c("l", "r", "r"),
  formats = list(
    list(colonnes = 2, type = "montant", symbole = TRUE),
    list(colonnes = 3, type = "pourcentage", digits = 1)
  ),
  lignes_gras = "derniere"
)
```

Garder les calculs par indices de colonnes et définir les données/calculs près de la première table qui les utilise. Pour un tableau unique, statique et sans calcul, préférer Markdown. Ne pas appeler `knitr::kable()` directement dans les chapitres.
