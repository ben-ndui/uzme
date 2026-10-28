import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Redirige Auth/Firestore/Storage/Functions vers les émulateurs Firebase
/// locaux — jamais la production. Activé uniquement par
/// `--dart-define=USE_EMULATORS=true` (harnais E2E Maestro, `tools/e2e/`).
///
/// Doit être appelé APRÈS `Firebase.initializeApp()` et AVANT toute
/// première utilisation d'une instance Auth/Firestore/Storage/Functions
/// (`SmoothFirebase.initializeWithDefault()` inclus) : la redirection ne
/// prend effet qu'avant le premier accès à l'instance par défaut.
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');

void connectToEmulatorsIfRequested() {
  if (!useEmulators) return;

  const host = 'localhost';
  FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}
