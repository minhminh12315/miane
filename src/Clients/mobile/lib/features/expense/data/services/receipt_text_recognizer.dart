import 'dart:io';

import 'package:flutter/services.dart';

/// A single recognized text block with its normalized bounding box, as
/// returned by the native Vision recognizer (origin bottom-left).
class _TextBlock {
  final String text;
  final double x;
  final double y;
  final double height;

  const _TextBlock(this.text, this.x, this.y, this.height);
}

/// Bridges to the native Apple Vision framework (VNRecognizeTextRequest) via
/// a platform channel implemented in ios/Runner/AppDelegate.swift.
///
/// Vision ships with the OS itself — unlike Google ML Kit's prebuilt
/// binaries, it has full arm64 Simulator support, so this runs on Apple
/// Silicon simulators as well as real devices. See
/// AI_OCR_LOCAL_REQUIREMENTS.md §5.
class ReceiptTextRecognizer {
  static const _channel = MethodChannel('miane.app/text_recognizer');

  /// Returns recognized text as logical rows, top-to-bottom.
  ///
  /// Vision often splits one visual table row (e.g. "item name | qty | unit
  /// price | total") into multiple separate text observations rather than a
  /// single line, since it groups purely by text proximity, not table
  /// columns. This reconstructs rows from each observation's bounding box:
  /// blocks whose vertical centers are close together are merged into one
  /// row, ordered left-to-right by their horizontal position.
  Future<List<String>> recognizeLines(File imageFile) async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'recognizeText',
      {'path': imageFile.path},
    );

    final blocks = (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((m) => _TextBlock(
              (m['text'] ?? '').toString(),
              (m['x'] as num?)?.toDouble() ?? 0,
              (m['y'] as num?)?.toDouble() ?? 0,
              (m['height'] as num?)?.toDouble() ?? 0,
            ))
        .where((b) => b.text.trim().isNotEmpty)
        .toList();

    return _reconstructRows(blocks);
  }

  List<String> _reconstructRows(List<_TextBlock> blocks) {
    if (blocks.isEmpty) return const [];

    // Vision's boundingBox origin is bottom-left, so a larger `y` is higher
    // up on the image — sort descending to get top-to-bottom reading order.
    final sorted = [...blocks]..sort((a, b) => b.y.compareTo(a.y));

    final rows = <List<_TextBlock>>[];
    for (final block in sorted) {
      final centerY = block.y + block.height / 2;
      final row = rows.isEmpty ? null : rows.last;
      if (row != null) {
        final rowCenterY =
            row.map((b) => b.y + b.height / 2).reduce((a, b) => a + b) /
                row.length;
        final rowHeight =
            row.map((b) => b.height).reduce((a, b) => a + b) / row.length;
        if ((centerY - rowCenterY).abs() <= rowHeight * 0.6) {
          row.add(block);
          continue;
        }
      }
      rows.add([block]);
    }

    return rows.map((row) {
      row.sort((a, b) => a.x.compareTo(b.x));
      return row.map((b) => b.text).join(' ');
    }).toList();
  }

  void dispose() {
    // No native resources to release — VNRecognizeTextRequest is per-call.
  }
}
