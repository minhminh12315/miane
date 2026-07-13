import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';

/// Full-screen camera QR scanner for joining a trip. Returns the extracted
/// invite code (via [Navigator.pop]) once a valid trip QR is detected.
///
/// Trip QR codes encode either a raw invite code or a share URL of the form
/// `https://miane.app/trip/<inviteCode>` (see trip_share_sheet.dart). Both are
/// handled by [_extractInviteCode].
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
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final code = _extractInviteCode(raw);
      if (code != null && code.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
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
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.4),
        middle: const Text('Quét mã tham gia',
            style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _controller.toggleTorch(),
          child: const Icon(CupertinoIcons.bolt_fill,
              color: CupertinoColors.white),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Simple viewfinder overlay.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.iosBlue, width: 3),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Text(
              'Đưa mã QR chuyến đi vào khung để tham gia',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd(color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
