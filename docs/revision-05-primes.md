# Révision du chapitre 5 — Primes

## Portée

Révision des fichiers suivants :

- `site/pdfs/diapos/05-primes.pdf`
- `site/pdfs/exercices/05-primes.pdf`
- leurs sources `site/chapitres/05-primes/diapos.qmd` et `site/chapitres/05-primes/exercices.qmd`

## Correction appliquée

### Formule absente dans la solution de l’exercice 6

- Source : `site/chapitres/05-primes/exercices.qmd:447-454`.
- Problème : la formule était délimitée par `\[...\]`, syntaxe qui n’est pas rendue correctement par le profil `exam-typst`.
- Effet dans le PDF : la formule disparaissait et le texte `[]` apparaissait à la page 10.
- Correction : remplacement des délimiteurs `\[...\]` par `$$...$$`, en conservant le calcul et le résultat `330\,750`.

## Corrections appliquées

Les recommandations ci-dessous ont été appliquées dans les sources Quarto, puis vérifiées dans les PDF régénérés.

Les numéros de ligne indiqués dans les recommandations correspondent au relevé initial; les insertions effectuées depuis peuvent les avoir décalés.

### Français et formulation

1. Dans `diapos.qmd:363`, reformuler la définition des primes non acquises pour éviter l’accord ambigu, par exemple : « Montant total des primes que la compagnie n’a pas encore acquises et auquel les assurés ont droit en cas d’annulation… ».
2. Dans `diapos.qmd:427`, remplacer « le meilleur estimé de la distribution du portefeuille » par « la meilleure estimation de la distribution du portefeuille »
3. Remplacer les anglicismes « On assume », « La méthode assume » et « En assumant » par « On suppose », « La méthode suppose » et « En supposant » (`diapos.qmd:967`, `1585`, `1644`, `1669`).
4. Dans `diapos.qmd:985`, remplacer « un groupe de police » par « un groupe de polices ».
5. Dans `diapos.qmd:1870` et `1872`, ajouter l’article : « Le facteur de tendance est basé sur… ».
6. Dans `diapos.qmd:1587-1588`, ajouter un point après « de façon plus précise » afin d’éviter l’enchaînement « précise Les » dans le PDF.
7. Uniformiser les apostrophes typographiques dans `diapos.qmd`, notamment `d'ajuster`, `d'un` et `l'exemple`, avec les apostrophes courbes déjà utilisées ailleurs.

### Ponctuation des listes de diapositives

Le skill exige un point final pour les éléments qui sont des phrases complètes. Ajouter les points manquants, notamment dans les listes de `diapos.qmd:54`, `377-378`, `700-701`, `1119-1121`, `1585`, `1587-1590`, `1620-1621`, `1852` et `1869-1872`. Les éléments qui sont de simples fragments ou des étiquettes peuvent rester sans point.

### Typographie française

1. Dans `exercices.qmd`, remplacer les espaces ordinaires avant les deux-points par des espaces insécables dans les passages visibles, notamment aux lignes `16`, `49`, `66`, `133`, `186`, `192`, `194-196`, `303`, `343`, `409`, `435`, `461`, `489`, `497`, `544`, `587`, `602`, `616`, `631`, `654` et `678`.
2. Ajouter une espace insécable avant le symbole monétaire dans les passages visibles, notamment `500\$` (`exercices.qmd:472`) et `560\$` (`exercices.qmd:633`), ainsi que dans la question finale (`exercices.qmd:752`).
3. Grouper les nombres avec des espaces insécables dans les tableaux visibles des exercices, notamment `1100` (`exercices.qmd:465`), `10000`, `11500`, `14000` (`exercices.qmd:126-128`), `1000`, `1100`, `1200`, `1300` (`exercices.qmd:591-592`) et `10000`, `5000000`, `5250000`, `5512500` (`exercices.qmd:640-642`).

### Conformité au skill RevealJS

1. Dans `diapos.qmd:1877`, remplacer la traduction inline `_(ang. : current trend factor)_` par l’attribut de titre `{.english-subtitle subtitle="Current Trend Factor"}`.
2. Les diapositives qui introduisent explicitement une définition — notamment « Primes non acquises », « Primes en force » et la définition de la tendance dans les primes — devraient utiliser la syntaxe de liste de définitions Pandoc (`**Terme**` suivi de `: Définition`).

### Harmonisation entre les deux fichiers

Harmoniser le vocabulaire entre les notes et les exercices :

- privilégier « tendance dans les primes » et « facteur de tendance » comme termes français principaux, plutôt que l’alternance avec « premium trend » et « facteur de premium trend »;
- employer partout « méthode qui consiste à recalculer la prime pour chaque unité d’exposition » plutôt que l’alternance entre « pour chaque unité » et « pour toutes les unités »;
- conserver « mise au taux courant » comme terme français commun aux deux documents.

## Commentaire sur le travail effectué

Toutes les recommandations qui précèdent sont maintenant traitées.

- Dans `diapos.qmd`, les formulations françaises ont été corrigées : accord de « primes acquises », « meilleure estimation », « on suppose », « groupe de polices », ajout des articles manquants et uniformisation des apostrophes courbes.
- Dans `diapos.qmd`, les points finaux ont été ajoutés aux phrases complètes des listes indiquées dans le rapport. Les fragments et les étiquettes sont restés sans point, conformément au skill.
- Dans `diapos.qmd`, les trois introductions de définitions utilisent maintenant des listes de définitions Pandoc pour « Primes non acquises », « Primes en force » et « Tendance dans les primes ».
- La définition de « Primes en force » et son graphique ont été séparés par un saut de diapositive. Cette adaptation était nécessaire pour éviter qu’une liste de définitions ne surcharge la diapositive contenant le graphique et ne produise une page PDF vide.
- Le titre `Étape 1 : Facteur de tendance courante` utilise maintenant l’attribut `.english-subtitle subtitle="Current Trend Factor"` plutôt qu’une traduction inline.
- Dans `exercices.qmd`, les espaces insécables ont été ajoutées avant les deux-points et les symboles monétaires visibles. Les nombres des tableaux et des montants visibles ont été groupés avec des espaces insécables.
- Dans `exercices.qmd`, la formulation `méthode qui consiste à recalculer la prime pour chaque unité d’exposition` est utilisée partout où cette méthode est mentionnée. Les occurrences de `premium trend` ont été remplacées par le vocabulaire français « tendance dans les primes » ou « facteur de tendance ».
- Les formules mathématiques et le code R n’ont pas été modifiés uniquement pour y insérer des espaces typographiques, conformément au périmètre du skill.

## Vérifications

- Les calculs numériques contrôlés dans les deux documents sont cohérents.
- Les deux PDF ont été régénérés depuis leurs sources : le PDF de diapositives compte 100 pages et le PDF d’exercices 15 pages.
- L’audit Chrome du PDF de diapositives a de nouveau réussi aux résolutions 1440×900 et 1024×768 après les changements, sans erreur de rendu ni débordement détecté.
- Le PDF d’exercices a été régénéré avec le profil `exercices-pdf`; la formule de l’exercice 6 apparaît à la page 10 et `[]` est absent. Le contrôle visuel de cette page est réussi.
- `scripts/audit-exercices.sh` confirme 12 questions et 27 solutions pour le chapitre 5, mais signale que le PDF source historique `site/vieux-materiel/exercices/chap5-exercices.pdf` est absent.
- `git diff --check` ne signale aucune erreur.
