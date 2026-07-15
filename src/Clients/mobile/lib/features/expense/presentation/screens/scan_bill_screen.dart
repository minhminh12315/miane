import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../home/domain/models/trip_models.dart';
import '../controllers/scan_bill_controller.dart';
import 'scan_result_review_screen.dart';

/// Entry point of the on-device receipt scanning flow: capture/pick a photo,
/// run the on-device text recognizer + Vietnamese parser, then hand off to
/// the review screen. No image or data ever leaves the device for this step
/// — see AI_OCR_LOCAL_REQUIREMENTS.md.
class ScanBillScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String baseCurrency;
  final List<TripMemberModel> members;
  final String? destination;
  final ScanMode mode;

  const ScanBillScreen({
    super.key,
    required this.tripId,
    required this.baseCurrency,
    required this.members,
    this.destination,
    this.mode = ScanMode.bill,
  });

  @override
  ConsumerState<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends ConsumerState<ScanBillScreen> {
  final _picker = ImagePicker();
  bool _navigated = false;

  Future<void> _pick(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      await showIosMessage(
        context,
        message: source == ImageSource.camera
            ? 'Không có camera trên thiết bị này. Hãy chọn ảnh từ thư viện.'
            : 'Không thể mở thư viện ảnh.',
        isError: true,
      );
      return;
    }
    if (picked == null) return;

    _navigated = false;
    await ref.read(scanBillControllerProvider.notifier).scanReceipt(
          File(picked.path),
          fallbackDescription: widget.destination,
          mode: widget.mode,
        );
  }

  /// Native iOS "add photo" pattern: one tappable area, tap opens an action
  /// sheet offering camera vs. library instead of two permanently-stacked
  /// buttons. `image_picker` itself reports a clear error if `.camera` is
  /// requested where there's no camera (e.g. the Simulator) — the library
  /// option next to it is always available regardless.
  Future<void> _showSourcePicker() async {
    final action = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            child: const Text('Chụp ảnh'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            child: const Text('Chọn từ thư viện ảnh'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
    if (action != null) await _pick(action);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanBillControllerProvider);

    ref.listen(scanBillControllerProvider, (previous, next) {
      if (next.status == ScanBillStatus.success &&
          next.result != null &&
          !_navigated) {
        _navigated = true;
        Navigator.of(context)
            .push(
          CupertinoPageRoute(
            builder: (_) => ScanResultReviewScreen(
              tripId: widget.tripId,
              baseCurrency: widget.baseCurrency,
              members: widget.members,
              initialImage: next.selectedImage,
              initialResult: next.result!,
            ),
          ),
        )
            .then((_) {
          ref.read(scanBillControllerProvider.notifier).reset();
        });
      }
    });

    final isTransfer = widget.mode == ScanMode.transfer;
    final noun = isTransfer ? 'biên lai chuyển khoản' : 'hóa đơn';
    final isRecognizing = state.status == ScanBillStatus.recognizing;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(isTransfer ? 'Quét biên lai' : 'Quét hóa đơn'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _UploadZone(
                          image: state.selectedImage,
                          isBusy: isRecognizing,
                          isTransfer: isTransfer,
                          onTap: isRecognizing ? null : _showSourcePicker,
                        ),
                        const SizedBox(height: 20),
                        if (isRecognizing)
                          Text('Đang quét $noun...', style: AppTheme.bodyMd())
                        else ...[
                          Text(
                            isTransfer
                                ? 'Quét biên lai chuyển khoản'
                                : 'Quét hóa đơn',
                            style: AppTheme.titleSm(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isTransfer
                                ? 'Số tiền và nội dung được tự động điền từ ảnh chụp màn hình giao dịch.'
                                : 'Món, số lượng và giá tiền được tự động điền từ ảnh hóa đơn.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodySm(
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                        if (state.status == ScanBillStatus.error &&
                            state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMd(color: AppTheme.iosRed),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isRecognizing)
                IosPrimaryButton(
                  label: state.selectedImage == null
                      ? 'Chọn ảnh $noun'
                      : 'Chọn ảnh khác',
                  onPressed: _showSourcePicker,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tappable upload surface: a dashed-style rounded card that previews
/// the picked photo once one exists, or an icon + hint while empty —
/// mirrors the native "add attachment" drop-zone pattern instead of a bare
/// pair of buttons floating on the screen.
class _UploadZone extends StatelessWidget {
  final File? image;
  final bool isBusy;
  final bool isTransfer;
  final VoidCallback? onTap;

  const _UploadZone({
    required this.image,
    required this.isBusy,
    required this.isTransfer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 240.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: image == null
              ? Border.all(
                  color: AppTheme.iosBorderDark,
                  width: 1.4,
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null) Image.file(image!, fit: BoxFit.cover),
            if (image != null && isBusy)
              ColoredBox(color: CupertinoColors.black.withValues(alpha: 0.45)),
            if (image == null || isBusy)
              Center(
                child: isBusy
                    ? const CupertinoActivityIndicator(
                        radius: 14, color: CupertinoColors.white)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.iosBlue.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTransfer
                                  ? CupertinoIcons.building_2_fill
                                  : CupertinoIcons.doc_text_viewfinder,
                              color: AppTheme.iosBlue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chạm để chọn ảnh',
                            style: AppTheme.bodySm(color: AppTheme.iosBlue),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
