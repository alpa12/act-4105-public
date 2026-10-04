# Graphiques du site

Lire cette référence lorsqu’un graphique R/`ggplot2` est créé ou révisé dans une page du site, particulièrement dans `site/chapitres/*/diapos.qmd`. L’objectif est de préserver le sens pédagogique des figures du cours tout en réutilisant les conventions visuelles établies dans les chapitres récents.

## Intention pédagogique

- Comparer d’abord le message du graphique aux données ou au matériel historique. La ressemblance recherchée est une ressemblance de sens pédagogique, pas une copie esthétique pixel par pixel.
- Travailler un graphique à la fois et vérifier que chaque série, intervalle et barre répond à une question identifiable.
- Ne pas ajouter de décoration qui masque la relation importante. Les points, lignes, intervalles et expositions doivent rester lisibles à la taille d’une diapositive.
- Conserver les graphiques de référence déjà finalisés lorsqu’une demande vise seulement les graphiques suivants.
- Employer « stabilité » pour décrire la similarité des résultats d’une année à l’autre; éviter « consistance ».

## Code commun et intégration Quarto

Commencer par les helpers déjà définis dans le document ou dans le package local. Dans les présentations, les fonctions suivantes sont le modèle courant :

- `theme_act` pour le thème commun;
- `geom_exposition()` pour les barres d’exposition en arrière-plan;
- `axe_exposition()` pour l’axe secondaire;
- un petit thème local partagé, par exemple `theme_exemple_glm`, lorsqu’un groupe de graphiques doit utiliser une taille de texte réduite et une légende à droite.

Ne pas recopier une fonction de graphique dans plusieurs documents si le comportement est réellement générique. Si un helper devient utile dans plusieurs chapitres, l’ajouter à `tarifr/R/`, l’exporter et suivre les règles de [tarifr-package.md](tarifr-package.md). Pour une adaptation propre à un seul chapitre, conserver le code dans le chunk `setup` de ce chapitre.

Pour une présentation contenant plusieurs figures coûteuses, activer le cache au niveau YAML :

```yaml
execute:
  echo: false
  cache: true
```

Le cache accélère les rendus, mais ne remplace pas l’inspection des figures après une modification des données ou du style.

## Exposition

L’exposition doit être représentée par des barres en arrière-plan lorsqu’elle aide à interpréter la stabilité ou l’incertitude des relativités. Utiliser les valeurs absolues qui auraient un sens pour le modèle enseigné : nombre de polices, unités, véhicules, années-polices, etc. Éviter de présenter une exposition relative si l’objectif est d’enseigner un GLM de fréquence.

Utiliser un facteur uniquement pour projeter les valeurs absolues sur l’échelle principale et afficher les valeurs originales sur l’axe secondaire :

```r
geom_exposition(
  donnees,
  "groupe",
  "exposition",
  facteur = 0.00001,
  alpha = 0.6
) +
scale_y_continuous(
  sec.axis = axe_exposition(0.00001, "Exposition")
)
```

Le facteur doit garder les barres dans la zone utile du graphique. L’axe secondaire ne doit pas étirer inutilement l’axe principal. Une opacité d’environ `0.6` rend les barres visibles sans cacher les séries; l’ajuster si les barres et un ruban d’incertitude se superposent.

Pour une validation simulée, l’exposition d’un bucket doit être le nombre réel d’observations qui y sont tombées. Ne pas fabriquer manuellement une suite décroissante de volumes. Une distribution de prédictions et un échantillonnage avec `seed` doivent pouvoir produire naturellement de petits volumes, voire des buckets vides, dans la queue droite.

## Séries, couleurs et légendes

- Utiliser des lignes relativement fines, généralement autour de `linewidth = 0.5` à `0.65`, et des points autour de `size = 1.35` à `1.6`.
- Ajouter des points aux séries centrales. Dans un graphique avec incertitude, les bornes restent des lignes ou un ruban; ne pas ajouter un point à chaque borne.
- Placer les légendes à droite avec `theme(..., legend.position = "right")` lorsque le graphique en possède une. Supprimer la légende seulement lorsque les éléments sont explicitement identifiés par les titres ou les axes.
- Utiliser une palette lisible pour les personnes daltoniennes, par exemple :

```r
couleurs_annees <- c("#D55E00", "#009E73", "#0072B2", "#CC79A7")
formes_annees <- c(16, 17, 15, 18)
```

- Pour plusieurs années, préférer des lignes continues combinées à des couleurs et des formes de points distinctes. Ne pas dépendre de pointillés, tirets et autres motifs difficiles à suivre lorsque les lignes sont proches.
- Les lignes d’incertitude peuvent toutefois être pointillées ou tiretées lorsqu’elles doivent être distinguées de la série centrale. Cette exception est utile pour le style « bornes + ruban ».
- Dans une validation où les deux séries se recouvrent, tracer la série attendue/prédite bleue après la série historique afin que la ligne et les points bleus restent visibles au-dessus.

## Axes et graduations

Commencer sans `limits` ni `breaks` forcés. Observer les graduations par défaut avant de les contraindre; cela évite de couper une information ou d’étirer l’échelle sans nécessité.

Lorsque les graduations servent directement l’explication :

- utiliser principalement des intervalles de `0.25` pour des relativités ou des différentiels;
- utiliser environ `0.1` pour des fréquences de validation;
- afficher toutes les catégories lorsque leur nombre est raisonnable, par exemple les groupes de véhicule `1:17`;
- ne pas afficher chaque valeur d’une variable x continue si cela surcharge l’axe;
- avec un axe secondaire d’exposition, choisir le facteur de projection pour que les barres utilisent bien l’espace sans rendre l’échelle principale illisible.

