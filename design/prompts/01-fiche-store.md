# 01 : Planches de fiche store (App Store et Play Store)

> Lot autonome : donner CE fichier seul à Claude Design. La Partie 1 est
> injectée automatiquement depuis `00-SYSTEME.md` (lancer
> `python3 design/prompts/inject-socle.py` après toute modification du socle).

---

# Partie 1, Contexte commun (identique pour tous les lots)

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

---

# Partie 2, Le lot : Planches de fiche store (App Store et Play Store)

## Ce n'est PAS un écran de l'app

Ce lot ne dessine aucune interface UZME : il dessine des planches marketing,
au format exact qu'exige chaque store, dans lesquelles une vraie capture
d'écran de l'app viendra se poser ensuite. Le cadre de téléphone est un mockup
photoréaliste (pas un composant du kit), mais tout le reste (couleurs,
typographie, nom, ton) suit la charte du socle à la lettre.

## Dimensions imposées, aucune autre

App Store (iPhone, portrait), Apple n'accepte que ces tailles, à l'exacte
seconde près :
- 1242 x 2688 px (iPhone 6,5 pouces)
- 1284 x 2778 px (iPhone 6,7 pouces)

Livrer les DEUX tailles pour chaque planche (le contenu est identique, raster
différent, pas de mise en page qui change entre les deux).

Google Play (Android, portrait), Play accepte une plage (320 à 3840 px, ratio
entre 16:9 et 9:16) ; on se cale sur un format propre et net :
- 1080 x 1920 px

## Fond de série : le dégradé signature, pas un aplat

Contrairement à un socle qui choisirait entre un fond clair et un fond sombre
neutre, UZME a un troisième choix, le dégradé signature du socle (`#0B38BF`
vers `#031473`, haut vers bas). C'est la surface la plus reconnaissable de
l'app depuis la refonte du 28/10/2026 et elle photographie mieux qu'un bleu
plat sur une planche store. Direction retenue par défaut, à confirmer avec
Ben avant de lancer le rendu complet : **toute la série sur ce dégradé**,
jamais un mélange d'un fond différent d'une planche à l'autre.

Si Ben préfère un fond clair pour une meilleure lisibilité en vignette (les
icônes de la fiche store s'affichent petites), deuxième direction : fond blanc
uni, mot-symbole et légende en bleu `#0B38BF` (contraste mesuré 6,8:1 sur
blanc, conforme AA mais pas AAA, à noter dans le rendu).

## Composition de chaque planche

- Fond : le dégradé signature du socle (ou l'alternative claire si Ben la
  choisit), un seul choix pour toute la série.
- Le nom « UZME » en haut, en Inter bold agrandi (le socle ne fournit pas
  d'autre traitement, ne pas en inventer un plus élaboré) ; l'icône d'app
  (`assets/logo/appstore.png`) peut se poser juste à côté, pas de logo
  alternatif.
- Un cadre de téléphone photoréaliste, centré ou légèrement décalé bas, sans
  bordure factice ni bouton home (gabarit iPhone récent sans encoche
  grossière ; gabarit Android nu, pas de marque visible).
- À l'intérieur du cadre : une zone plane, unie, sans dégradé, sans icône
  « ajouter une photo », aux proportions exactes d'un écran de téléphone
  (environ 9:19,5), c'est là que la vraie capture viendra se poser au montage.
  Marquer légèrement au centre, en petit et discret, le numéro de la planche
  (1, 2, 3...) pour s'y retrouver au montage, rien d'autre.
- Une légende de vente au-dessus ou à côté du téléphone, grande, une phrase
  courte par planche (voir la liste ci-dessous), jamais plus de 6 mots, jamais
  de point final.
- Le bleu `#0B38BF` porte les aplats et le mot-symbole ; sur fond sombre, le
  texte de la légende passe en blanc (contraste à mesurer et noter dans le
  rendu).

## Les planches à produire, proposition à valider avec Ben

UZME n'a pas encore d'ordre de capture d'écran arrêté (contrairement au lot
Kotizo dont le parcours était déjà figé). Les cinq légendes ci-dessous sont
une PROPOSITION fondée sur les écrans réellement codés de l'app
(`lib/screens/shared/discover_map_screen.dart`,
`lib/screens/artist/session_request_screen.dart`,
`lib/screens/artist/artist_session_detail_screen.dart`,
`lib/screens/shared/chat_screen.dart`, `lib/screens/shared/favorites_screen.dart`),
pas une capture déjà fournie. Ben confirme ou ajuste l'ordre et le choix
d'écran avant le rendu complet :

1. Carte de recherche de studios, légende proposée : « Trouve ton studio en
   un instant »
2. Réservation d'une session, légende proposée : « Réserve en quelques
   secondes »
3. Détail et suivi d'une session, légende proposée : « Suis ta session en
   un coup d'oeil »
4. Messagerie avec le studio, légende proposée : « Échange direct avec le
   studio »
5. Favoris, légende proposée : « Garde tes studios préférés »

Deux fonctionnalités différenciantes existent dans le code et peuvent remplacer
une de ces cinq planches si Ben préfère les mettre en avant :
l'assistant IA (`lib/screens/shared/ai_assistant_screen.dart`) et la carte de
visite numérique (`lib/screens/shared/digital_card_screen.dart`), rares chez
des concurrents du secteur.

(Si Ben fournit un nombre différent d'écrans réels à capturer, ajuster le
nombre de planches en conséquence, ne pas en inventer au-delà des écrans
réellement capturés.)

## Chiffres si une planche en affiche un en dehors de la capture

UZME n'a pas d'annexe chiffrée comme Kotizo (pas de calcul de répartition à
illustrer). Si une planche affiche malgré tout un exemple de prix ou de durée
de session, le signaler explicitement dans le rendu comme un exemple fictif,
jamais un chiffre réel du catalogue d'un studio.

## Ce qui disqualifie une planche

- un dégradé ailleurs que le dégradé signature imposé en fond, ou un dégradé
  sur un élément qui n'est pas ce fond
- une bordure de téléphone factice, trop épaisse, ou une marque visible
- une légende de plus de 6 mots, ou un ton publicitaire criard
- un fond différent d'une planche à l'autre dans la même série
- un gris ou noir neutre en fond ou en surface décorative (règle du socle,
  décision du 28/10/2026)
- un logo ou une calligraphie inventée pour « UZME » qui n'existe pas dans
  le produit

## Livrable

Pour CHAQUE planche (cinq attendues, ou le nombre ajusté avec Ben) : les deux
tailles App Store (1242x2688 et 1284x2778) et la taille Play Store
(1080x1920), sur le fond unique retenu. Si les deux directions de fond (sombre
signature / clair) doivent être comparées avant de trancher, livrer une seule
planche témoin dans les deux directions d'abord, pas la série complète en
double.

Pour chaque rendu : la liste des tokens utilisés, les contrastes mesurés de
chaque paire texte/fond (légende sur le dégradé, numéro de planche sur la
zone vide), et un LIVRAISON.md qui dit : écrans et images, tokens, contrastes,
et « À signaler » (choix de fond non tranché, légende à reformuler, écran
manquant côté capture réelle).

Déposer le rendu dans `design/prompts/handoffs/01-fiche-store/`.
