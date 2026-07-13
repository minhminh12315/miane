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
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    _navigated = false;
    await ref.read(scanBillControllerProvider.notifier).scanReceipt(
          File(picked.path),
          fallbackDescription: widget.destination,
          mode: widget.mode,
        );
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

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(isTransfer ? 'Quét biên lai' : 'Quét hóa đơn'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Image.file(
                    state.selectedImage!,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              if (state.status == ScanBillStatus.recognizing) ...[
                const IosLoading(),
                const SizedBox(height: 12),
                Text('Đang quét $noun...', style: AppTheme.bodyMd()),
              ] else ...[
                if (state.status == ScanBillStatus.error &&
                    state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMd(color: AppTheme.iosRed),
                    ),
                  ),
                IosPrimaryButton(
                  label: isTransfer
                      ? '📷 Chụp biên lai chuyển khoản'
                      : '📷 Chụp ảnh hóa đơn',
                  onPressed: () => _pick(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                IosSecondaryButton(
                  label: 'Chọn từ thư viện ảnh',
                  icon: CupertinoIcons.photo,
                  onPressed: () => _pick(ImageSource.gallery),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
