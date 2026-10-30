import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_folder_watcher/smoothandesign_folder_watcher.dart';
import 'package:uzme/widgets/engineer/studio_folder_file_tile.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  final file = WatchedFile(
    name: 'mix_final.wav',
    path: '/Users/eng/Enregistrements/mix_final.wav',
    modifiedAt: DateTime(2026, 10, 30, 14, 5),
    sizeBytes: 3 * 1024 * 1024,
  );

  testWidgets('affiche le nom du fichier', (tester) async {
    await tester.pumpWidget(buildTestApp(
      child: Scaffold(body: StudioFolderFileTile(file: file, onSend: () {})),
    ));

    expect(find.text('mix_final.wav'), findsOneWidget);
  });

  testWidgets('affiche la taille arrondie en Mo', (tester) async {
    await tester.pumpWidget(buildTestApp(
      child: Scaffold(body: StudioFolderFileTile(file: file, onSend: () {})),
    ));

    expect(find.textContaining('3.0 Mo'), findsOneWidget);
  });

  testWidgets('le bouton Envoyer déclenche onSend', (tester) async {
    var sent = false;
    await tester.pumpWidget(buildTestApp(
      child: Scaffold(body: StudioFolderFileTile(file: file, onSend: () => sent = true)),
    ));

    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(sent, isTrue);
  });
}
