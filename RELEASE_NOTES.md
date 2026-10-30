# UZME — Notes de version

Ce fichier compile les changements user-facing depuis la dernière version
publiée en prod (**v1.3.0**) jusqu'à la version actuelle (**v1.5.28**).

> ⚠️ Trou non documenté entre v1.5.24 et v1.5.27 : ces versions ont été
> taguées sans section ici (voir l'historique git pour le détail si besoin
> un jour). Pas comblé — pas bloquant pour publier v1.5.28.

À utiliser pour :
- Description Play Store / TestFlight
- Bottomsheet « Quoi de neuf » in-app
- Newsletter / annonce communauté

---

## Convention par version (lue automatiquement par les workflows)

À chaque release, ajouter une section au format suivant **avant de
lancer la release.yml** depuis le dashboard. Le workflow extrait la
section pour la version qu'il vient de tagger et passe le contenu à
Fastlane (`upload_to_play_store` + `deliver`).

```
## v{X.Y.Z}

### FR
Texte court FR (≤500 chars pour Play Store, ≤4000 pour App Store).

### EN
Short EN text.

### SG
Texte Sango (in-app what's-new uniquement — pas une locale store).
```

**⚠️ Pas d'emoji ni d'icônes dans les sections FR / EN.** Apple
rejette les release notes contenant des emoji (Guideline App Review
sur le contenu des metadata). Les bullets utiliser `-` ou `•`. Les
emoji restent OK pour SG puisque cette section n'est pas envoyée aux
stores (c'est uniquement la copie pour le bottomsheet what's-new
in-app).

Voir `scripts/extract_release_notes.sh` pour le parser exact.

Si une section ou une locale manque, Fastlane skip le upload des notes
sans casser le deploy → release notes restent celles de la version
précédente sur le store.

---

## v1.5.28

### FR
- Nouveau : le dossier d'enregistrement — choisis dans les Réglages le dossier où tu enregistres tes sessions (ordinateur, téléphone ou tablette) et envoie un fichier à un artiste en un geste, sans ouvrir un autre outil.
- Messagerie : un message qui ne part pas affiche maintenant une erreur claire au lieu de disparaître en silence.
- Fix : l'application ne crashait plus au lancement sur Mac dans de rares cas.
- Fix : la barre de navigation reste bien en bas sur iPad et grand écran.
- Fix : le fond de l'écran de discussion ne devenait plus noir en thème clair.

### EN
- New: recording folder — pick the folder where you record your sessions (computer, phone, or tablet) in Settings, and send a file to an artist in one tap.
- Messaging: a message that fails to send now shows a clear error instead of silently disappearing.
- Fix: the app no longer crashed on launch on Mac in rare cases.
- Fix: the navigation bar now stays at the bottom on iPad and large screens.
- Fix: the chat screen background no longer turned black in light mode.

### SG
📁 Fini : dossier tî enregistrement — choisi na Réglages dossier so mo-yêkë enregistrer sessions tî mo (ordinateur, téléphone wala tablette), tokua fichier na artiste na mbeni geste.
💬 Messagerie : message so a-yêkë pars pëpe a-yêkë montrer erreur, a-disparaître na silence pëpe.
🐛 Fix : app a-yêkë crash na lancement na Mac pëpe mbeni fois.
🐛 Fix : barre tî navigation a-yêkë ngbâ na bas na iPad na grand écran.

---

## v1.5.24

### FR
- Profil : édite ta ville et tes genres musicaux directement depuis ton profil.
- Studios : saisie d'adresse avec suggestions auto + carte interactive pour ajuster ta position.
- Onboarding : demandes de permission conformes aux recommandations Apple.
- Fix : retour des Réglages iOS, l'écran se met à jour automatiquement.

### EN
- Profile: edit your city and music genres directly from your profile.
- Studios: address input with live suggestions + interactive map to adjust your pin.
- Onboarding: permission prompts follow Apple's guidelines.
- Fix: returning from iOS Settings now refreshes the screen automatically.

### SG
🌆 Profil tî mo a-yêkë na fini : modifie ville na genres musicaux direct na profil.
📍 Saisie tî adresse fluide na studios : suggestions automatique, carte interactive tî ajuster position.
🔐 Onboarding a-yêkë na recommandations tî Apple — « Tambela » na pëtï tî « Activer ».
🐛 Fix : si mo a-change permission na Réglages, écran a-update pëpe. A-yêkë awê.

---

## v1.5.23

### FR
- Programme Pioneer : badge studio, frais offerts 6 mois, mise en avant carte.
- Bascule entre rôles (Artiste / Studio / Ingé) avec conseiller IA.
- Assistant IA contextualisé qui connaît ton activité.
- Face ID / Touch ID + verrouillage de l'app.
- Profil public uzme.app/u/{id} pour les QR codes.
- Messagerie : badges rôle + étoile Pioneer.
- Langue Sango ajoutée.
- Re-design AI Assistant + mode clair / sombre.

