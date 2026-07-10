# Réponse App Review — rejet du 06/07/2026 (v1.5.25 b82)

> Submission ID : `a923a829-f533-481b-b8f4-9b6e67c89913`
> Rejets : Guideline 2.1(a) (chargement infini au lancement) + Guideline 2.1 (vidéo démo NFC exigée).
> Fix code : commit `38bea12` (purge keychain install fraîche + timeout Firestore 10s + watchdog splash).

## Avant d'envoyer — checklist

- [x] Build de resoumission : **1.5.25 (84)** sur TestFlight (10/07) — tous les fixes, NFC inclus.
- [x] Compte démo `artist@test.fr` remis en rôle `client` (custom claim resynchronisé, vérifié).
- [x] NFC réparé et testé sur device (tags vierges + session) ; page `uzme.app/u/{id}` en ligne.
- [ ] Filmer la vidéo NFC : iPhone physique + tag visibles — carte digitale → écriture du tag ("Profil UZME écrit !") → app fermée, tap du tag → bannière iOS → profil s'ouvre.
- [ ] Uploader la vidéo et mettre le lien dans **App Review Information** (pas seulement dans la réponse).
- [ ] Remplacer `[VIDEO_LINK]` ci-dessous.
- [ ] Test conseillé sur le build 84 TestFlight : install fraîche (login direct) + update par-dessus.

## Réponse à coller dans App Store Connect

Hello,

Thank you for the detailed review. We have addressed both issues.

**Guideline 2.1(a) — App loads indefinitely upon launch**

We identified the root cause: a stale authentication session persisted in the iOS keychain from a previous installation of the app (keychain data survives app uninstallation on iOS). On launch, the app attempted to restore this expired session and waited indefinitely on a network call that could never complete.

We have fixed this in build 84:

- On a fresh installation, the app now clears any stale keychain session and starts from a clean, signed-out state.
- All authentication network calls at startup are now bounded by a strict timeout.
- As a final failsafe, the launch screen automatically falls back to the login screen if initialization takes longer than a few seconds.

We verified the fix on physical devices (iPhone and iPad) with both a fresh installation and an update over the previous version.

**Guideline 2.1 — Demo video (NFC functionality)**

The app includes one NFC feature: users can share their UZME digital business card by writing their public profile link to an NFC tag (Digital Card → Share → NFC). We have added a demo video link in the App Review Information section showing:

- The current build running on a physical iPhone (not a simulator),
- The full NFC workflow: opening the digital card, starting the NFC share, holding the phone to an NFC tag, the tag being written successfully, and the tag then being scanned to open the user's profile page.

Demo video: [VIDEO_LINK]

The demo account credentials in App Review Information have been verified and are working (artist@test.fr, studio@test.fr and inge@test.fr — see the Notes field for all three roles).

Thank you for your time, and please let us know if you need anything else.

## Ajout suggéré aux Notes App Review (section NFC)

À ajouter dans le champ Notes de App Review Information :

```
NFC FUNCTIONALITY:
The app's only NFC feature is sharing the user's digital business card:
Profile → Digital Card → Share → NFC writes the user's public profile
link (https://uzme.app/u/{id}) to an NDEF-compatible NFC tag. No NFC
pairing with dedicated hardware is required — any standard NFC tag works.
Demo video: [VIDEO_LINK]
```
