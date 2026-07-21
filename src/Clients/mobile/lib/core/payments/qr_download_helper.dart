import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';

Uint8List? qrPngBytesFromDataUrl(String? dataUrl) {
  final value = dataUrl?.trim() ?? '';
  if (value.isEmpty) return null;

  final commaIndex = value.indexOf(',');
  final base64Value = commaIndex >= 0 ? value.substring(commaIndex + 1) : value;
  try {
    return base64Decode(base64Value);
  } catch (_) {
    return null;
  }
}

Future<Uint8List> resolveQrPngBytes({
  String? dataUrl,
  required String fallbackData,
  QrEyeStyle eyeStyle = const QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: ui.Color(0xFF000000),
  ),
  QrDataModuleStyle dataModuleStyle = const QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.square,
    color: ui.Color(0xFF000000),
  ),
}) async {
  final decodedBytes = qrPngBytesFromDataUrl(dataUrl);
  if (decodedBytes != null && decodedBytes.isNotEmpty) return decodedBytes;

  return renderQrPngBytes(
    data: fallbackData,
    eyeStyle: eyeStyle,
    dataModuleStyle: dataModuleStyle,
  );
}

Future<Uint8List> renderQrPngBytes({
  required String data,
  double size = 768,
  double padding = 64,
  QrEyeStyle eyeStyle = const QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: ui.Color(0xFF000000),
  ),
  QrDataModuleStyle dataModuleStyle = const QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.square,
    color: ui.Color(0xFF000000),
  ),
}) async {
  final value = data.trim();
  if (value.isEmpty) {
    throw ArgumentError('QR data must not be empty.');
  }

  final painter = QrPainter(
    data: value,
    version: QrVersions.auto,
    gapless: false,
    eyeStyle: eyeStyle,
    dataModuleStyle: dataModuleStyle,
  );

  final resolvedSize = size.round();
  final imageSize = resolvedSize.toDouble();
  final quietZone = padding.clamp(0, imageSize / 2 - 1).toDouble();
  final qrSize = imageSize - (quietZone * 2);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, imageSize, imageSize),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  canvas
    ..save()
    ..translate(quietZone, quietZone);
  painter.paint(canvas, ui.Size(qrSize, qrSize));
  canvas.restore();

  final image = await recorder.endRecording().toImage(
        resolvedSize,
        resolvedSize,
      );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not render QR image.');
  }

  return byteData.buffer.asUint8List();
}

Future<bool> saveQrPngFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  if (bytes.isEmpty) {
    throw ArgumentError('QR image bytes must not be empty.');
  }

  final savedPath = await FilePicker.saveFile(
    dialogTitle: 'Lưu mã QR',
    fileName: sanitizeQrFileName(fileName),
    type: FileType.custom,
    allowedExtensions: const ['png'],
    bytes: bytes,
  );

  return kIsWeb || savedPath != null;
}

String sanitizeQrFileName(String value, {String fallback = 'miane-qr'}) {
  final sanitized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  final baseName = sanitized.isEmpty ? fallback : sanitized;
  return baseName.endsWith('.png') ? baseName : '$baseName.png';
}
