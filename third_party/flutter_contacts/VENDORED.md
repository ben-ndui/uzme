# flutter_contacts 1.1.9+2 — vendorisé + patché

Copie de [flutter_contacts 1.1.9+2](https://pub.dev/packages/flutter_contacts)
(MIT, © QuisApp — LICENSE conservée), seule version publiée sur pub.dev
au 2026-10-27.

**`SwiftFlutterContactsPlugin.register(with:)`** capturait le
`rootViewController` une seule fois via
`UIApplication.shared.delegate!.window!!.rootViewController!`. Sous le
cycle UIScene (imposé par Xcode 27+ — migration AppDelegate/SceneDelegate
du même commit), la fenêtre appartient à la `UIWindowScene` et n'existe
pas encore au moment où les plugins s'enregistrent : ce force-unwrap
plantait l'app au tout premier lancement, avant même d'afficher un
écran (`Fatal error: Unexpectedly found nil while unwrapping an
Optional value`).

**Patch** : `rootViewController` est devenu une propriété calculée,
résolue paresseusement à chaque présentation (fiche contact / picker)
au lieu d'être figée à l'enregistrement — même logique que
`openExternalDelete` (ligne ~678 de l'upstream) qui faisait déjà cette
résolution tardive avec un chaînage optionnel, sans force-unwrap.
Remonte aussi au `UIWindowScene` courant en repli si
`UIApplication.shared.delegate.window` est vide.

Patch marqué `UZME PATCH` dans
`ios/Classes/SwiftFlutterContactsPlugin.swift`. À supprimer (retour à
la dépendance pub.dev) si l'upstream publie un correctif.

`example_full/` et `test/` retirés de la copie.
