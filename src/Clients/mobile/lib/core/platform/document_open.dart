import 'dart:typed_data';

import 'document_open_stub.dart'
    if (dart.library.html) 'document_open_web.dart';

Future<bool> openDocumentBytes({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) {
  return openDocumentBytesPlatform(
    bytes: bytes,
    fileName: fileName,
    contentType: contentType,
  );
}

Future<bool> openDocumentUrl(String url) => openDocumentUrlPlatform(url);
