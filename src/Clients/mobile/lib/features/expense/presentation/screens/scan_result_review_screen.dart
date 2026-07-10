import 'dart:io';

import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../home/domain/models/trip_models.dart';
import '../../domain/models/scan_bill_result.dart';
import '../controllers/expense_controller.dart';
import '../controllers/pool_controller.dart';

/// Human-in-the-loop review of the on-device OCR draft. The rule-based
/// parser (VnReceiptParser) cannot "reason" about ambiguous receipts the way
/// an AI model could, so every field here is editable before it becomes a
/// real expense. See AI_OCR_LOCAL_REQUIREMENTS.md FR-9/FR-10.
class ScanResultReviewScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String baseCurrency;
  final List<TripMemberModel> members;
  final File? initialImage;
  final ScanBillResult initialResult;

  const ScanResultReviewScreen({
    super.key,
    required this.tripId,
    required this.baseCurrency,
    required this.members,
    required this.initialResult,
    this.initialImage,
  });

  @override
  ConsumerState<ScanResultReviewScreen> createState() =>
      _ScanResultReviewScreenState();
}

class _ItemControllers {
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;

  _ItemControllers(ScannedItem item)
      : name = TextEditingController(text: item.name),
        price = TextEditingController(text: item.unitPrice.toStringAsFixed(0)),
        quantity = TextEditingController(text: item.quantity.toString());

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

class _ScanResultReviewScreenState
    extends ConsumerState<ScanResultReviewScreen> {
  late final TextEditingController _descController;
  late final List<_ItemControllers> _itemControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descController =
        TextEditingController(text: widget.initialResult.description);
    _itemControllers = widget.initialResult.items
        .map((item) => _ItemControllers(item))
        .toList();
  }

  @override
  void dispose() {
    _descController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _calculatedTotal {
    var sum = 0.0;
    for (final c in _itemControllers) {
      final price = double.tryParse(c.price.text.trim()) ?? 0;
      final qty = int.tryParse(c.quantity.text.trim()) ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(_ItemControllers(
        const ScannedItem(name: '', unitPrice: 0, quantity: 1),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers.removeAt(index).dispose();
    });
  }

  Future<void> _confirmAndSave() async {
    final description = _descController.text.trim();
    final total = _calculatedTotal;

    if (description.isEmpty) {
      await showIosMessage(context,
          message: 'Vui lòng nhập nội dung khoản chi.', isError: true);
      return;
    }
    if (total <= 0) {
      await showIosMessage(context,
          message: 'Tổng tiền phải lớn hơn 0.', isError: true);
      return;
    }
    if (widget.members.isEmpty) {
      await showIosMessage(context,
          message: 'Chuyến đi chưa có thành viên để chia tiền.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final splits = widget.members
          .map((member) => {
                'userId': member.userId,
                'amount': null,
                'percentage': null,
              })
          .toList();

      await ref
          .read(tripExpensesProvider(widget.tripId).notifier)
          .createExpense(
            description: description,
            amount: total,
            currency: widget.baseCurrency,
            tripBaseCurrency: widget.baseCurrency,
            splitType: 0,
            splits: splits,
          );

      ref.invalidate(tripBalancesProvider(widget.tripId));
      ref.invalidate(tripPoolControllerProvider(widget.tripId));

      if (mounted) {
        await showIosMessage(context,
            message: 'Khoản chi đã được tạo thành công!');
        if (mounted) {
          Navigator.of(context)
            ..pop()
            ..pop();
        }
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Lỗi tạo chi tiêu: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculatedTotal;
    final hasDiscrepancy = widget.initialResult.hasDiscrepancy;

    return cupertino.CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      navigationBar: const cupertino.CupertinoNavigationBar(
        middle: Text('Xác nhận hóa đơn'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  if (widget.initialImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Image.file(widget.initialImage!,
                          height: 140, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: _descController,
                    label: 'Nội dung',
                    placeholder: 'Ăn tối, taxi, khách sạn...',
                    prefixIcon: cupertino.CupertinoIcons.doc_text,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danh sách món', style: AppTheme.titleSm()),
                      cupertino.CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _addItem,
                        child: const Text('+ Thêm mục'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _itemControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ItemEditor(
                        controllers: _itemControllers[i],
                        onChanged: () => setState(() {}),
                        onDelete: () => _removeItem(i),
                      ),
                    ),
                  if (_itemControllers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Không nhận diện được món nào. Bạn có thể thêm thủ công.',
                        style: AppTheme.bodySm(
                          color: cupertino.CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (hasDiscrepancy)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.iosGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                              cupertino.CupertinoIcons.exclamationmark_triangle,
                              color: AppTheme.iosGold,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tổng nhận diện (${formatMoney(widget.initialResult.totalAmount)}) khác với tổng các món. Vui lòng kiểm tra lại.',
                              style: AppTheme.bodySm(color: AppTheme.iosGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng cộng', style: AppTheme.titleSm()),
                        Text(
                          '${formatMoney(total)} ${widget.baseCurrency}',
                          style: AppTheme.titleSm(color: AppTheme.iosBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: IosSecondaryButton(
                      label: 'Hủy',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IosPrimaryButton(
                      label: 'Xác nhận & Lưu',
                      isLoading: _isSaving,
                      onPressed: _confirmAndSave,
                    ),
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

class _ItemEditor extends StatelessWidget {
  final _ItemControllers controllers;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemEditor({
    required this.controllers,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: IosTextField(
                  controller: controllers.name,
                  placeholder: 'Tên món',
                  onChanged: (_) => onChanged(),
                ),
              ),
              cupertino.CupertinoButton(
                padding: const EdgeInsets.only(left: 8),
                onPressed: onDelete,
                child: const Icon(cupertino.CupertinoIcons.trash,
                    color: AppTheme.iosRed, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: IosTextField(
                  controller: controllers.price,
                  placeholder: 'Đơn giá',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IosTextField(
                  controller: controllers.quantity,
                  placeholder: 'SL',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
