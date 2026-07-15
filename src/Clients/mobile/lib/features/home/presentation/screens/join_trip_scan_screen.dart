import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';

/// Decodes a QR code from a still image entirely in Dart (zxing2, a pure
/// port of the ZXing barcode library), run on a background isolate via
/// [compute] since decoding a full-resolution photo is CPU-bound.
///
/// Two native paths were tried for this "pick a QR screenshot from the
/// library" flow and both turned out to be unusable here:
/// - `MobileScannerController.analyzeImage` — its own docs state it is
///   "not supported on the iOS Simulator, due to restrictions on the
///   Simulator."
/// - Vision's `VNDetectBarcodesRequest` — threw `Could not create
///   inference context` on this iOS Simulator/OS build (a known
///   Vision-on-Simulator limitation for some request types).
///
/// zxing2 has no such restriction — it's pure computation over already
/// decoded pixels, so behavior is identical on Simulator and real devices.
class _QrImageDecoder {
  static Future<String?> decode(String imagePath) {
    return compute(_decodeSync, imagePath);
  }

  static String? _decodeSync(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final source = RGBLuminanceSource(
      image.width,
      image.height,
      image
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.abgr)
          .buffer
          .asInt32List(),
    );
    final bitmap = BinaryBitmap(HybridBinarizer(source));

    try {
      return QRCodeReader().decode(bitmap).text;
    } on ReaderException {
      return null;
    }
  }
}

/// Full-screen camera QR scanner for joining a trip. Returns the extracted
/// invite code (via [Navigator.pop]) once a valid trip QR is detected.
///
/// Trip QR codes encode either a raw invite code or a share URL of the form
/// `https://miane.app/trip/<inviteCode>` (see trip_share_sheet.dart). Both are
/// handled by [_extractInviteCode].
///
/// The camera feed is the primary path, but the Simulator (and any device
/// without a camera) has none — a "pick from library" fallback decodes a QR
/// from a saved screenshot/photo via [MobileScannerController.analyzeImage].
class JoinTripScanScreen extends StatefulWidget {
  const JoinTripScanScreen({super.key});

  @override
  State<JoinTripScanScreen> createState() => _JoinTripScanScreenState();
}

class _JoinTripScanScreenState extends State<JoinTripScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _picker = ImagePicker();
  bool _handled = false;
  bool _torchOn = false;
  bool _decodingFromLibrary = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final code = _codeFrom(barcode);
      if (code != null) {
        _finish(code);
        return;
      }
    }
  }

  void _finish(String code) {
    _handled = true;
    Navigator.of(context).pop(code);
  }

  String? _codeFrom(Barcode barcode) {
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return null;
    final code = _extractInviteCode(raw);
    return (code != null && code.isNotEmpty) ? code : null;
  }

  Future<void> _pickFromLibrary() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _decodingFromLibrary = true);
    try {
      final raw = await _QrImageDecoder.decode(picked.path);
      if (!mounted) return;

      final code = raw != null ? _extractInviteCode(raw) : null;
      if (code != null && code.isNotEmpty) {
        _finish(code);
        return;
      }

      setState(() => _decodingFromLibrary = false);
      await showIosMessage(
        context,
        message: 'Không tìm thấy mã QR hợp lệ trong ảnh này.',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _decodingFromLibrary = false);
      debugPrint('QR image decode failed: $e');
      await showIosMessage(
        context,
        message: 'Không đọc được ảnh này. Vui lòng thử ảnh khác.',
        isError: true,
      );
    }
  }

  /// Pulls the invite code out of a scanned payload. Accepts:
  /// - a share URL: `https://miane.app/trip/ABC123` -> `ABC123`
  /// - a raw code: `ABC123` -> `ABC123`
  static String? _extractInviteCode(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final tripIdx = segments.indexOf('trip');
      if (tripIdx != -1 && tripIdx + 1 < segments.length) {
        return segments[tripIdx + 1];
      }
      // Fallback: last non-empty path segment.
      return segments.last;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.32),
        border: null,
        middle: const Text('Quét mã tham gia',
            style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ViewfinderOverlay(),
          Positioned(
            left: 32,
            right: 32,
            bottom: 156,
            child: Text(
              'Đưa mã QR chuyến đi vào khung để tham gia',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd(color: CupertinoColors.white),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Center(
              child: _ScannerControlBar(
                torchOn: _torchOn,
                isBusy: _decodingFromLibrary,
                onToggleTorch: () {
                  _controller.toggleTorch();
                  setState(() => _torchOn = !_torchOn);
                },
                onPickFromLibrary: _decodingFromLibrary ? null : _pickFromLibrary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass control pill anchored above the home indicator — matches the
/// system Camera app's bottom control row (flash on the left, library
/// picker on the right) instead of burying actions in the nav bar.
class _ScannerControlBar extends StatelessWidget {
  final bool torchOn;
  final bool isBusy;
  final VoidCallback onToggleTorch;
  final VoidCallback? onPickFromLibrary;

  const _ScannerControlBar({
    required this.torchOn,
    required this.isBusy,
    required this.onToggleTorch,
    required this.onPickFromLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScannerControlButton(
            icon: torchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash_fill,
            label: 'Đèn flash',
            active: torchOn,
            onPressed: onToggleTorch,
          ),
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: CupertinoColors.white.withValues(alpha: 0.14),
          ),
          _ScannerControlButton(
            icon: CupertinoIcons.photo_on_rectangle,
            label: 'Thư viện ảnh',
            isLoading: isBusy,
            onPressed: onPickFromLibrary,
          ),
        ],
      ),
    );
  }
}

class _ScannerControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ScannerControlButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 26,
            child: isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Icon(
                    icon,
                    color: active ? AppTheme.iosGold : CupertinoColors.white,
                    size: 26,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: (active ? AppTheme.iosGold : CupertinoColors.white)
                  .withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything outside the scan box and draws the four corner brackets
/// iOS users recognize from Camera/Wallet's own QR scanners, instead of a
/// plain full-square border.
class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ViewfinderPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();

  static const _boxSize = 260.0;
  static const _cornerRadius = 28.0;
  static const _bracketLength = 34.0;
  static const _bracketWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 24);
    final rect = Rect.fromCenter(
      center: center,
      width: _boxSize,
      height: _boxSize,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_cornerRadius),
    );

    final outerPath = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRRect(rrect);
    final dimPath = Path.combine(
      PathOperation.difference,
      outerPath,
      holePath,
    );
    canvas.drawPath(dimPath, Paint()..color = const Color(0xB3000000));

    final bracketPaint = Paint()
      ..color = AppTheme.iosBlue
      ..strokeWidth = _bracketWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Simple L-shaped brackets at each corner (straight legs, no arc) —
    // matches the QR-scanner viewfinder pattern used across iOS apps.
    void drawCorner(Offset corner, double dx, double dy) {
      final horizontal = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(corner.dx + dx * _bracketLength, corner.dy);
      final vertical = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(corner.dx, corner.dy + dy * _bracketLength);
      canvas.drawPath(horizontal, bracketPaint);
      canvas.drawPath(vertical, bracketPaint);
    }

    drawCorner(rect.topLeft, 1, 1);
    drawCorner(rect.topRight, -1, 1);
    drawCorner(rect.bottomLeft, 1, -1);
    drawCorner(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
