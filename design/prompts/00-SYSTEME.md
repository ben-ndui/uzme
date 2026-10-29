# Socle commun, à coller EN TÊTE de chaque prompt Claude Design

> Ce fichier n'est pas un prompt à jouer seul. C'est le bloc de contexte que
> chaque prompt de lot reprend, pour que tous les lots UZME forment un système
> et non des directions différentes. Propagé automatiquement par
> `inject-socle.py`, éditer ICI, jamais dans la Partie 1 d'un lot.

## Le produit

**UZME** : réservation de sessions studio entre artistes, ingénieurs son et
propriétaires de studios. Trois rôles se partagent l'app : **artiste**
(`client`, la demande), **ingénieur son** (`worker`, l'expertise technique),
**studio** (`admin`/`superAdmin`, l'offre, gère réservations, équipe,
services). Flutter + Firebase (Firestore, Auth, Storage, Cloud Functions).

Édité par **Smooth & Design**. FR et EN.

## Ce qu'on cherche

Une app qui rend la réservation studio aussi simple qu'un taxi : on cherche sur
une carte, on compare équipements et disponibilités, on réserve, on suit sa
session. L'ambiance doit parler à des musiciens et des professionnels de
l'enregistrement, créative mais crédible, jamais gadget.

Concrètement :
- Le studio, l'ingénieur et le créneau sont les éléments les plus lisibles de
  chaque écran (c'est ce qu'on compare avant de réserver).
- Un statut de session est une phrase (« Confirmée pour le 12 à 14h »), jamais
  une pastille de couleur seule.
- Le ton est celui d'un pair du milieu musical, pas d'une appli de gestion :
  direct, sans jargon administratif.

Ambiance : nocturne, créative, nette. Le bleu profond de marque porte
l'identité (voir dégradé ci-dessous), pas de néon, pas de dégradé multicolore,
pas d'esthétique « studio vintage » (vinyles, bandes magnétiques, VU-mètres).

## Tokens, valeurs réelles lues dans `lib/config/useme_theme.dart`

| Rôle | Valeur | Source |
|---|---|---|
| Bleu primaire (porte texte, icônes, CTA) | `#0B38BF` | `UseMeTheme.primaryColor` |
| Bleu secondaire (fond immersif, bas du dégradé) | `#031473` | `UseMeTheme.secondaryColor` |
| Turquoise (tertiaire, rare) | `#00CEC9` | `UseMeTheme.tertiaryColor` |
| Accent clair | `#3B5FC7` | `UseMeTheme.accentColor` |
| Succès | `#00B894` | `UseMeTheme.successColor` |
| Alerte | `#FDCB6E` | `UseMeTheme.warningColor` |
| Erreur | `#E17055` | `UseMeTheme.errorColor` |

Surfaces thème sombre (toutes dérivées du bleu, décision du 28/10/2026, voir
plus bas) : fond d'écran `#031473`, cartes `#123490`, cartes élevées
`#1E47B5`/`#2E5CD6`, filet `#2A4A9E`, texte secondaire `#A8B5D9`.

Typographie : **Inter** (Google Fonts), une seule famille. Hiérarchie par la
graisse : `bold`/`w600` pour titres, `w500` pour labels, normal pour le corps.
(UZME n'a pas de traitement typographique dédié pour son nom : dans l'app,
« UZME » s'affiche en Inter bold 16px sans mise en forme spéciale. Pour les
planches, proposer un agrandissement du même traitement plutôt qu'inventer une
calligraphie qui n'existe pas dans le produit.)

## Le dégradé signature, l'identité sombre de la marque

Décrété par Ben le 28/10/2026, en toutes lettres : « en theme dark, je ne
devrais voir de noir nulle part, notre dark à nous c'est le bleu qu'on utilise
dans smooth_draggable_background.dart ». Toute surface immersive ou décorative
de l'app, en sombre, dérive de CE dégradé, jamais un noir ou gris neutre.

Spécification exacte (`lib/widgets/common/smooth_draggable_background.dart`) :
- Dégradé linéaire `#0B38BF` vers `#031473`, du haut vers le bas
  (`Alignment.topCenter` vers `bottomCenter`).
- Coins arrondis 40px en haut seulement (le bas est carré quand c'est une
  feuille qui touche le bord de l'écran).
- Liseré `outlineVariant` 0,5px en haut.
- Ombre portée noire, alpha 0,2 (sombre) ou 0,08 (clair), flou 10, décalage
  (0, moins 5).

C'est ce dégradé, pas un simple aplat `#031473`, qui doit servir de fond aux
planches store si on choisit le thème sombre pour la série (voir Partie 2).

## La barre de navigation flottante, `UzmeNavBar`

Si une capture d'écran réelle l'inclut (elle l'inclura, c'est le châssis de
toutes les pages internes), ces valeurs ne se renégocient pas :

- Hauteur 68, rayon 32, décollée des bords (marge latérale 16, marge basse 4
  plus zone de sécurité).
- Fond plein, jamais translucide. Sombre : barre blanche, pilule active bleu
  `#0B38BF`, encre blanche dessus. Clair : barre en dégradé `#0B38BF` vers
  `#031473` (diagonal haut gauche vers bas droite), pilule blanche, encre bleue
  dessus. (Elle s'inverse par rapport au fond de l'app : barre blanche sur
  fond sombre, barre bleue sur fond clair.)
- Ombre : flou 28, décalage (0, 10), alpha 0,15 (sombre) ou 0,35 (bleu, clair).
- La pilule active glisse (260ms, easeOutCubic), coupée si le système demande
  de réduire les animations.

## Identité visuelle existante

- Icône d'app : `assets/logo/appstore.png` (iOS) et `assets/logo/playstore.png`
  (Android), les réutiliser telles quelles, ne pas en redessiner une version.
- Nom affiché : UZME (majuscules), `CFBundleDisplayName` et `android:label`.
- Pas de slogan officiel déposé à ce jour, en proposer un court pour les
  planches reste ouvert (voir Partie 2).

## Décisions déjà actées (ne pas rouvrir)

### 28/10/2026, unification du thème sombre

Avant cette date, plusieurs écrans redéfinissaient leur propre fond sombre
(wrappers `GradientSurface` posés par écran), source d'incohérences : chips,
feuilles et icônes restaient noir ou gris neutre pendant que d'autres zones
avaient le dégradé. Corrigé à la source dans `useme_theme.dart` : une seule
définition du thème sombre, tout en bleu, lue partout. Conséquence pour le
design : toute nouvelle surface sombre proposée doit être une teinte de ce
bleu, jamais un gris ou noir neutre, même « juste pour un fond marketing ».

### 29/10/2026, premier lot de planches store (ce fichier)

Pas de kit de composants transverse formalisé pour UZME à ce jour (contrairement
à VAGUA et Kotizo) : l'app est déjà en production avec 80 écrans et plus,
ce travail porte uniquement sur les planches marketing des fiches store, pas
sur une refonte d'écran. Si un futur lot dessine de vrais écrans UZME,
cartographier `lib/widgets/common/` avant d'écrire quoi que ce soit (règle
« cartographier avant de coder » du brain S&D).
