# nfc_manager 4.1.1 — vendorisé + patché

Copie de [nfc_manager 4.1.1](https://pub.dev/packages/nfc_manager)
(MIT, © okadan — LICENSE conservée) avec deux patches iOS que
l'upstream n'a pas (vérifié jusqu'à 4.2.1) :

1. **`tagReaderSession(_:didInvalidateWithError:)`** — remet
   `tagSession = nil` : sans ça, fermer la feuille NFC iOS (ou le
   timeout 60s) laissait une référence zombie et toute session suivante
   levait `PlatformException(session_already_exists)` jusqu'au kill de
   l'app.
2. **`convert(NFCNDEFTag)` / `readNDEF`** — traite l'erreur
   `ndefReaderSessionErrorZeroLengthMessage` (tag NDEF-formaté mais
   vide, i.e. tout NTAG21x sorti d'usine) comme « pas de message en
   cache » au lieu d'abandonner silencieusement la détection : les tags
   vierges étaient invisibles pour l'app.

Les patches sont marqués `UZME PATCH #1/#2` dans
`ios/Classes/NfcManagerPlugin.swift`. À supprimer (retour à la dépendance
pub.dev) si l'upstream corrige — surveiller le CHANGELOG à chaque bump.

`example/` et `.metadata` retirés de la copie.
