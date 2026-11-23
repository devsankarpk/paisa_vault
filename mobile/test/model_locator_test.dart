import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/features/model/model_locator.dart';
import 'package:paisa_vault/features/model/model_manifest.dart';

void main() {
  late Directory base;
  late AppFolderModelLocator locator;

  setUp(() {
    base = Directory.systemTemp.createTempSync('pv_model');
    locator = AppFolderModelLocator(() async => base);
  });
  tearDown(() => base.deleteSync(recursive: true));

  File modelFile() => File('${base.path}/models/${qwen3Manifest.fileName}');

  test('no model installed', () async {
    expect(await locator.find(qwen3Manifest), isNull);
  });

  test('finds a real-looking GGUF file', () async {
    modelFile()
      ..createSync(recursive: true)
      ..writeAsBytesSync([
        ...'GGUF'.codeUnits,
        ...List.filled(2 * 1024 * 1024, 0),
      ]);
    expect(await locator.find(qwen3Manifest), modelFile().path);
  });

  test('ignores a half-copied or wrong file', () async {
    modelFile().createSync(recursive: true);
    modelFile().writeAsBytesSync([...'GGUF'.codeUnits, 1, 2, 3]); // too small
    expect(await locator.find(qwen3Manifest), isNull);
    modelFile().writeAsBytesSync(
      List.filled(2 * 1024 * 1024, 7),
    ); // big but not GGUF
    expect(await locator.find(qwen3Manifest), isNull);
  });
}
