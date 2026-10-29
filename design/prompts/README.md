# UZME, prompts Claude Design

Un prompt par lot, à jouer dans l'ordre. Chaque fichier de lot est autonome :
il contient déjà le contexte marque, les tokens et les contraintes communes.
Tu donnes le fichier à Claude Design, rien d'autre à joindre.

`00-SYSTEME.md` est la source de ce contexte commun, gardée à part pour
pouvoir le modifier à un seul endroit. Si tu l'édites, relance l'injection
(voir "Maintenir le socle" en bas) pour propager dans tous les lots.

| Numéro | Lot | Écrans | Statut |
|---|---|---|---|
| 00 | Socle système | (aucun) | source du contexte, deja inclus dans chaque lot |
| 01 | Planches de fiche store (App Store et Play Store) | 5 planches proposees | pret a jouer, choix de fond et ordre des ecrans a valider avec Ben avant le rendu complet |

Contrairement à VAGUA et Kotizo, il n'y a pas de lot 01 "Kit de composants" :
UZME est déjà en production (80 écrans et plus), ce premier lot ne dessine
aucun écran d'app, seulement des planches marketing qui accueilleront de
vraies captures. Un futur lot qui dessinerait un vrai écran UZME devra
d'abord cartographier `lib/widgets/common/` (règle du brain S&D) avant
d'ouvrir un lot "composants".

## Comment jouer un lot

1. Donner le fichier du lot à Claude Design, tel quel, en entier.
2. Déposer le dossier rendu dans `handoffs/<slug-du-lot>/` (déjà créé pour le
   lot 01).
3. Cocher le lot dans le tableau ci-dessus.
4. Reporter dans `00-SYSTEME.md` ce que le lot a tranché (notamment le choix
   de fond entre le dégradé signature et l'alternative claire), puis relancer
   `python3 design/prompts/inject-socle.py`, c'est ce qui empêche le lot
   suivant de rouvrir une question déjà réglée.

## Ce que chaque rendu doit contenir

- Chaque planche dans les trois tailles imposées (1242x2688, 1284x2778,
  1080x1920).
- La liste des tokens utilisés, pour vérifier qu'aucune couleur hors charte
  n'a été inventée.
- Les contrastes mesurés de chaque paire texte/fond.

Un rendu sans contrastes mesurés n'est pas exploitable.

## Une question ouverte à trancher avant le rendu complet du lot 01

Le fond de série : le dégradé signature `#0B38BF` vers `#031473` (direction
retenue par défaut dans le socle) ou un fond blanc uni avec texte bleu
(meilleure lisibilité en vignette, mais AA seulement, pas AAA). Demander à
Claude Design une planche témoin dans les deux directions avant de lancer
la série complète dans les trois tailles.

## Après la validation du lot 01

Les cinq captures d'écran réelles (ou le nombre ajusté avec Ben) doivent être
prises sur l'app à jour, puis montées dans la zone vide de chaque planche,
pixel pour pixel sur les proportions prévues. Méthode de capture et pièges :
`~/.smooth-brain/conventions/ecrans-depuis-planches-claude-design.md`.