### EN
- Pioneer programme: studio badge, 6-month fee waiver, featured on the map.
- Switch roles (Artist / Studio / Engineer) with an AI advisor.
- Context-aware AI assistant that knows your activity.
- Face ID / Touch ID + app lock.
- Public profile at uzme.app/u/{id} for QR scans.
- Conversations: role badges + Pioneer star.
- Sango language added.
- AI Assistant redesign + light / dark mode.

### SG
🚀 Programme Pioneer : badge studio tî mo, frais a-yêkë gï tî 6 nze, mise tî kekê na carte.
🎭 Bascule rôle (Artiste/Studio/Ingé) na conseiller IA.
🤖 Assistant IA so a-yêkë na contexte tî activité tî mo.
🔐 Face ID / Touch ID + verrouillage tî app.
🌐 Profil public uzme.app/u/{id} tî QR code.
💬 Conversations: badge rôle + étoile Pioneer.
🌍 Sango a-yêkë na app.
🎨 Re-design AI Assistant + mode lê / lê.

---

## Fiche complète — v1.3.0 → v1.5.23

### 🚀 Nouvelles fonctionnalités majeures

**Programme Pioneer** 🌟
On récompense les premiers utilisateurs qui font vivre la plateforme.
- Studios Pioneer mis en avant sur la carte (épingle dorée + halo)
- Tri prioritaire dans la recherche
- Frais Stripe offerts pendant 6 mois (commission + abonnement)
- Badge étoile sur les conversations
- Notif push à la distribution du badge

**Comparateur de rôles + bascule** 🎭
Passer entre Artiste / Studio / Ingé son sans recréer un compte.
- Écran de comparaison côte à côte
- Conseiller IA qui lit ton profil et propose le rôle le plus pertinent
- Soft-archive : tes données du rôle précédent sont conservées si tu reviens
- Limite de 3 bascules / an pour éviter les abus

**Auto-bascule sur invitation** ⚡
Un studio t'invite via team ? Ton rôle passe automatiquement à Ingé son
quand tu acceptes — plus besoin d'aller dans les paramètres.

**Assistant IA contextualisé** 🤖
Le chat IA connaît maintenant ton rôle, ton historique d'activité, tes
sessions passées. Réponses sur-mesure au lieu de génériques.
- FAB AI à 2 modes : tap = conversation, long-press = sheet rapide
- Suggestions de réponses dans la messagerie

**« Quoi de neuf pour moi »** ✨
L'IA te résume uniquement les nouvelles fonctionnalités pertinentes
pour TON usage de l'app, plutôt qu'une longue liste générique.

**Profil public web** 🌐
Quand quelqu'un scanne ton QR code UZME sans avoir l'app, il atterrit
sur une fiche propre (`uzme.app/u/{id}`) avec :
- Avatar, nom, badge rôle, ville
- Bio, spécialités, genres
- Badges Pioneer / Partenaire
- CTA « Ouvrir UZME »
- Meta tags pour le partage social

---

### 🗺️ Carte & Recherche

- Filtre qui exclut automatiquement les lieux non-studio
- Pastille « X studios à proximité » draggable sur la carte
- Recherche améliorée : tri par engagement (Pioneer en haut)
- Halo lumineux sur le studio sélectionné

---

### 💬 Messagerie

- Conversation enrichie : pastille de rôle colorée (Artiste violet,
  Studio or, Ingé teal) + étoile dorée si Pioneer
- Suggestions de réponse IA en bas du chat
- Avatars avec overlay de rôle pour repérer le contexte d'un coup

---

### 🔐 Connexion & sécurité

- **Face ID / Touch ID / empreinte** pour re-login rapide
- **Verrouillage de l'app** (au lieu de déconnexion) : tu gardes les
  notifs et la sync calendrier qui tournent en background
- Apple / Google Sign-In stables (fix crash iOS, fix zone mismatch)
- Messages d'erreur clairs (« Email ou mot de passe incorrect » au
  lieu du `INVALID_LOGIN_CREDENTIALS` cryptique)
- Rôle par défaut = Artiste au signup (plus de sélecteur qui piège
  les nouveaux comptes Apple/Google)

---

### 🌍 Internationalisation

- 3 langues : **Français**, **Anglais**, **Sango**
- Tous les écrans admin migrés (Pioneer, Feature Flags, Role Switch)
- 40 traductions Sango ajoutées pour les cartes digitales

---

### 🎨 Interface

