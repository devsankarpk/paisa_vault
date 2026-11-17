import 'dart:typed_data';

/// Text recognition for the camera card scan. Returns lines in reading order.
abstract class TextScanner {
  Future<List<String>> recognise(Uint8List imageBytes);
}
