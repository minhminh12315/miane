import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../expense/domain/models/expense_models.dart';
import '../../../expense/presentation/controllers/expense_controller.dart';
import '../../../expense/presentation/controllers/pool_controller.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';

class TripWorkspaceScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;
  final String destination;
  final String baseCurrency;

  const TripWorkspaceScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.destination,
    required this.baseCurrency,
  });

  @override
  ConsumerState<TripWorkspaceScreen> createState() =>
      _TripWorkspaceScreenState();
}

class _TripWorkspaceScreenState extends ConsumerState<TripWorkspaceScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(tripExpensesProvider(widget.tripId));
    final balancesState = ref.watch(tripBalancesProvider(widget.tripId));
    final poolState = ref.watch(tripPoolControllerProvider(widget.tripId));
    final detailsState = ref.watch(tripDetailsProvider(widget.tripId));
    final userIdState = ref.watch(currentUserIdProvider);

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.tripName),
        previousPageTitle: 'Miane',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddExpenseSheet(context, detailsState),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTab,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Tổng quan'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Nợ'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Quỹ'),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Thành viên'),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) setState(() => _selectedTab = value);
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildOverviewTab(expensesState, poolState),
                  _buildBalancesTab(balancesState, detailsState, userIdState),
                  _buildPoolTab(poolState, detailsState),
                  _buildMembersTab(detailsState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<List<ExpenseModel>> expensesState,
    AsyncValue<TripPoolModel?> poolState,
  ) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(tripExpensesProvider(widget.tripId));
            ref.invalidate(tripPoolControllerProvider(widget.tripId));
          },
        ),
        expensesState.when(
          loading: () => const SliverFillRemaining(child: IosLoading()),
          error: (err, stack) => SliverFillRemaining(
            child: IosEmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Không tải được chi tiêu',
              message: err.toString(),
            ),
          ),
          data: (expenses) {
            final totalSpent = expenses.fold<double>(
                0, (sum, expense) => sum + expense.amount);
            final poolBalance = poolState.valueOrNull?.balance ?? 0;

            return SliverList(
              delegate: SliverChildListDelegate(
                [
                  IosSection(
                    header: 'Lịch trình',
                    children: [
                      IosListTile(
                        icon: CupertinoIcons.map,
                        title: 'Tham quan và check-in',
                        subtitle: '${widget.destination} • Tự do khám phá',
                      ),
                    ],
                  ),
                  IosSection(
                    header: 'Tài chính nhóm',
                    children: [
                      IosListTile(
                        icon: CupertinoIcons.money_dollar,
                        title: 'Đã chi tiêu',
                        value:
                            '${formatMoney(totalSpent)} ${widget.baseCurrency}',
                      ),
                      IosListTile(
                        icon: CupertinoIcons.creditcard,
                        iconColor: AppTheme.iosGold,
                        title: 'Số dư quỹ nhóm',
                        value:
                            '${formatMoney(poolBalance)} ${widget.baseCurrency}',
                      ),
                    ],
                  ),
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: IosEmptyState(
                        icon: CupertinoIcons.doc_text,
                        title: 'Chưa có chi tiêu',
                        message: 'Nhấn nút + để thêm khoản chi đầu tiên.',
                      ),
                    )
                  else
                    IosSection(
                      header: 'Lịch sử chi tiêu',
                      children: expenses
                          .map((expense) => _ExpenseTile(expense: expense))
                          .toList(),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalancesTab(
    AsyncValue<TripBalancesModel> balancesState,
    AsyncValue<TripDetailModel> detailsState,
    AsyncValue<String?> userIdState,
  ) {
    final currentUserId = userIdState.valueOrNull?.toLowerCase();

    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(tripBalancesProvider(widget.tripId));
          },
        ),
        balancesState.when(
          loading: () => const SliverFillRemaining(child: IosLoading()),
          error: (err, stack) => SliverFillRemaining(
            child: IosEmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Không tải được số dư',
              message: err.toString(),
            ),
          ),
          data: (balances) {
            if (balances.unsettledDebts.isEmpty &&
                balances.settledDebts.isEmpty) {
              return const SliverFillRemaining(
                child: IosEmptyState(
                  icon: CupertinoIcons.check_mark_circled,
                  title: 'Đã cân bằng',
                  message: 'Hiện không có khoản nợ cần thanh toán.',
                ),
              );
            }

            return SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (balances.unsettledDebts.isNotEmpty)
                    IosSection(
                      header: 'Cần thanh toán',
                      children: balances.unsettledDebts.map((debt) {
                        final isOwedByMe =
                            debt.fromUserId.toLowerCase() == currentUserId;
                        final fromName =
                            _getMemberName(debt.fromUserId, detailsState);
                        final toName =
                            _getMemberName(debt.toUserId, detailsState);

                        return IosListTile(
                          icon: CupertinoIcons.arrow_right_arrow_left,
                          iconColor:
                              isOwedByMe ? AppTheme.iosRed : AppTheme.iosBlue,
                          title:
                              '${isOwedByMe ? 'Bạn' : fromName} nợ ${debt.toUserId.toLowerCase() == currentUserId ? 'Bạn' : toName}',
                          subtitle:
                              '${formatMoney(debt.amount)} ${debt.currency}',
                          trailing: isOwedByMe
                              ? CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  onPressed: () => _settleDebt(debt),
                                  child: const Text('Trả'),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  if (balances.settledDebts.isNotEmpty)
                    IosSection(
                      header: 'Đã thanh toán',
                      children: balances.settledDebts.map((debt) {
                        return IosListTile(
                          icon: CupertinoIcons.check_mark,
                          iconColor: AppTheme.iosGreen,
                          title:
                              '${_getMemberName(debt.fromUserId, detailsState)} đã trả ${_getMemberName(debt.toUserId, detailsState)}',
                          subtitle:
                              '${formatMoney(debt.amount)} ${debt.currency}',
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPoolTab(
    AsyncValue<TripPoolModel?> poolState,
    AsyncValue<TripDetailModel> detailsState,
  ) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(tripPoolControllerProvider(widget.tripId));
          },
        ),
        poolState.when(
          loading: () => const SliverFillRemaining(child: IosLoading()),
          error: (err, stack) => SliverFillRemaining(
            child: IosEmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Không tải được quỹ nhóm',
              message: err.toString(),
            ),
          ),
          data: (pool) {
            final contributions = pool?.contributions ?? [];
            final balance = pool?.balance ?? 0;
            final currency = pool?.currency ?? widget.baseCurrency;

            return SliverList(
              delegate: SliverChildListDelegate(
                [
                  IosSection(
                    header: 'Quỹ nhóm',
                    children: [
                      IosListTile(
                        icon: CupertinoIcons.creditcard,
                        iconColor: AppTheme.iosGold,
                        title: 'Số dư hiện tại',
                        value: '${formatMoney(balance)} $currency',
                      ),
                      IosListTile(
                        icon: CupertinoIcons.add_circled,
                        title: 'Đóng góp quỹ',
                        onTap: () => _showContributeDialog(context),
                      ),
                    ],
                  ),
                  if (contributions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: IosEmptyState(
                        icon: CupertinoIcons.creditcard,
                        title: 'Chưa có đóng góp',
                        message:
                            'Các khoản nạp vào quỹ nhóm sẽ hiển thị tại đây.',
                      ),
                    )
                  else
                    IosSection(
                      header: 'Lịch sử đóng góp',
                      children: contributions.map((contribution) {
                        return IosListTile(
                          icon: CupertinoIcons.person,
                          title:
                              _getMemberName(contribution.userId, detailsState),
                          subtitle: _formatDate(contribution.contributedAt),
                          value:
                              '${formatMoney(contribution.amount)} $currency',
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMembersTab(AsyncValue<TripDetailModel> detailsState) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(tripDetailsProvider(widget.tripId));
          },
        ),
        detailsState.when(
          loading: () => const SliverFillRemaining(child: IosLoading()),
          error: (err, stack) => SliverFillRemaining(
            child: IosEmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Không tải được thành viên',
              message: err.toString(),
            ),
          ),
          data: (details) {
            return SliverList(
              delegate: SliverChildListDelegate(
                [
                  IosSection(
                    header: 'Mã mời',
                    footer:
                        'Chia sẻ mã này để mời thêm thành viên vào chuyến đi.',
                    children: [
                      IosListTile(
                        icon: CupertinoIcons.number,
                        title: details.inviteCode,
                        subtitle: details.baseCurrency,
                      ),
                    ],
                  ),
                  IosSection(
                    header: 'Thành viên',
                    children: details.members.map((member) {
                      return IosListTile(
                        icon: CupertinoIcons.person,
                        title: member.nickName ?? 'Thành viên',
                        subtitle:
                            member.role == 0 ? 'Chủ chuyến đi' : 'Thành viên',
                        value: member.userTier == 1 ? 'PRO' : null,
                      );
                    }).toList(),
                  ),
                  IosSection(
                    children: [
                      IosListTile(
                        icon: CupertinoIcons.square_arrow_right,
                        iconColor: AppTheme.iosRed,
                        title: 'Rời chuyến đi',
                        destructive: true,
                        onTap: () => _handleLeaveTrip(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _settleDebt(DebtModel debt) async {
    try {
      await ref
          .read(tripBalancesProvider(widget.tripId).notifier)
          .settle(debt.debtRecordId);
      if (mounted) {
        await showIosMessage(
          context,
          title: 'Đã thanh toán',
          message: 'Khoản nợ đã được đánh dấu là đã trả.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể thanh toán: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    }
  }

  void _showContributeDialog(BuildContext context) {
    final amountController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Đóng góp quỹ'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: IosTextField(
            controller: amountController,
            placeholder: 'Số tiền (${widget.baseCurrency})',
            prefixIcon: CupertinoIcons.money_dollar,
            keyboardType: TextInputType.number,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              try {
                await ref
                    .read(tripPoolControllerProvider(widget.tripId).notifier)
                    .contribute(amount, widget.baseCurrency);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) {
                  await showIosMessage(
                    context,
                    message:
                        'Lỗi đóng góp: ${e.toString().replaceAll('ApiException: ', '')}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Đóng góp'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(
    BuildContext context,
    AsyncValue<TripDetailModel> detailsState,
  ) {
    detailsState.when(
      loading: () =>
          showIosMessage(context, message: 'Đang tải danh sách thành viên.'),
      error: (err, stack) =>
          showIosMessage(context, message: err.toString(), isError: true),
      data: (details) {
        final descController = TextEditingController();
        final amountController = TextEditingController();
        var selectedSplitType = 0;
        final selectedUserIds =
            details.members.map((member) => member.userId).toSet();
        final customAmountControllers = {
          for (final member in details.members)
            member.userId: TextEditingController(),
        };

        showCupertinoModalPopup<void>(
          context: context,
          builder: (sheetContext) {
            return SafeArea(
              child: CupertinoPopupSurface(
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.82,
                  child: StatefulBuilder(
                    builder: (context, setSheetState) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  child: const Text('Hủy'),
                                ),
                                const Spacer(),
                                Text('Thêm chi tiêu',
                                    style: AppTheme.titleSm()),
                                const Spacer(),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _submitExpense(
                                    context: context,
                                    sheetContext: sheetContext,
                                    details: details,
                                    descController: descController,
                                    amountController: amountController,
                                    selectedSplitType: selectedSplitType,
                                    selectedUserIds: selectedUserIds,
                                    customAmountControllers:
                                        customAmountControllers,
                                  ),
                                  child: const Text('Thêm'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                IosTextField(
                                  controller: descController,
                                  label: 'Nội dung',
                                  placeholder: 'Ăn tối, taxi, khách sạn...',
                                  prefixIcon: CupertinoIcons.doc_text,
                                ),
                                const SizedBox(height: 14),
                                IosTextField(
                                  controller: amountController,
                                  label: 'Tổng tiền',
                                  placeholder: '0 ${widget.baseCurrency}',
                                  prefixIcon: CupertinoIcons.money_dollar,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Cách chia',
                                  style: AppTheme.labelSm(
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CupertinoSlidingSegmentedControl<int>(
                                  groupValue: selectedSplitType,
                                  children: const {
                                    0: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Đều'),
                                    ),
                                    1: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Tùy chỉnh'),
                                    ),
                                    3: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Quỹ'),
                                    ),
                                  },
                                  onValueChanged: (value) {
                                    if (value != null) {
                                      setSheetState(
                                          () => selectedSplitType = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (selectedSplitType == 0)
                                  IosSection(
                                    header: 'Người tham gia chia đều',
                                    children: details.members.map((member) {
                                      final checked = selectedUserIds
                                          .contains(member.userId);
                                      return IosListTile(
                                        icon: CupertinoIcons.person,
                                        title: member.nickName ?? 'Thành viên',
                                        trailing: CupertinoSwitch(
                                          value: checked,
                                          onChanged: (value) {
                                            setSheetState(() {
                                              if (value) {
                                                selectedUserIds
                                                    .add(member.userId);
                                              } else {
                                                selectedUserIds
                                                    .remove(member.userId);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else if (selectedSplitType == 1)
                                  Column(
                                    children: details.members.map((member) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: IosTextField(
                                          controller: customAmountControllers[
                                              member.userId]!,
                                          label:
                                              member.nickName ?? 'Thành viên',
                                          placeholder: '0',
                                          prefixIcon:
                                              CupertinoIcons.money_dollar,
                                          keyboardType: TextInputType.number,
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else
                                  const IosSection(
                                    footer:
                                        'Khoản chi này sẽ được thanh toán trực tiếp từ quỹ nhóm và không phát sinh nợ mới.',
                                    children: [
                                      IosListTile(
                                        icon: CupertinoIcons.creditcard,
                                        iconColor: AppTheme.iosGold,
                                        title: 'Trả bằng quỹ nhóm',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitExpense({
    required BuildContext context,
    required BuildContext sheetContext,
    required TripDetailModel details,
    required TextEditingController descController,
    required TextEditingController amountController,
    required int selectedSplitType,
    required Set<String> selectedUserIds,
    required Map<String, TextEditingController> customAmountControllers,
  }) async {
    final desc = descController.text.trim();
    final totalAmount = double.tryParse(amountController.text.trim());
    if (desc.isEmpty || totalAmount == null || totalAmount <= 0) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập nội dung và số tiền hợp lệ.',
        isError: true,
      );
      return;
    }

    var splits = <Map<String, dynamic>>[];
    if (selectedSplitType == 0) {
      if (selectedUserIds.isEmpty) {
        await showIosMessage(
          context,
          message: 'Vui lòng chọn ít nhất một người tham gia chia tiền.',
          isError: true,
        );
        return;
      }
      splits = selectedUserIds
          .map(
            (userId) => {
              'userId': userId,
              'amount': null,
              'percentage': null,
            },
          )
          .toList();
    } else if (selectedSplitType == 1) {
      var customTotal = 0.0;
      for (final member in details.members) {
        final amount = double.tryParse(
          customAmountControllers[member.userId]?.text.trim() ?? '',
        );
        if (amount != null && amount > 0) {
          customTotal += amount;
          splits.add({
            'userId': member.userId,
            'amount': amount,
            'percentage': null,
          });
        }
      }
      if (customTotal != totalAmount) {
        await showIosMessage(
          context,
          message:
              'Tổng tiền tùy chỉnh (${formatMoney(customTotal)}) phải bằng tổng chi (${formatMoney(totalAmount)}).',
          isError: true,
        );
        return;
      }
    } else if (selectedSplitType == 3) {
      splits = details.members
          .map(
            (member) => {
              'userId': member.userId,
              'amount': null,
              'percentage': null,
            },
          )
          .toList();
    }

    try {
      await ref
          .read(tripExpensesProvider(widget.tripId).notifier)
          .createExpense(
            description: desc,
            amount: totalAmount,
            currency: widget.baseCurrency,
            tripBaseCurrency: widget.baseCurrency,
            splitType: selectedSplitType,
            splits: splits,
          );
      ref.invalidate(tripBalancesProvider(widget.tripId));
      ref.invalidate(tripPoolControllerProvider(widget.tripId));
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    } catch (e) {
      if (context.mounted) {
        await showIosMessage(
          context,
          message:
              'Lỗi tạo chi tiêu: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleLeaveTrip(BuildContext context) async {
    final confirmed = await showIosConfirm(
      context,
      title: 'Rời chuyến đi?',
      message:
          'Nếu bạn còn nợ chưa thanh toán, hệ thống có thể không cho rời chuyến.',
      confirmLabel: 'Rời chuyến',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      final repo = ref.read(tripRepositoryProvider);
      await repo.leaveTrip(widget.tripId);
      ref.invalidate(tripsProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        await showIosMessage(
          context,
          message:
              'Lỗi rời chuyến: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    }
  }

  String _getMemberName(
      String userId, AsyncValue<TripDetailModel> detailsState) {
    return detailsState.maybeWhen(
      data: (details) {
        final member = details.members.firstWhere(
          (member) => member.userId.toLowerCase() == userId.toLowerCase(),
          orElse: () => TripMemberModel(
            userId: userId,
            role: 1,
            userTier: 0,
            joinedAt: DateTime.now(),
          ),
        );
        return member.nickName ?? 'Thành viên';
      },
      orElse: () => 'Thành viên',
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final paidFromPool = expense.isPaidFromPool;
    return IosListTile(
      icon: paidFromPool
          ? CupertinoIcons.creditcard
          : CupertinoIcons.money_dollar,
      iconColor: paidFromPool ? AppTheme.iosGold : AppTheme.iosBlue,
      title: expense.description,
      subtitle: paidFromPool
          ? 'Quỹ nhóm chi trả'
          : 'Cá nhân trả • ${_formatDate(expense.createdAt)}',
      value: '${formatMoney(expense.amount)} ${expense.currency}',
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