Les libellés du projet privilégient « Groupe de véhicule » plutôt que « Groupe du véhicule ».

## Intervalles d’incertitude

Pour des bornes d’écarts-types ou d’intervalle de confiance, reprendre le style suivant :

- un ruban continu entre `borne_inf` et `borne_sup`;
- une zone de remplissage rouge très pâle, cohérente avec les lignes des bornes;
- deux lignes rouges pointillées ou tiretées pour les bornes;
- une série centrale bleue, continue, avec des points;
- une légende à droite distinguant la prédiction et les bornes.

Exemple de couches :

```r
geom_ribbon(
  aes(ymin = borne_inf, ymax = borne_sup, group = 1),
  fill = couleurs_act["rouge"],
  alpha = 0.08
) +
geom_line(
  aes(y = borne_inf, group = 1,
      colour = "Bornes à ±2 écarts-types",
      linetype = "Bornes à ±2 écarts-types"),
  linewidth = 0.5
) +
geom_line(
  aes(y = borne_sup, group = 1,
      colour = "Bornes à ±2 écarts-types",
      linetype = "Bornes à ±2 écarts-types"),
  linewidth = 0.5
) +
geom_line(
  aes(group = 1, colour = "Prédiction GLM", linetype = "Prédiction GLM"),
  linewidth = 0.5
) +
geom_point(aes(colour = "Prédiction GLM"), size = 1.35)
```

`geom_linerange()` convient à des intervalles ponctuels, mais il ne reproduit pas le message pédagogique d’un intervalle qui évolue entre les catégories. Ne pas transformer les lignes verticales d’un graphique de validation en barres d’incertitude si elles représentent en réalité une ligne reliant les observations.

Avec une variable x catégorielle, `geom_ribbon()` peut ne pas produire une zone visible correctement. Utiliser alors des positions numériques tout en conservant les libellés :

```r
donnees$position <- seq_len(nrow(donnees))

ggplot(donnees, aes(position, relativite)) +
  geom_ribbon(aes(ymin = borne_inf, ymax = borne_sup, group = 1), ...) +
  scale_x_continuous(
    breaks = donnees$position,
    labels = as.character(donnees$categorie)
  )
```

Cette approche est particulièrement importante lorsque les barres d’exposition occupent le même graphique.

## Graphique de stabilité annuelle

Les années doivent être dynamiques lorsque le graphique est réutilisé d’une année à l’autre. Charger l’extension `dynamic-year`, puis construire les années à partir de l’année de base :

```r
annees_stabilite <- vapply(-3:-1, dynamic_year, integer(1))
```

Utiliser trois séries annuelles qui arrivent aux trois années calculées. Les valeurs peuvent varier légèrement, mais doivent garder une tendance pédagogique similaire. Associer chaque année à une couleur et une forme de point; placer la légende à droite.

## Validation des fréquences prédites

Pour se rapprocher du graphique historique de validation, simuler un grand nombre d’observations individuelles avec une graine fixe :

1. générer une fréquence prédite individuelle dans une plage réaliste;
2. générer une fréquence historique individuelle binaire avec `rbinom(..., size = 1, prob = predite)`;
3. trier implicitement les observations par la prédiction et créer des buckets de largeur égale;
4. calculer, par bucket, la moyenne prédite, la moyenne historique et le nombre d’observations;
5. utiliser le nombre d’observations comme exposition absolue;
6. conserver les buckets vides avec une fréquence historique manquante plutôt que d’inventer une observation;
7. relier les fréquences historiques par une ligne et superposer les points; tracer ensuite la série attendue bleue et ses points pour qu’elle reste visible.

Le bruit historique doit être cohérent avec l’exposition : il est plus faible dans les buckets volumineux et plus grand dans les buckets ayant peu d’observations. Une queue de prédictions peu exposée peut donc contenir des fréquences historiques très variables, parfois nulles. Cette variabilité est le message pédagogique; ne pas la remplacer par des barres d’incertitude orange.

Utiliser une grille x adaptée à la fréquence, autour de `0.1`, et ne pas étiqueter chaque bucket continu. La diagonale ou la série attendue doit rester mince, et les légendes sont à droite si elles existent.

## Organisation pédagogique des exemples

Dans un exemple de présentation qui donne directement les résultats, utiliser un bloc `::: {.question}` sans bloc `.solution`. Mettre chaque test ou étape dans un titre de niveau 3, par exemple `### Écart-type`, `### Stabilité des résultats d’une année à l’autre`, `### Test statistique`, `### Jugement` et `### Décision`. Cela garde le contexte, le graphique et son interprétation dans le même exemple.

## Vérification

Après une modification de graphique :

1. exécuter `git diff --check`;
2. rendre le document source avec `scripts/quarto render site/chapitres/<chapitre>/diapos.qmd`;
3. inspecter visuellement les images générées, en particulier l’exposition, les points, les lignes, les rubans et les légendes;
4. vérifier que les axes ne sont ni inutilement étirés ni surchargés;
5. vérifier que les modifications restent dans les fichiers sources et ne reposent pas sur une édition de `site/_site/`.

Un échec Sass lié à macOS peut limiter la sortie finale, mais les chunks knitr exécutés et les images produites doivent tout de même être inspectés lorsque disponibles.
