# Important


# Génériques

## Fonctionnalités
- Soulignement des titres de plusieurs lignes en pdf, voir diapo 44 chap 1
- Améliorer l'interface des graphiques pour le chap 4 : Permettre des polices annulées, et simplifier "écrits" -> points, "acquis" -> ligne en gras, annulation -> x, etc.
- Bug dans les .exercices qui semble ignorer les classes...?! Essayer : 
  :::: {.question title="Base de données de polices"}

  ##

  Vous avez 3 polices dans votre base de données de polices :

  ::: {.tableau-polices smart-tables-width="full"} <-- en enlevant .tableau-polices

  | Police | Écriture | Prime annuelle | Territoire | Franchise |
  |:--|:--|--:|--:|--:|
  | A | {{< dynamic-date "YYYY-01-01" -2 >}} | 1 100 | 1 | 250 |
  | B | {{< dynamic-date "YYYY-04-01" -2 >}} | 600 | 2 | 250 |
  | C | {{< dynamic-date "YYYY-07-01" -2 >}} | 1 000 | 3 | 500 |

  :::
- Nom du document des exercices en pagetitle dans Acrobat (fonctionne dans Chrome)
    Oui. Le titre est bien présent dans le PDF d’exercices : pdfinfo et les métadonnées XMP indiquent 1. Introduction - Exercices.
    La différence vient du lecteur PDF, pas du contenu. Chrome utilise volontiers le champ de métadonnées Title pour son onglet. Acrobat, lui, affiche souvent le nom du fichier sauf si le PDF demande explicitement l’affichage du titre via la préférence PDF ViewerPreferences /DisplayDocTitle true (ou selon la préférence Acrobat « Afficher le titre du document dans la barre de titre »).
    Les notes et les exercices sont produits par deux moteurs différents :
    - Notes : Chrome/Skia.
    - Exercices : Typst.
    Le PDF Typst contient bien le titre, mais ses préférences de visualisation ne demandent pas à Acrobat de l’utiliser dans l’onglet; Acrobat retombe donc sur 01-introduction.pdf.
- Nice-to-have : Graphique temps vs % du terme expiré, mais on change l'axe des y pour "nombre d'unités acquises". Donc les lignes sont toujours à 45 degrés, mais elles coupent plus vite pour des polices de 6 mois, moins vite pour des polices de 2 ans.
- Nice-to-have : Fonctions pour calculer les unités et primes écrites/acquises en AC/AP et packager
- Est-ce que les exemples devraient être des titres niveaux 3?


# Prompts

## Nouvelles diapos

[$act-4105-course-site](/Users/alexandreparent/Documents/r-projects/act-4105/.agents/skills/act-4105-course-site/SKILL.md) Crée les diapos du chapitre 9 à partir de site/vieux-materiel/diapos/pdf/chap9-classification-traditionnelle-des-risques.pdf (et du pptx) en t'assurant de suivre les bonnes pratiques du projet (dans le skill). Utilise les diapos du chapitre 5, 6, 7 et 8 comme modèles, c'est les présentations les plus proches du résultat final désiré.

## Améliorations à faire

Fais toutes les améliorations suivantes aux diapos du chapitre 9 (les améliorations sont indiquées dans l'ordre des diapos, ça peut t'aider à te situer)