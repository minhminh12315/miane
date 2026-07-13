import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/receipt_text_recognizer.dart';
import '../../domain/models/scan_bill_result.dart';
import '../../domain/services/vn_receipt_parser.dart';

part 'scan_bill_controller.g.dart';

enum ScanBillStatus { idle, recognizing, success, error }

/// What kind of image is being scanned — an itemized bill/receipt, or a
/// bank-transfer slip (chuyển khoản). Selects the parsing strategy.
enum ScanMode { bill, transfer }

class ScanBillState {
  final ScanBillStatus status;
  final File? selectedImage;
  final ScanBillResult? result;
  final String? errorMessage;

  const ScanBillState({
    this.status = ScanBillStatus.idle,
    this.selectedImage,
    this.result,
    this.errorMessage,
  });

  ScanBillState copyWith({
    ScanBillStatus? status,
    File? selectedImage,
    ScanBillResult? result,
    String? errorMessage,
  }) {
    return ScanBillState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class ScanBillController extends _$ScanBillController {
  ReceiptTextRecognizer? _recognizer;

  @override
  ScanBillState build() {
    _recognizer = ReceiptTextRecognizer();
    ref.onDispose(() => _recognizer?.dispose());
    return const ScanBillState();
  }

  Future<void> scanReceipt(
    File imageFile, {
    String? fallbackDescription,
    ScanMode mode = ScanMode.bill,
  }) async {
    state = state.copyWith(
      status: ScanBillStatus.recognizing,
      selectedImage: imageFile,
      errorMessage: null,
    );

    final label = mode == ScanMode.transfer ? 'biên lai' : 'hóa đơn';

    try {
      final lines = await _recognizer!.recognizeLines(imageFile);
      final parser = VnReceiptParser();
      final result = mode == ScanMode.transfer
          ? parser.parseTransferSlip(lines,
              fallbackDescription: fallbackDescription)
          : parser.parse(lines, fallbackDescription: fallbackDescription);

      if (result.items.isEmpty && result.totalAmount <= 0) {
        state = state.copyWith(
          status: ScanBillStatus.error,
          errorMessage:
              'Không thể đọc $label. Vui lòng chụp lại ảnh rõ hơn.',
        );
        return;
      }

      state = state.copyWith(status: ScanBillStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: ScanBillStatus.error,
        errorMessage: 'Không thể đọc $label. Vui lòng chụp lại ảnh rõ hơn.',
      );
    }
  }

  void updateResult(ScanBillResult result) {
    state = state.copyWith(result: result);
  }

  void reset() {
    state = const ScanBillState();
  }
}
