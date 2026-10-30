import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uzme/core/services/studio_folder_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bookmark1 = Uint8List.fromList([1, 2, 3]);
  final bookmark2 = Uint8List.fromList([4, 5, 6]);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load renvoie null quand aucun dossier n\'a été choisi', () async {
    final saved = await StudioFolderPreferences.load('eng-1');
    expect(saved, isNull);
  });

  test('save puis load renvoie le même chemin et le même bookmark', () async {
    await StudioFolderPreferences.save('eng-1', '/Users/eng/Enregistrements', bookmark1);
    final saved = await StudioFolderPreferences.load('eng-1');

    expect(saved, isNotNull);
    expect(saved!.path, '/Users/eng/Enregistrements');
    expect(saved.bookmark, bookmark1);
  });

  test('deux ingénieurs sur le même Mac ne se mélangent pas', () async {
    await StudioFolderPreferences.save('eng-1', '/Users/eng1/Sessions', bookmark1);
    await StudioFolderPreferences.save('eng-2', '/Users/eng2/Sessions', bookmark2);

    final saved1 = await StudioFolderPreferences.load('eng-1');
    final saved2 = await StudioFolderPreferences.load('eng-2');

    expect(saved1!.path, '/Users/eng1/Sessions');
    expect(saved1.bookmark, bookmark1);
    expect(saved2!.path, '/Users/eng2/Sessions');
    expect(saved2.bookmark, bookmark2);
  });

  test('clear retire uniquement le dossier de l\'ingénieur concerné', () async {
    await StudioFolderPreferences.save('eng-1', '/Users/eng1/Sessions', bookmark1);
    await StudioFolderPreferences.save('eng-2', '/Users/eng2/Sessions', bookmark2);

    await StudioFolderPreferences.clear('eng-1');

    expect(await StudioFolderPreferences.load('eng-1'), isNull);
    expect((await StudioFolderPreferences.load('eng-2'))!.path, '/Users/eng2/Sessions');
  });
}