- Re-design écran Assistant IA aux couleurs UZME (plus de violet hors-charte)
- Mode clair / sombre amélioré sur tous les écrans
- Support iPhone 17 simulator
- iOS minimum bumped à iOS 14 (drop iOS 13)
- Migration Flutter SDK 3.38.2 → 3.41.9

---

### 🔔 Notifications

- Push quand tu deviens Pioneer 🚀
- Bottomsheet « Quoi de neuf » qui s'affiche au lancement après un
  rollout de fonctionnalité (avec replay si tu rates l'event)

---

### ⚙️ Sous le capot (impact user)

- Migration vers le projet Firebase **uzme-app** dédié → API plus
  rapide (europe-west1), Crashlytics activé
- Permissions Android conformes aux nouvelles règles Play Store
  (Photo Picker système, plus de READ_MEDIA_IMAGES)
- Feature flags global avec 4 modes (`disabled` / `pioneer` / `beta` /
  `enabled`) pour activation progressive sans rebuild
- Gestion des distributions de paiement (post-booking) cleanup

---

## Release notes — Play Store / App Store (≤ 500 chars / locale)

### Français

```
🚀 Programme Pioneer : badge studio, frais offerts 6 mois, mise en avant carte.
🎭 Bascule entre rôles (Artiste/Studio/Ingé) avec conseiller IA.
🤖 Assistant IA contextualisé qui connaît ton activité.
🔐 Face ID / Touch ID + verrouillage de l'app.
🌐 Profil public uzme.app/u/{id} pour les QR codes.
💬 Messagerie : badges rôle + étoile Pioneer.
🌍 Sango ajouté.
🎨 Re-design AI Assistant + mode clair/sombre.
```

### English

```
🚀 Pioneer programme: studio badge, 6-month fee waiver, featured on the map.
🎭 Switch roles (Artist/Studio/Engineer) with an AI advisor.
🤖 Context-aware AI assistant that knows your activity.
🔐 Face ID / Touch ID + app lock.
🌐 Public profile at uzme.app/u/{id} for QR scans.
💬 Conversations: role badges + Pioneer star.
🌍 Sango language added.
🎨 AI Assistant redesign + light/dark mode.
```

### Sango

```
🚀 Programme Pioneer : badge studio tî mo, frais a-yêkë gï tî 6 nze, mise tî kekê na carte.
🎭 Bascule rôle (Artiste/Studio/Ingé) na conseiller IA.
🤖 Assistant IA so a-yêkë na contexte tî activité tî mo.
🔐 Face ID / Touch ID + verrouillage tî app.
🌐 Profil public uzme.app/u/{id} tî QR code.
💬 Conversations: badge rôle + étoile Pioneer.
🌍 Sango a-yêkë na app.
🎨 Re-design AI Assistant + mode lê / lê.
```

---

## In-app What's-New (≤ 280 chars, format bottomsheet)

```
v1.5.23 — Programme Pioneer + bascule de rôle 🚀

Récompense des premiers users (badge or, frais offerts), comparateur Artiste/Studio/Ingé avec IA, profil public web pour les QR codes, Face ID + verrouillage, et plein d'autres améliorations 🎵
```

---

## Versioning

| Version | Date         | Highlights |
|---------|--------------|------------|
| v1.5.23 | 2026-05-07   | Photo Picker compliance Android |
| v1.5.22 | 2026-05-07   | Pioneer badge tile + i18n admin |
| v1.5.21 | 2026-05-07   | Smoke tests phase E + AI-3 |
| v1.5.20 | 2026-05-06   | What's-new IA personnalisé |
| v1.5.14 | 2026-05-06   | Phase E Role Switch complète |
| v1.5.10 | 2026-05-04   | Login UX + invalid-credential |
| v1.5.4  | 2026-05-04   | Feature Flags global |
| v1.5.0  | 2026-05-04   | Pioneer cohorts + map |
| v1.4.7  | 2026-04-29   | CI build refresh |
| v1.4.6  | 2026-04-28   | Lock UX hardening |
| v1.4.5  | 2026-04-27   | Lock vs SignOut biometric |
| v1.4.4  | 2026-04-25   | Maps uzme-app keys |
| v1.4.3  | 2026-04-24   | White screen TestFlight fix |
| v1.4.0  | 2026-04-22   | Migration uzme-app Firebase |
| v1.3.8  | 2026-04-15   | Biometric login (Face/Touch/empreinte) |
| v1.3.4  | 2026-04-10   | Google Sign-In TestFlight fix |
| v1.3.3  | 2026-04-08   | Crashlytics activé |
| v1.3.2  | 2026-04-06   | Re-design AI Assistant |
| v1.3.1  | 2026-04-04   | i18n Sango cartes |
| v1.3.0  | 2026-04-01   | Dernière prod (référence) |
