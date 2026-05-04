import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/main.dart' show recentAccountsService;

/// Presents a Lock vs Sign-out choice when the current user has biometric
/// enabled. Falls through to [onSignOut] directly otherwise.
///
/// The caller is responsible for the actual side effects (clearing blocs,
/// dispatching events, navigating). The helper is UI-only.
Future<void> showLockOrSignOutSheet(
  BuildContext context, {
  required String email,
  required Future<void> Function() onSignOut,
  required Future<void> Function() onLock,
}) async {
  final account = recentAccountsService.findByEmail(email);
  final hasBiometric = account?.biometricEnabled ?? false;

  if (!hasBiometric) {
    await onSignOut();
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Que veux-tu faire ?',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.lock, color: Colors.amber),
            title: const Text('Verrouiller', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'Garder la session. Au prochain lancement, déverrouillage via Face ID ou Touch ID.',
            ),
            onTap: () async {
              Navigator.pop(sheetContext);
              await onLock();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.rightFromBracket, color: Colors.red),
            title: const Text(
              'Se déconnecter complètement',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Effacer la session. Il faudra se reconnecter via Google, Apple ou e-mail.',
            ),
            onTap: () async {
              Navigator.pop(sheetContext);
              await onSignOut();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
