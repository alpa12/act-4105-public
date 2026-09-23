# ACT-4105 / ACT-6006

Preuve de concept d'un site Quarto pour un cours universitaire de tarification en assurance IARD.

## Licences et droits

Le dépôt applique des licences distinctes selon la nature des fichiers :

- Le code source original est sous [licence MIT](LICENSE-CODE), qui couvre
  notamment `tarifr/`, les scripts, filtres Lua, CSS et JavaScript originaux.
- Le contenu pédagogique original dont Alexandre Parent détient les droits est
  sous [CC BY-SA 4.0](LICENSE-CONTENT.md).
- Le matériel tiers, les médias non documentés et les contenus adaptés ne sont
  couverts par aucune de ces licences; consulter
  [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

En particulier, la licence MIT ne couvre pas automatiquement le contenu de
`site/`, et la licence CC BY-SA ne couvre pas les éléments tiers.

## Compréhension du dépôt

- `site/_quarto.yml` pilote le site web Quarto, les filtres Lua et le CSS global.
- `tarifr/` est un package R local minimal à la racine du dépôt pour les fonctions réutilisables utilisées par les documents Quarto.
- `site/cours/` contient les pages de séance comme `01.qmd`. Leur métadonnée `chapitres` est une liste d’objets `path`/ `title`, utilisée pour afficher les ressources de chaque chapitre; le `week-id` et `first-class-date` produisent la date de séance.
- `site/chapitres/` contient les contenus sources par chapitre. Les notes de cours converties depuis les PDF historiques doivent être nommées `diapos.qmd`; les exercices sont dans `exercices.qmd`.
- `site/vieux-materiel/` contient le matériel source historique complet: PDFs d'exercices dans `exercices/`, notes de cours PDF dans `diapos/pdf/`, présentations PowerPoint dans `diapos/pptx/`, et matériel complémentaire comme `solution-14.1-a.xlsx`.
- `site/filters/` contient la logique Pandoc/Lua qui transforme le balisage Quarto en HTML plus riche.
- `site/includes/` contient les injections HTML globales utiles quand le comportement doit s'appliquer apres le rendu Quarto.
- `site/_extensions/` contient du code vendorisé immuable utilisé par le site. Ne jamais le modifier localement : lorsqu’un changement est nécessaire, rédiger une demande précise au mainteneur (problème, comportement attendu, tests de régression, version publiée et notes de changement), puis intégrer seulement la version livrée.
- `site/styles/site.css` est la feuille de style canonique du site HTML; elle utilise les fichiers locaux Overpass versionnés dans `site/assets/vendor/overpass/`. `site.scss` reste un point d’entrée léger pour une éventuelle compilation SCSS.
- `site/_site/` contient le rendu généré et sert de vérification rapide, mais les changements doivent être faits dans les sources Quarto/Lua/CSS.
- `scripts/audit-exercices.sh` vérifie rapidement les fichiers d'exercices convertis depuis les PDF sources.
- La navbar définie dans `site/_quarto.yml` est l’unique navigation globale du site. Ses menus déroulants donnent accès aux séances, ainsi qu’aux notes et exercices de chaque chapitre.
- Le pied de page global identifie Alexandre Parent, l’année 2026 et précise que le site Brio officiel de l’Université Laval prévaut en cas de différence.

## Travail réalisé

- Ajout du rendu automatique des blocs `::: {.diapos source="..."}` vers un iframe RevealJS responsive, sans modifier le contenu des fichiers `.qmd`.
- Conversion des chemins de diapos de `.qmd` vers `.html` dans l'iframe pour pointer vers la sortie réellement rendue.
- Mise à jour du filtre d'exercices pour normaliser les classes de `question` et `grading` sans modifier le contenu source.
- Ajout d'une injection HTML globale qui replie chaque couple `solution` + `grading` dans un seul bloc après le rendu final, car Quarto convertit les solutions en `proof` tard dans la chaîne de transformation.
- Ajout d'une numérotation automatique des questions d'exercices selon la profondeur d'imbrication: `1.`, `a)`, `i)`, puis répétition du motif pour les niveaux suivants.
- Ajout d'une injection HTML globale qui ouvre les liens vers les présentations RevealJS dans un onglet ou une fenêtre séparée.
- Ajout d’un mode d’étude optionnel pour les pages HTML d’exercices, avec une vue 45/55 et des notes RevealJS chargées seulement à la demande sur ordinateur.
- Ajout d'un style plus clair pour les questions, sous-questions, solutions, barèmes et cadres d'iframe.
- Simplification de la navigation globale autour de la navbar.
- Création d'un skill local de continuité pour les prochains agents dans `.agents/skills/act-4105-course-site/`.

## Conventions de développement

- Ne pas modifier le contenu pédagogique des `.qmd` pour ajouter du comportement UI si un filtre Lua ou le CSS peut le faire proprement.
- Si Quarto réécrit un bloc tard dans le pipeline et empêche un filtre Lua simple de suffire, utiliser `site/includes/` pour une petite transformation DOM ciblée plutôt que de modifier les `.qmd`.
- Préférer les extensions transversales dans `site/filters/` quand une feature doit s'appliquer à plusieurs cours ou chapitres.
- Les exercices imbriqués héritent automatiquement d'une numérotation par niveau via `site/includes/site-behavior.html`; conserver la structure `::: {.question}` imbriquée plutôt que d'écrire la numérotation manuellement dans les `.qmd`.
- `site/filters/exercise-study-view.lua` injecte les contrôles du mode d’étude uniquement dans les sorties HTML de `exercices.qmd`, ce qui garde les neuf sources pédagogiques et les PDF inchangés. `site/includes/exercise-study-mode.html` construit ensuite la grille 45/55, ne charge `diapos.html` qu’à l’activation de « Exercices et notes » sur un viewport de bureau, et active les contrôles RevealJS natifs dans cette iframe locale ; sous 992 px, les exercices restent seuls. Les présentations RevealJS ne sont pas modifiées.
- `site/filters/course-overview.lua` génère seulement en HTML le titre `Cours X : titre`, la date de séance et les liens vers les notes et exercices depuis `first-class-date`, `week-id` et `chapitres`. Les pages de cours ne contiennent donc pas d’iframe RevealJS.
- La métadonnée `label` sert de libellé court pour la navigation et les listings; garder `title` pour le titre complet et `description` pour le résumé long.
- La navbar configurée dans `site/_quarto.yml` est l’unique navigation globale du site. Les pages de cours et de chapitres restent accessibles depuis les liens de contenu et les embeddings de diapos.
- `site/_quarto.yml` limite le rendu direct aux fichiers `.qmd`; les templates `*.ejs.md` servent aux listings et ne doivent pas etre rendus comme pages autonomes.
- Vérifier les chemins relatifs du site rendu: les pages `cours/` embarquent des pages `chapitres/`, donc les liens d'iframe doivent viser les `.html` générés, pas les `.qmd`.
- Les exercices convertis depuis PDF commencent toujours par le YAML `metadata-files: ../_exercices.yml`, ne gardent que les questions et solutions, et n'ajoutent jamais de bloc `.grading`.
- Les notes de cours converties depuis les sources historiques sont des présentations RevealJS Quarto natives nommées `diapos.qmd`. Quand un `.pptx` est disponible, l'utiliser comme source principale pour la structure, le texte, les notes de présentateur et les visuels; utiliser le PDF comme rendu de comparaison. Remplacer entièrement les templates existants au besoin, reproduire fidèlement la structure des diapositives sources, corriger les erreurs manifestes, et éviter les ajustements de style dans le contenu.
- Pour les visuels issus des PPTX, privilégier le contenu natif Quarto lorsque le résultat reste facilement modifiable (Markdown, LaTeX, tableaux, Mermaid, colonnes, CSS simple). Si un visuel est trop complexe ou composé de nombreuses formes PowerPoint, utiliser une image extraite/exportée du PPTX peut être préférable. Tenter de conserver un fond transparent lorsque possible; si l'extraction transparente n'est pas fiable et qu'une capture opaque risque de nuire aux fonds de diapos, signaler le cas afin qu'une validation ou une image manuelle puisse être ajoutée.
- Les présentations RevealJS de chapitre sont alignées en haut par défaut via `site/chapitres/_diapos.yml` (`center: false`), tandis que la page titre conserve le centrage vertical par défaut. Pour centrer ponctuellement une slide de contenu, ajouter la classe `.center` au titre.
- Le styling RevealJS est organisé en couches. `site/styles/diapos.css` est le manifeste de base partagé par tous les decks et importe les fichiers de `site/styles/diapos/`. Les surcharges visuelles pour `clean-revealjs` vivent dans `site/styles/diapos-clean.css` et `site/styles/diapos-clean/`; les charger après la base et avant le CSS local du chapitre.
- La palette `clean-revealjs` du cours vit dans `site/styles/diapos-clean/variables.css` et utilise des accents inspirés de l'Université Laval: rouge pour l'accent principal, or pour les soulignements/repères secondaires, et bleu pour les états complémentaires.
- Les types de slides `clean-revealjs` (contenu pédagogique, exemple, solution et rappel) sont définis dans `site/styles/diapos-clean/variables.css`, puis appliqués dans `site/styles/diapos-clean/backgrounds.css`. Chaque type fournit un accent, deux tons de fond et une lueur: l’accent teinte à la fois le soulignement du `h2` et le fond extérieur de la slide active, sans modifier la card blanche. Pour ajouter un type, déclarer sa palette puis ses sélecteurs de slide et de stage dans ce dernier fichier.
- La couverture Quarto RevealJS utilise le langage visuel clair du gabarit Université Laval dans `site/styles/diapos-clean/title-pages.css` : fond gris perle, halos rouge et or et police Overpass. Le même fond est repris par `site/styles/diapos-clean/print.css` pour sa page PDF; les pages de titre de section `# Titre` conservent leur style standard. Les titres de section peuvent recevoir un sous-titre seulement avec l'attribut `subtitle`, par exemple `# Objectifs de la tarification {subtitle="Pourquoi le prix d'assurance est prospectif"}`. Le filtre `site/filters/revealjs-section-subtitle.lua` place ce sous-titre dans un bloc `.section-subtitle` adjacent au `h1`, afin que le texte du `h1` reste le titre principal utilisé par l'aperçu `progress-overview`. Ne pas utiliser ce mécanisme pour des labels, punchlines ou listes de mots-clés.
- Les titres `h2` RevealJS du thème `clean-revealjs` sont soulignés par `site/styles/diapos-clean/headings.css`. Comme `text-wrap: balance` peut produire des titres sur plusieurs lignes, `site/includes/revealjs-heading-underlines.html` mesure au rendu la ligne la plus longue de chaque titre et expose cette largeur dans `--act-heading-underline-width`; la barre de soulignement utilise cette variable au lieu de prendre toute la largeur du bloc.
- Les boutons flottants des extensions RevealJS sont regroupés au rendu par `site/includes/revealjs-extension-controls.html`, puis stylés dans `site/styles/diapos/extension-controls.css`. Les classes connues comme `.slide-menu-button` et `.slide-chalkboard-buttons` sont prises en charge automatiquement; pour une nouvelle extension locale, utiliser `.slide-extension-controls` ou l'attribut `data-act-extension-controls` sur le conteneur de boutons afin qu'il rejoigne le dock en bas à gauche.
- La taille de texte RevealJS par défaut est contrôlée dans `site/styles/diapos/text-scale.css`. Les classes `.text-*`, `.smaller` et `.text-scale` sont réservées aux ajustements manuels du responsable du cours : un agent ne doit jamais en ajouter sans demande explicite et doit laisser celles qui existent inchangées. Le corps est fixé à 28 px; `.text-xs`, `.text-smaller`, `.text-small`, `.text-medium`, `.text-large`, `.text-larger` et `.text-xl` forment une échelle à pas de 1,1 autour de `.text-medium`. `.smaller` reste un alias de `.text-smaller`. Les éléments de liste de premier niveau gardent la taille choisie, puis les sous-listes diminuent progressivement. Les équations affichées héritent directement de la taille de texte choisie; les tableaux utilisent 80 % de celle-ci. Ces classes fonctionnent autant sur le titre de slide (`## Titre {.text-large}`) que sur un bloc interne (`::: {.text-large} ... :::`): sur un titre, elles redimensionnent le contenu de la slide sans modifier les titres `h1` et `h2`; sur un bloc, elles redimensionnent seulement ce bloc. Les titres `h1` et `h2` partagent une taille fixe. Pour un ajustement précis du texte, ajouter `.text-scale` avec un paramètre `scale`, soit sur le titre, soit sur un bloc, par exemple `## Tableau long {.text-scale scale=0.84}` ou `::: {.text-scale scale=1.12} ... :::`. Le filtre `site/filters/revealjs-text-scale.lua`, référencé depuis `_diapos.yml` par `../../filters/revealjs-text-scale.lua`, transforme ce paramètre en variable CSS pour la slide ou le bloc selon l'emplacement.

  Pour ajuster un tableau seulement, l’envelopper dans un bloc portant la classe :

  ```markdown
  ::: {.text-large}
  | Année | Prime |
  | ----: | ----: |
  | 2025  | 1 250 |
  :::
  ```

  Le tableau reste à 80 % de la taille `.text-large`. Le deck de référence non publié `site/chapitres/00-reference-typography/diapos.qmd` permet de vérifier visuellement toutes les tailles après une modification CSS.
- Les équations affichées RevealJS héritent directement de la taille de texte choisie; elles ne reçoivent aucun facteur de réduction supplémentaire.
- Dans les équations RevealJS, utiliser `\textbf{...}` pour mettre du texte en gras. Éviter `\mathbf{\text{...}}`, qui ne s'applique pas de façon fiable au contenu placé dans `\text{...}`. Le thème `clean-revealjs` utilise MathJax 4 avec la police `mathjax-newcm`, car `mathjax-asana` rend certains caractères accentués, comme `û`, sans gras visible dans le texte mathématique.
- Le filtre partagé `site/filters/revealjs-english-subtitle.lua`, activé dans `site/chapitres/_diapos.yml`, ajoute les sous-titres anglais aux titres portant `.english-subtitle subtitle="..."`. Le filtre doit seulement transformer le balisage; l'apparence va dans le CSS.
- Dans une présentation RevealJS, utiliser `::: {.center}` pour centrer horizontalement un groupe de médias en ligne.
- Lors de la création d’une slide qui introduit des définitions, utiliser la syntaxe de liste de définitions Markdown (`**Terme**` puis `: Définition`). Ces listes sont stylées dans toutes les présentations RevealJS par `site/styles/diapos/definitions.css`; garder un terme anglais en italique seulement, par exemple `**Terme** *(Ang. : Term)*`.
- Les exemples dans les présentations RevealJS utilisent un bloc `:::: {.question title="Titre"}` pour l'énoncé et un sous-bloc `::: {.solution}` pour la solution. Le filtre partagé `site/filters/revealjs-exemples.lua`, activé avant `cascade` dans `site/chapitres/_diapos.yml`, transforme les titres `##` internes en `Exemple <order>.<n> - Titre` ou `Solution <order>.<n> - Titre`. Les `##` internes servent seulement à séparer les slides et à porter des classes comme `.text-smaller`; leur texte est ignoré. Pour répéter le titre généré sur une continuation, écrire simplement `---` dans l’énoncé ou la solution : l’extension `cascade` crée alors la slide et répète le titre. Ne jamais définir `name` dans une `.solution` : le préfiltre `site/filters/revealjs-example-solutions-pre.lua` marque automatiquement la solution avant la normalisation Quarto, puis le filtre d’exemples génère le titre visible. Le numéro de chapitre vient de la métadonnée `order`, avec repli sur le `_metadata.yml` du chapitre.
- L'espacement vertical interne des slides RevealJS est réglé dans `site/styles/diapos/foundations.css` avec `--act-slide-top-offset`. Quand un chapitre encadre ses slides avec une card, réserver l'espace au-dessus de la card avec `--act-card-top: calc(var(--rpb-reserved-top-space, ...) + ...)` dans le CSS local du chapitre afin de laisser la barre de progression et ses numéros hors de la card.
- Le cadrage des slides `clean-revealjs` vit dans `site/styles/diapos-clean/cards.css`, avec les variables de dimensions dans `site/styles/diapos-clean/variables.css`. Les paddings internes des cards doivent rester en unités stables liées au viewport ou à `rem`, pas en `em`, afin que les marges et l'alignement des titres ne changent pas quand une slide utilise `.text-*` ou `.title-*`. Ne pas forcer la hauteur des sections avec `!important`: RevealJS met temporairement la hauteur de la section à `auto` pour calculer les images `.r-stretch`, et un `height: ... !important` rend les images seules minuscules.
- Pour remplir exactement la surface d'une card RevealJS avec un média ou un bloc spécialisé, utiliser une slide `## {.card-fill}` contenant un bloc `::: {.card-fill-content}`. Les images, vidéos, iframes et canvas remplissent la card avec `object-fit: cover`; ajouter aussi `.card-contain` au titre pour conserver tout le média sans recadrage. Pour une légende visible sur le média, utiliser un bloc absolu avec `.card-fill-caption`.
- Les présentations RevealJS de chapitre utilisent l'extension `revealjs-progress-bar` via `site/chapitres/_diapos.yml`: garder `progress: false`, le filtre `revealjs-progress-bar` et les largeurs proportionnelles dans la configuration partagée. Chaque `diapos.qmd` devrait ajouter une slide `## Contenu du chapitre {.progress-overview}` au début du déroulé; les grandes sections suivantes doivent être des titres `#`, avec `data-progress-label="Court"` lorsque le titre complet est trop long pour la barre.
- Chaque titre de section RevealJS (`#`) doit porter `data-progress-label`, même lorsque le libellé court est identique au titre. Un libellé vide est permis pour une section très courte lorsque l’absence de texte améliore la barre de progression.
- Dans les listes des présentations, commencer chaque élément par une majuscule. Mettre un point à la fin d’un élément lorsqu’il forme une phrase complète ; ne pas mettre de point lorsqu’il s’agit d’un fragment. Ne pas terminer les éléments par un point-virgule.
- Un deck RevealJS hors chapitre qui hérite de la configuration de diapositives ajoute suppress-title-prefix: true à ses métadonnées pour retirer le repli Chapitre 0 :; le filtre partagé qui applique cette option suit title-prefix et laisse les titres de chapitres canoniques inchangés.
- Dans le texte français visible et les libellés de tableaux, employer des espaces insécables avant `:`, `;`, `?` et `!`, entre les groupes de chiffres et avant les unités ou symboles. Ne pas insérer ces espaces dans le code, les shortcodes ou le LaTeX.
- Garder une équation courte sur la ligne de sa phrase d'introduction lorsque cela reste lisible. Pour une formule affichée avec des termes complets et longs, employer un environnement aligné sur plusieurs lignes et commencer chaque terme par une majuscule. Rendre visibles les retours entre termes additifs ou soustractifs avec `\\` et `&+` ou `&-`; pour une fraction longue, utiliser un numérateur ou un dénominateur interne `gathered` ou `aligned`, plutôt que de seulement couper la ligne source.
- Dans un calcul d’exemple, afficher d’abord la formule symbolique, puis les substitutions numériques sur les lignes alignées suivantes. Garder les libellés français de la source, sans ajouter de transition comme « Ou, écrit autrement » lorsque les égalités alignées suffisent.
- Les présentations RevealJS de chapitre utilisent aussi l'extension `cascade` via `site/chapitres/_diapos.yml`. Pour plusieurs slides consécutives qui gardent le même titre, écrire le titre une seule fois puis séparer les continuations avec `---`; l'extension répète automatiquement le titre au rendu. Garder un nouveau titre explicite lorsque ses classes ou attributs changent, par exemple pour ajouter ou retirer `.english-subtitle`, `.text-small` ou un attribut de fond.
- L'extension locale `site/_extensions/alpa12/title-prefix`, activée dans `site/chapitres/_diapos.yml`, préfixe automatiquement le titre des présentations avec `Chapitre <order> :` sur une ligne séparée et numérote les sections `#` en `1. Titre`, `2. Titre`, etc. Ajouter `{.unnumbered}` à un titre de section, par exemple `# Section {.unnumbered}`, pour ne pas afficher de numéro et ne pas avancer le compteur. Le numéro de chapitre vient de la métadonnée `order`, avec repli sur le `_metadata.yml` du chapitre.
- Le filtre partagé `site/filters/chapter-pagetitle.lua` donne aux documents canoniques de chapitre un titre d’onglet et de PDF fondé sur leurs métadonnées brutes : `<order>. <label> - Notes` pour `diapos.qmd` et `<order>. <label> - Exercices` pour `exercices.qmd`. Les métadonnées partagées `_diapos.yml` et `_exercices.yml` suppriment le préfixe du site pour ces documents; le deck de référence le rétablit explicitement.
- Les présentations de chapitre utilisent `revealjs` avec la copie locale `site/styles/diapos-clean/clean-local.scss` et les CSS dans l'ordre `/styles/diapos.css`, `/styles/diapos-clean.css`, puis `diapos.css` si le chapitre a des styles locaux. L'extension vendorisée `grantmcdermott/clean` reste immuable; la copie locale supprime son import Google Fonts distant et utilise les fichiers Roboto versionnés dans `site/assets/vendor/roboto/`.
- Le mode d'export PDF des présentations `clean-revealjs` est stylé par `site/styles/diapos-clean/print.css`, importé en dernier par `site/styles/diapos-clean.css`, et préparé avant l'initialisation de RevealJS par `site/includes/revealjs-print-preflight.html`. Le filtre `site/filters/revealjs-print-overview.lua` insère aussi une liste statique source dans chaque slide `.progress-overview` avant l'extension `revealjs-progress-bar`. Le CSS d'impression cible seulement `html.reveal-print` et `html.print-pdf`: chaque slide imprimée devient une card blanche pleine page, sans fond extérieur, barre de progression, menu ou boutons d'extension. `pdf-separate-fragments` peut rester `true` pour imprimer une page par état de fragment, ou être mis à `false` localement pour imprimer l'état final. Pour produire un PDF reproductible, utiliser `scripts/revealjs-pdf site/chapitres/<chapitre>/diapos.qmd -o sortie.pdf`; le flux manuel reste possible via `site/_site/chapitres/<chapitre>/diapos.html?print-pdf`, en paysage avec marges nulles et graphiques d'arrière-plan activés.
- Pour exporter tous les PDF de chapitres depuis la racine du dépôt, lancer :

  ```bash
  scripts/render-pdfs
  ```

  Le script découvre les dossiers numériques, ignore le chapitre `00`, et exporte par défaut les présentations et les exercices corrigés. Utiliser `--chapter 06` pour un chapitre précis et `--type diapos` ou `--type exercices` pour un seul type de PDF. Les présentations sont écrites dans `site/pdfs/diapos/`; les exercices sont rendus au format `exam-typst` de l’extension `alpa12/exam`, avec la couverture et les instructions communes définies dans `site/instructions-exercices.qmd`, puis écrits dans `site/pdfs/exercices/`. Les solutions et les blocs `.grading` présents sont affichés, sans ajouter de bloc aux sources. Ces dossiers sont volontairement ignorés par Git.
- La configuration MathJax maintenue par le projet est unique : `site/mathjax-config.js`. Elle est publiée comme ressource de site et chargée par les pages HTML et les decks RevealJS; elle désactive l'explorateur d'expressions, conserve MathJax 4 et sert les assets `mathjax-newcm` localement. Les decks utilisent `html-math-method: mathjax`, désactivent le plugin RevealMathJS v2 avec `mathjax: false` et chargent le bundle MathJax 4 local explicitement; ne jamais revenir à `html-math-method: plain`, qui transforme certaines équations en texte. Ne jamais modifier les copies `mathjax-config.js` générées dans les sorties de chapitre.
- Dans les `diapos.qmd` des chapitres 4 et 5, nommer tous les chunks R avec `#| label:` pour garder les chunks de préparation et les graphiques faciles à suivre.
- Pour un comportement RevealJS ponctuel limité à une seule présentation, préférer un petit fichier CSS local au chapitre (par exemple `diapos.css`) ou un filtre Lua référencé seulement par ce `diapos.qmd` plutôt que d'étendre `site/filters/` ou le CSS global. Promouvoir vers `site/styles/diapos/` ou `site/styles/diapos-clean/` seulement lorsqu'un pattern revient dans plusieurs chapitres.
- Éviter les styles inline dans les `.qmd` et les filtres Lua; préférer des classes explicites et du CSS. Garder les `.qmd` comme contenu pédagogique propre.
- Dans le CSS Reveal partagé, ne pas détourner des classes internes génériques comme `.r-stretch`. Si un comportement d'image particulier est nécessaire, créer une classe dédiée explicite (par exemple `.compact-slide-image`) et l'appliquer seulement aux diapos concernées.
- Garder `auto-stretch: true` dans `site/chapitres/_diapos.yml`. Quarto ajoute alors `.r-stretch` à une image seule directement dans une slide et lui donne l'espace restant, ce qui écrase les dimensions d'affichage explicites (`width`, `out-width`, `out-height`). Pour préserver la dimension d'une image Markdown, utiliser la classe native Quarto `.nostretch`, par exemple `![](assets/image.png){.nostretch width=92%}`. Pour une figure produite par un chunk R, ajouter `.nostretch` au titre de la slide, par exemple `## Titre {.nostretch}`; ne pas créer de div ou classe wrapper uniquement pour désactiver cet automatisme. `fig-width` et `fig-height` déterminent les dimensions/proportions du graphique généré, tandis que `out-width` et `out-height` déterminent sa taille d'affichage lorsque l'étirement est désactivé.
- Le CSS Reveal partagé fixe les sorties knitr de RevealJS (`figure-revealjs/`) à la largeur intérieure de la card, avec `height: auto !important` pour conserver les proportions sans dépendre du calcul `.r-stretch` de RevealJS. Il ne faut donc pas ajouter de largeur de contournement (`out-width`, CSS local ou wrapper) uniquement pour éviter un dépassement horizontal; une largeur locale reste possible lorsqu'elle répond à un choix visuel précis.
- `smart-typst-tables`, activée dans `site/chapitres/_diapos.yml`, est l’unique couche de présentation structurelle des tableaux RevealJS : types, alignement final, largeur naturelle, retours d’en-têtes, classes `.smart-table`, défilement et géométrie. Ne pas la reproduire dans `tarifr`, un CSS local ou les `.qmd`; comme toute extension vendorisée, ne jamais modifier son code ou son CSS localement. Transmettre plutôt toute amélioration au mainteneur, puis intégrer sa version publiée. Exception : un seul séparateur vertical pédagogique peut être ajouté avec un sélecteur CSS limité à une classe de tableau locale, sans modifier la géométrie ni l’extension.
- Le thème `clean-revealjs` définit une seule fois l’apparence des en-têtes regroupés dans `site/styles/diapos-clean/content.css`, à partir des variables CSS publiques de `smart-typst-tables` : même dégradé que les en-têtes ordinaires, peint une seule fois sur tout le `thead`, séparateurs de groupe discrets uniquement à l’intérieur du tableau et trait entre les niveaux d’en-tête seulement sous une cellule de groupe fusionnée. Les conteneurs de tableaux n’ont pas d’ombre portée et les tableaux intelligents annulent la bordure grise inférieure du thème de base. Cette règle vise la classe générique des tableaux à en-têtes regroupés et ne doit pas être dupliquée dans un chapitre.
- Auditer les tableaux d’un chapitre avant leur conversion : garder un tableau court, unique et sans calcul en Markdown. Pour des données répétées ou des calculs entre colonnes, créer les données R juste avant la première table de la section et afficher chaque table avec `tarifr::afficher_table()`. Cette fonction est la seule couche R commune : elle produit une table Pandoc native et accepte `formats` par indices de colonnes (`nombre`, `montant`, `pourcentage`), `lignes_gras` et `entetes_groupes` pour des en-têtes regroupés. Pour un tableau dont des colonnes dépendent d’autres colonnes, utiliser aussi `entetes_calculs`, un vecteur de texte libre d’une valeur par colonne, par exemple `c("(1)", "(2)", "(3) = (1) + (2)")`. L’extension associe alors les deux rangées `labels` et `calculations`; ne pas créer cette structure à la main dans un `.qmd`. Reproduire fidèlement les en-têtes et les regroupements visibles dans la source, par exemple avec `list(list(label = "Ratios", colonnes = 2:4))`. Garder les calculs par indices de colonnes; réserver les noms visibles au renommage final. Dans un exemple à plusieurs sous-questions, réafficher les mêmes données à chaque étape et mettre en gras les valeurs utilisées. Dériver facteurs, projections et totaux de la table source plutôt que de créer une matrice de résultats indépendante, et afficher dans la question tout total nécessaire à la compréhension ou à la vérification du calcul. Les chunks de tables ont `#| label:` et `#| output: asis`; définir `execute.echo: false` dans les métadonnées quand cette option est commune au deck. Vérifier le HTML rendu pour `�`, `.smart-table` et l’absence de `.cell-output-display` autour des tables R.
- Pour placer ponctuellement une référence d'image visible dans une présentation RevealJS, utiliser le positionnement absolu natif de Quarto avec un bloc Markdown propre comme `::: {.absolute bottom=20 left=0 width="100%"}`. Ne pas imbriquer `::: {.aside}` dans `.absolute`: Quarto extrait les apartés du wrapper, ce qui laisse le bloc absolu vide. Éviter le CSS global qui modifie toutes les sections RevealJS.
- Réserver `.r-stack` aux superpositions de médias, notamment plusieurs images ou figures R. Chrome peut omettre à l'impression PDF le texte HTML, les callouts et les fragments `.absolute` imbriqués dans cette grille, même lorsque leur DOM est visible. Pour annoter une image, placer l'image `.nostretch` et les blocs Quarto natifs `.absolute.fragment` directement dans la diapositive; limiter les classes personnalisées à la sémantique visuelle et ne pas créer de wrapper propre à l'impression.
- Pour les dates qui doivent rester réutilisables d'une année à l'autre, utiliser l'extension locale `site/_extensions/alpa12/dynamic-year`, avec sa doc de référence dans `site/_extensions/alpa12/dynamic-year/.agents/skills/dynamic-year-user/SKILL.md`.
- Choisir `dynamic-date` pour toute date complète visible, en format `YYYY-MM-DD` et avec un offset entier seulement; réserver `dynamic-year` aux cas où seule l'année varie.
- Décider entre statique et dynamique selon le sens pédagogique: garder statiques les dates qui décrivent le document lui-même, les références bibliographiques et les faits historiques fixes; rendre dynamiques les dates d'exemple, les périodes de données, les dates d'effet, les dates de transaction et les dates d'évaluation qui doivent suivre l'année du cours.
- Fixer `base-year` dans `site/_quarto.yml`. Avec `base-year: 2026`, les exemples récents se situent souvent en 2024-2026, donc les offsets `-2`, `-1` et `0` sont fréquemment les bons.
- Pour les conversions d'exercices, utiliser d'abord les sources locales dans `site/vieux-materiel/exercices/`; consulter les notes correspondantes dans `site/vieux-materiel/diapos/pdf/` seulement pour lever une ambiguite ou confirmer le contexte.
- Normaliser les dates numériques du contenu rédigé au format `yyyy/mm/dd` pour éviter toute ambiguïté; par exemple, écrire `2013/07/01` pour le 1er juillet 2013.
- Pour les fonctions R réutilisables, préférer le package local `tarifr/` à la racine du dépôt plutôt que des scripts `source(...)` placés dans un chapitre.
- Dans les `.qmd`, supposer que `tarifr` est installé et le charger avec `library(tarifr)` dans un chunk caché. Ne pas installer ou charger le package avec `pkgload::load_all()` pendant un rendu Quarto.
- Utiliser `tarifr::trend_period_diagram()` pour illustrer les dates moyennes qui définissent une période de tendance; la fonction couvre les tendances en primes ou en sinistres et les bases année calendrier, année de police ou année d'accident.
- Utiliser `tarifr::two_step_trend_diagram()` pour une projection de primes en deux étapes; la fonction distingue l'expérience historique, le niveau courant et l'année de police prospective avec les deux facteurs de tendance correspondants.
- Utiliser `tarifr::rate_level_diagram()` pour les visuels de niveau de taux, niveau de bénéfice, changements requis par la loi, diagrammes de parallélogramme et schémas d'exposition avec lignes de polices individuelles. L'argument `experience_period` (`calendar`, `policy`, `accident`, `reporting`) détermine à la fois le préfixe (`AC`, `AA`, `AP`, `AR`) et la forme; seul `policy` produit des parallélogrammes, les autres périodes sont rectangulaires. Préciser `period_months = 12` pour les périodes annuelles et `period_months = 3` pour les périodes trimestrielles, avec `minor_grid_months = 1` au besoin pour montrer les repères mensuels et `analyzed_start`/`analyzed_end` pour encadrer la période analysée. Utiliser `policies`, `points`, `reference_lines` et `show_date_labels` pour reproduire les schémas d'exposition du chapitre 4. Tous les graphiques produits par cette fonction doivent conserver le même style visuel; ajuster la fonction elle-même plutôt que les appels dans les chapitres si le style doit changer. La page `site/chapitres/05-primes/test.qmd` documente les variantes principales de cette fonction et sert de page de validation visuelle. Si un type de visuel récurrent ne peut pas être représenté proprement avec les fonctions existantes, ajouter une fonction réutilisable dans `tarifr/R/` et l'exporter.
- Lorsqu'un élément du PDF source n'est volontairement pas recopié dans un `.qmd` d'exercices, ajouter un court commentaire HTML près du début du fichier pour expliquer l'omission.
- Pour les équations longues, privilégier une mise en forme sur plusieurs lignes dans le `.qmd`; `site/styles/site.css` fournit aussi un défilement horizontal de secours, seulement au besoin, dans les boîtes de questions ou de solutions.
- Garder ce `README.md` et le skill `.agents/skills/act-4105-course-site/SKILL.md` à jour à chaque modification structurelle ou fonctionnelle importante.

## Conversion PDF -> Quarto

### Notes de cours

Pour convertir des notes de cours historiques vers `site/chapitres/<chapitre>/diapos.qmd` :

1. Utiliser le `.pptx` local correspondant dans `site/vieux-materiel/diapos/pptx/` comme source principale lorsqu'il existe; utiliser le PDF dans `site/vieux-materiel/diapos/pdf/` comme rendu de référence.
2. Renommer l'ancien fichier de présentation en `diapos.qmd` si le chapitre utilise encore l'ancienne convention, puis mettre à jour `site/_quarto.yml` et les pages `site/cours/*.qmd` qui l'embarquent avec `::: {.diapos source="..."}`.
3. Remplacer entièrement les templates ou contenus fictifs par des diapositives RevealJS Quarto natives.
4. Reproduire le mieux possible les diapositives sources visibles en gardant l'ordre, les définitions, les exemples, les formules et les tableaux importants. Utiliser le chapitre immédiatement précédent comme modèle visuel et pédagogique. Ne pas intégrer les diapositives PowerPoint cachées ou marquées `NE PAS IMPRIMER` au déroulé principal, sauf demande explicite.
5. Ne pas inventer ni reformuler de nouveau texte visible sur les diapositives. Le texte visible doit être copié ou fidèlement transcrit depuis les diapositives sources, en préservant le gras et l’italique; le contenu des notes de présentateur doit aller dans `::: {.notes}`.
6. Corriger les erreurs manifestes de transcription, d'orthographe ou de notation, sans réécrire le cours inutilement.
7. Convertir les formules en LaTeX, les tableaux en tableaux Markdown, et les schémas simples en structures Quarto natives, par exemple Mermaid lorsque cela clarifie une chronologie ou une relation. Les notes de présentateur substantielles doivent aller dans des blocs Quarto `::: {.notes}`; ignorer les pieds de page répétés et les commentaires non pédagogiques.
8. Ne pas écrire de numérotation en dur dans les titres, sections, listes d'aperçu ou titres d'exemples (`Chapitre 1: ...`, `# I. ...`, listes numérotées, `Exemple 1.1`, etc.); utiliser des libellés descriptifs non numérotés pour permettre une numérotation programmatique plus tard.
9. Extraire les images utiles du PPTX dans un dossier d'assets local au chapitre, par exemple `site/chapitres/01-introduction/assets/`, puis les référencer avec des chemins relatifs depuis `diapos.qmd`.
10. Garder le contenu des diapos en Markdown propre et en syntaxe Quarto native. Ne pas utiliser de HTML brut dans les fichiers `diapos.qmd` pour régler des problèmes de rendu; corriger plutôt les comportements récurrents dans `site/styles/diapos.css` ou la configuration Quarto partagée.
11. Ne pas travailler le style visuel pendant la conversion; les choix de thème, de CSS et de mise en page fine doivent rester transversaux.
12. Rendre au minimum le fichier converti avec `quarto render site/chapitres/<chapitre>/diapos.qmd`.
13. Faire des commits par étapes significatives: renommage/navigation, conversion du contenu, puis documentation ou conventions.

### Exercices

Pour convertir un PDF d'exercices vers `site/chapitres/<chapitre>/exercices.qmd` :

1. Commencer le fichier avec :

```yaml
---
metadata-files:
  - ../_exercices.yml
---
```

2. Retirer tout ce qui n'est pas une question ou une solution : titre du PDF, "Exercices Chapitre X", "Solutions Chapitre X", en-tetes, pieds de page, numeros de page, notes generales.
3. Conserver uniquement la structure pedagogique en blocs Quarto :

```qmd
::: {.question}
Texte de la question.

::: {.solution}
Texte de la solution.
:::
:::
```

4. Utiliser des `::: {.question}` imbriques quand le PDF contient des sous-questions; la numerotation est ajoutee automatiquement par `site/includes/site-behavior.html`.
5. Ne jamais ajouter de bloc `.grading`.
6. Si une solution a besoin d'un schema ou d'un calcul R reutilisable, ajouter la fonction au package local `tarifr/`, relancer `install_tarifr()`, puis charger ce package dans un chunk cache du document Quarto.
7. Pour les PDF contenant des solutions sous forme d'images, ne pas se fier seulement a `pdftotext`; verifier visuellement les pages de solutions ou utiliser un OCR.
8. Apres une conversion ou une revision, lancer l'audit rapide :

```bash
bash scripts/audit-exercices.sh
```

Le script verifie notamment l'en-tete YAML, les titres/en-tetes PDF residuels, l'absence de blocs `.grading`, le nombre attendu d'exercices principaux pour les chapitres 1 a 7, et signale les PDF contenant des images.

## Package R Local

Le dépôt contient un package R minimal dans `tarifr/` pour centraliser les fonctions réutilisables du site.

- Mettre le code partagé dans `tarifr/R/`.
- Exporter seulement les fonctions qui doivent être appelées depuis les documents Quarto dans `tarifr/NAMESPACE`.
- Garder le package léger; il sert ici surtout à éviter les duplications de code entre chapitres.
- Les documents Quarto supposent que `tarifr` est installé dans la librairie R active. Ils ne doivent pas installer le package ni utiliser `pkgload::load_all()` pendant le rendu.
- Après une modification du code dans `tarifr/R/`, réinstaller le package local avant de relancer le rendu.
- Les fonctions `format_nombre()`, `format_montant()` et `format_pourcentage()` appliquent la convention française avec espaces insécables; `afficher_table()` les applique de façon déclarative aux positions de colonnes, aux en-têtes groupés et aux lignes en gras. Le package ne gère ni CSS ni largeur, ni wrapping, ni conteneurs de défilement.
- `afficher_table()` accepte aussi `entetes_calculs` pour une rangée de numéros ou de formules sous les titres. Pour ne pas couper cette rangée dans un tableau précis, entourer son chunk dans le `.qmd` d’un Div `.tableau-calculs-sur-une-ligne`; le conteneur défile horizontalement si le tableau devient alors plus large que la slide. L’extension intégrée `smart-typst-tables` 0.3 prend en charge `smart-tables-header-roles`; le feature request d’origine reste archivé dans `docs/smart-typst-tables-calculation-headers-request.md`.

Depuis la racine du dépôt :

```r
source("scripts/install-tarifr.R")
install_tarifr()
```

Exemple minimal dans un document Quarto :

```r
library(tarifr)
```

## Vérification rapide

Depuis la racine du dépôt:

```bash
quarto render site
```

Puis vérifier en particulier:

- `site/_site/cours/01.html`
- `site/_site/cours/02-cours.html`
- `site/_site/chapitres/01-introduction/exercices.html`
- `site/_site/chapitres/02-principes-tarif-cas/exercices.html`
- `site/_site/chapitres/05-primes/exercices.html`
- `site/_site/chapitres/06-sinistres/exercices.html`
- `site/_site/chapitres/07-autres-frais-et-profit/exercices.html`

## Validation des présentations RevealJS

### Environnement

Depuis la racine, restaurer les dépendances R et Node avant un rendu :

```r
renv::restore()
```

```bash
npm ci
```

Le projet requiert Quarto **1.10.17 ou une version ultérieure**. Le wrapper `scripts/quarto` utilise la version disponible et force le Sass local de `node_modules/.bin/sass` via `QUARTO_DART_SASS`; l’utiliser pour les rendus :

```bash
QUARTO_BIN=/chemin/vers/quarto scripts/quarto render site
```

Les modules RevealJS partagés sont dans `scripts/lib/revealjs/` : serveur statique sécurisé, client CDP, cycle de vie Chrome, navigation, parcours des états, impression et lecture PDF. `npm test` exécute leurs tests natifs `node:test`.

### Audit canonique

```bash
CSK_CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
QUARTO_BIN=/chemin/vers/quarto \
scripts/audit-chapter-slides
```

Sans option, l’audit découvre exactement les sources `site/chapitres/01-*/diapos.qmd` à `09-*/diapos.qmd`, rend chaque fichier avec `scripts/quarto render ... --no-cache`, puis contrôle les sources, le HTML et le navigateur à `1440×900` et `1024×768`. Le chapitre `00-reference-typography` est volontairement exclu : c’est le deck interne de régression typographique.

Options : `--chapter 06`, `--skip-render`, `--browser-only`, `--report FILE` et `--wait MS`. Le rapport synthétique est `docs/rapport-audit-presentations.md`; les logs CDP et captures brutes restent temporaires et ignorés. Un rapport vert signifie que les ressources locales, `chapter-css`, les décisions `fig-alt`, les attributs `alt`, MathJax, RevealJS, les CSS/scripts, les deux résolutions et les parcours horizontal/vertical/fragments ont passé les contrôles. Les liens pédagogiques externes ordinaires ne sont pas des ressources d’affichage requises.

Les sources (`.qmd`, Lua, CSS, includes et assets) sont les fichiers à modifier; `site/_site/` et les PDF de sortie sont générés. Les decks utilisent `chapter-css` local et le marqueur `data-act-chapter-css`; aucun CDN ne doit être requis pour l’affichage. Ne jamais éditer `site/_extensions/` ni `site/TODOs.md`.

### Chrome et export PDF

`CSK_CHROME` doit pointer vers l’exécutable Chrome/Chromium choisi. Pour exporter un deck :

```bash
CSK_CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
QUARTO_BIN=/chemin/vers/quarto \
scripts/revealjs-pdf site/chapitres/06-sinistres/diapos.qmd --out /tmp/chapitre-06.pdf
```

Le script rend la source, résout les actifs depuis `site/_site`, sert le HTML localement, prépare `print-pdf` et imprime via CDP. `scripts/render-pdfs` exporte par défaut les présentations et exercices de tous les chapitres numériques dans les répertoires ignorés `site/pdfs/diapos/` et `site/pdfs/exercices/`; ses options `--chapter` et `--type` limitent la sélection. Les présentations conservent un sommaire PDF navigable composé des titres H1 et H2 (les répétitions H2 consécutives sont regroupées). Lorsqu’un titre est coupé visuellement, l’export ajoute un séparateur de ligne invisible dans les métadonnées pour que Chrome conserve les espaces du signet. Les lignes de la diapositive imprimée « Contenu du chapitre » sont aussi des liens internes vers leurs sections H1. `scripts/revealjs-pdf` conserve son comportement par défaut; son option interne `--outline-h1-h2` active ce sommaire lorsque nécessaire. Vérifier taille, nombre de pages, dimensions paysage, pages-titres, vues d’ensemble, tableaux, formules, images, diapositives denses, liens du plan et signets PDF.
