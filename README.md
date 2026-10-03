# ACT-4105 / ACT-6006

Preuve de concept d’un site Quarto pour les cours universitaires de tarification en assurance IARD.

## Licences et droits

Le dépôt applique des licences distinctes selon la nature des fichiers :

- Le code source original est sous [licence MIT](LICENSE-CODE), notamment `tarifr/`, les scripts, filtres Lua, CSS et JavaScript originaux.
- Le contenu pédagogique original dont Alexandre Parent détient les droits est sous [CC BY-SA 4.0](LICENSE-CONTENT.md).
- Le matériel tiers, les médias non documentés et les contenus adaptés ne sont couverts par aucune de ces licences; consulter [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Les licences ne s’étendent pas automatiquement au matériel tiers, adapté ou dont les droits ne sont pas établis.

## Orientation du dépôt

- `site/` est le projet Quarto; `site/_quarto.yml` en porte la configuration globale.
- `site/cours/` contient les pages de séance et `site/chapitres/` les notes (`diapos.qmd`) et exercices (`exercices.qmd`).
- `site/vieux-materiel/` conserve les PDF, PPTX et autres sources historiques.
- `site/filters/`, `site/includes/` et `site/styles/` portent les comportements et styles partagés; `site/_extensions/` est du code vendorisé immuable.
- `tarifr/` est le package R local des aides réutilisables.
- `site/_site/` et les PDF de sortie sont générés : modifier les sources, jamais ces sorties.

Les conventions d’implémentation sont centralisées dans le skill local :

- [architecture du site](.agents/skills/act-4105-course-site/references/site-architecture.md);
- [présentations RevealJS](.agents/skills/act-4105-course-site/references/revealjs-presentations.md);
- [package `tarifr` et tableaux R](.agents/skills/act-4105-course-site/references/tarifr-package.md);
- [conversion de notes](.agents/skills/act-4105-course-site/references/legacy-diapos-conversion.md) et [d’exercices](.agents/skills/act-4105-course-site/references/exercises-conversion.md).

## Conversion PDF vers Quarto

Pour des notes, utiliser le PPTX local comme source principale lorsqu’il existe et le PDF comme rendu de comparaison. Conserver l’ordre et le contenu pédagogique, transcrire les formules en LaTeX et préférer les structures Quarto natives. Un chapitre précédent est une référence visuelle seulement lorsqu’il est pertinent au contenu converti; ne pas normaliser mécaniquement les autres chapitres.

Pour des exercices, conserver les seules questions et solutions dans des blocs Quarto. Après toute conversion ou révision matérielle, exécuter :

```bash
bash scripts/audit-exercices.sh
```

Les détails de structure, les omissions documentées et la validation des sources sont dans la [référence de conversion des exercices](.agents/skills/act-4105-course-site/references/exercises-conversion.md).

## Package R local

Le code R partagé va dans `tarifr/R/`; exporter seulement les fonctions requises par les documents Quarto. Les documents supposent `tarifr` installé et ne doivent ni l’installer ni appeler `pkgload::load_all()` pendant un rendu.

Pour les déploiements, `site/manifest.json` résout volontairement `tarifr/` depuis la branche `main` de `alpa12/act-4105-public`, sans SHA de commit. Un déploiement récupère donc la pointe courante de cette branche. À chaque changement de version dans `tarifr/DESCRIPTION`, mettre aussi à jour la version `tarifr` déclarée dans ce manifeste afin que Connect Cloud puisse résoudre le package.

Après une modification du package, depuis la racine du dépôt :

```r
source("scripts/install-tarifr.R")
install_tarifr()
```

## Rendu et vérification

Le projet requiert Quarto **1.10.17 ou une version ultérieure**. Employer systématiquement le wrapper, qui utilise le binaire disponible et le Sass local sans imposer de version exacte :

```bash
scripts/quarto render site
```

Pour un document précis :

```bash
scripts/quarto render site/chapitres/01-introduction/diapos.qmd
```

Le deck `site/chapitres/00-reference-typography/` est une régression interne versionnée, exclue du rendu et du déploiement normaux. Il couvre typographie, listes, équations, tableaux Markdown/R, en-têtes de calcul et cascade. Le rendre explicitement après une modification pertinente :

```bash
scripts/quarto render site/chapitres/00-reference-typography
```

Sa sortie interne est limitée à `site/_reference/chapitres/00-reference-typography/`, hors de l’arborescence publiée.

## Export des PDF

`scripts/render-pdfs` exporte les diapositives et exercices de tous les chapitres numériques, sauf le chapitre 00, ainsi que les diapositives de toutes les révisions vers `site/pdfs/`. Pour exporter une seule révision, employer son nom de dossier :

```bash
scripts/render-pdfs --revision revision-examen-1
```

`--revision` est incompatible avec `--chapter` et ne prend en charge que les diapositives. Utiliser `--type diapos` ou `--type exercices` pour limiter le type d’export; `--chapter 06` limite l’export à un chapitre.

## Validation RevealJS

Restaurer les dépendances R et Node avant un rendu complet si nécessaire :

```r
renv::restore()
```

```bash
npm ci
npm test
```

L’audit canonique couvre les chapitres 01 à 09, volontairement sans le deck 00 :

```bash
CSK_CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
scripts/audit-chapter-slides
```

Options utiles : `--chapter 06`, `--skip-render`, `--browser-only`, `--report FILE` et `--wait MS`. Voir [la référence RevealJS](.agents/skills/act-4105-course-site/references/revealjs-presentations.md) pour les critères, le rendu PDF et l’inspection visuelle.
