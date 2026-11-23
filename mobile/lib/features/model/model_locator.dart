import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model_manifest.dart';

/// Finds the model file on this phone. Where it comes from (a Play asset pack on Android, the app
/// bundle on iPhone, or a file copied for testing) is not this class's business.
abstract class ModelLocator {
  /// Path of a usable model file, or null when none is installed.
  Future<String?> find(ModelManifest manifest);
}

/// Looks in the app's own storage folder `models/`.
class AppFolderModelLocator implements ModelLocator {
  AppFolderModelLocator([Future<Directory> Function()? base])
    : _base = base ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _base;

  @override
  Future<String?> find(ModelManifest manifest) async {
    final file = File(
      p.join((await _base()).path, 'models', manifest.fileName),
    );
    // A half-copied file must not be loaded: require it to look like a GGUF.
    if (!await file.exists() || await file.length() < 1024 * 1024) return null;
    final head = await file.openRead(0, 4).first;
    return String.fromCharCodes(head) == 'GGUF' ? file.path : null;
  }
}
