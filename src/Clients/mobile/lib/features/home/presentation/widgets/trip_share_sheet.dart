import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/payments/qr_download_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../domain/models/trip_models.dart';

Future<void> showTripShareSheet(
  BuildContext context,
  TripCreationResult result,
) {
  return showGlassBottomSheet<void>(
    context: context,
    heightFactor: 0.64,
    builder: (_) => _TripShareSheet(result: result),
  );
}

class _TripShareSheet extends StatelessWidget {
  final TripCreationResult result;

  const _TripShareSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheetScaffold(
      title: 'Mời bạn đồng hành',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Center(
            child: Container(
              width: 188,
              height: 188,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.iosBlue.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: QrImageView(
                data: result.shareUrl,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: CupertinoColors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: CupertinoColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            result.inviteCode.isEmpty ? 'TRIP READY' : result.inviteCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.shareUrl,
            textAlign: TextAlign.center,
            style: AppTheme.bodySm(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ShareAction(
                  icon: CupertinoIcons.link,
                  label: 'Sao chép link',
                  onTap: () => _copy(context, result.shareUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareAction(
                  icon: CupertinoIcons.number,
                  label: 'Sao chép mã',
                  onTap: () => _copy(context, result.inviteCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShareAction(
                  icon: CupertinoIcons.arrow_down_doc,
                  label: 'Tải QR',
                  onTap: () => _downloadQr(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareAction(
                  icon: CupertinoIcons.qrcode,
                  label: 'Chia sẻ QR',
                  onTap: () => Share.share(
                    '${result.shareUrl}\nCode: ${result.inviteCode}',
                    subject: 'MIANE Trip ${result.inviteCode}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQr(BuildContext context) async {
    try {
      final bytes = await renderQrPngBytes(
        data: result.shareUrl,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: CupertinoColors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: CupertinoColors.black,
        ),
      );
      final saved = await saveQrPngFile(
        bytes: bytes,
        fileName: 'miane-trip-${result.inviteCode}',
      );
      if (!context.mounted) return;
      await showIosMessage(
        context,
        message: saved ? 'Đã tải mã QR.' : 'Đã hủy tải mã QR.',
      );
    } catch (error) {
      if (!context.mounted) return;
      await showIosMessage(
        context,
        message: 'Không thể tải mã QR: $error',
        isError: true,
      );
    }
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    await showIosMessage(
      context,
      title: 'Đã sao chép',
      message: value,
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.iosBlue, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titleSm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
