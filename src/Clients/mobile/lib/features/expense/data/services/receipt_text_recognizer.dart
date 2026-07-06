import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the native Apple Vision framework (VNRecognizeTextRequest) via
/// a platform channel implemented in ios/Runner/AppDelegate.swift.
///
/// Vision ships with the OS itself — unlike Google ML Kit's prebuilt
/// binaries, it has full arm64 Simulator support, so this runs on Apple
/// Silicon simulators as well as real devices. See
/// AI_OCR_LOCAL_REQUIREMENTS.md §5.
class ReceiptTextRecognizer {
  static const _channel = MethodChannel('miane.app/text_recognizer');

  /// Returns the recognized text as a list of lines, in reading order.
  Future<List<String>> recognizeLines(File imageFile) async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'recognizeText',
      {'path': imageFile.path},
    );
    return (result ?? const []).map((e) => e.toString()).toList();
  }

  void dispose() {
    // No native resources to release — VNRecognizeTextRequest is per-call.
  }
}
