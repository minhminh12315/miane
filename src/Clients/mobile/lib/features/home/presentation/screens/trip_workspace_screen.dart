import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../expense/presentation/controllers/expense_controller.dart';
import '../../../expense/presentation/controllers/pool_controller.dart';
import '../../../expense/domain/models/expense_models.dart';
import '../../domain/models/trip_models.dart';
import '../../data/repositories/trip_repository_impl.dart';
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
  ConsumerState<TripWorkspaceScreen> createState() => _TripWorkspaceScreenState();
}

class _TripWorkspaceScreenState extends ConsumerState<TripWorkspaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    final expensesState = ref.watch(tripExpensesProvider(widget.tripId));
    final balancesState = ref.watch(tripBalancesProvider(widget.tripId));
    final poolState = ref.watch(tripPoolControllerProvider(widget.tripId));
    final detailsState = ref.watch(tripDetailsProvider(widget.tripId));
    final userIdState = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.tripName,
          style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAzure,
          labelColor: kLight,
          unselectedLabelColor: kLight.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Số dư nợ'),
            Tab(text: 'Quỹ nhóm'),
            Tab(text: 'Thành viên'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview & Transactions
          _buildOverviewTab(expensesState, poolState, kNavy, kAzure, kGold, kLight),
          // Tab 2: Debt Balances
          _buildBalancesTab(balancesState, detailsState, userIdState, kNavy, kAzure, kGold, kLight),
          // Tab 3: Trip Pool
          _buildPoolTab(poolState, detailsState, kNavy, kAzure, kGold, kLight),
          // Tab 4: Members
          _buildMembersTab(detailsState, kNavy, kAzure, kGold, kLight),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAzure,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddExpenseDialog(context, detailsState),
        child: const Icon(Icons.add_rounded, color: kLight, size: 28),
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<List<ExpenseModel>> expensesState,
    AsyncValue<TripPoolModel?> poolState,
    Color kNavy, Color kAzure, Color kGold, Color kLight
  ) {
    return expensesState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.iosBlue)),
      error: (err, stack) => Center(child: Text('Lỗi: $err', style: TextStyle(color: AppTheme.iosRed))),
      data: (expenses) {
        final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        final poolBalance = poolState.value?.balance ?? 0.0;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tripExpensesProvider(widget.tripId));
            ref.invalidate(tripPoolControllerProvider(widget.tripId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Itinerary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch trình tiếp theo',
                        style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: kNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: AppTheme.thinBorder,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: kAzure.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.map_rounded, color: kAzure, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tham quan & Check-in',
                                    style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.destination} • Tự do khám phá',
                                    style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.5), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: kLight, size: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Group Budget summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: AppTheme.thinBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan tài chính nhóm',
                          style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đã chi tiêu:',
                              style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.7), fontSize: 14),
                            ),
                            Text(
                              '${_formatMoney(totalSpent)} ${widget.baseCurrency}',
                              style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số dư quỹ nhóm:',
                              style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.7), fontSize: 14),
                            ),
                            Text(
                              '${_formatMoney(poolBalance)} ${widget.baseCurrency}',
                              style: GoogleFonts.beVietnamPro(color: kGold, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Transaction List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'Lịch sử chi tiêu (${expenses.length})',
                    style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Transactions
              if (expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Chưa có khoản chi tiêu nào.',
                      style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.4)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ex = expenses[index];
                        final isPool = ex.isPaidFromPool;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: AppTheme.thinBorder,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isPool ? kGold : kAzure).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPool ? Icons.pix_rounded : Icons.payments_rounded,
                                  color: isPool ? kGold : kAzure,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.description,
                                      style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPool ? 'Quỹ chi trả' : 'Cá nhân trả • ${_formatDate(ex.createdAt)}',
                                      style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_formatMoney(ex.amount)} ${ex.currency}',
                                style: GoogleFonts.beVietnamPro(
                                  color: isPool ? kGold : kLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: expenses.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab(
    AsyncValue<TripBalancesModel> balancesState,
    AsyncValue<TripDetailModel> detailsState,
    AsyncValue<String?> userIdState,
    Color kNavy, Color kAzure, Color kGold, Color kLight
  ) {
    return balancesState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.iosBlue)),
      error: (err, stack) => Center(child: Text('Lỗi: $err', style: TextStyle(color: AppTheme.iosRed))),
      data: (balances) {
        final unsettled = balances.unsettledDebts;
        final settled = balances.settledDebts;

        final currentUserId = userIdState.value;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tripBalancesProvider(widget.tripId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Các khoản cần thanh toán',
                    style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (unsettled.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('Mọi số dư đã được đơn giản hóa & thanh toán xong! 🎉'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = unsettled[index];
                        final isOwedByMe = debt.fromUserId.toLowerCase() == currentUserId?.toLowerCase();

                        // Try to resolve member names
                        final fromName = _getMemberName(debt.fromUserId, detailsState);
                        final toName = _getMemberName(debt.toUserId, detailsState);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: AppTheme.thinBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: isOwedByMe ? 'Bạn ' : '$fromName ',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(text: 'nợ '),
                                          TextSpan(
                                            text: debt.toUserId.toLowerCase() == currentUserId?.toLowerCase() ? 'Bạn' : toName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Số tiền: ${_formatMoney(debt.amount)} ${debt.currency}',
                                      style: GoogleFonts.beVietnamPro(color: kAzure, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwedByMe)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAzure,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ref.read(tripBalancesProvider(widget.tripId).notifier).settle(debt.debtRecordId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Thanh toán khoản nợ thành công!'),
                                            backgroundColor: AppTheme.iosGreen,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi thanh toán: ${e.toString().replaceAll('ApiException: ', '')}'),
                                            backgroundColor: AppTheme.iosRed,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text('Trả nợ', style: GoogleFonts.beVietnamPro(color: kLight, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: unsettled.length,
                    ),
                  ),
                ),

              // Settled debts
              if (settled.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                    child: Text(
                      'Lịch sử thanh toán xong',
                      style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = settled[index];
                        final fromName = _getMemberName(debt.fromUserId, detailsState);
                        final toName = _getMemberName(debt.toUserId, detailsState);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kNavy.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kLight.withOpacity(0.1), width: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$fromName đã trả cho $toName',
                                  style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.5), fontSize: 13),
                                ),
                              ),
                              Text(
                                '${_formatMoney(debt.amount)} ${debt.currency}',
                                style: GoogleFonts.beVietnamPro(color: Colors.greenAccent[200], fontSize: 13, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: settled.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoolTab(
    AsyncValue<TripPoolModel?> poolState,
    AsyncValue<TripDetailModel> detailsState,
    Color kNavy, Color kAzure, Color kGold, Color kLight
  ) {
    return poolState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.iosBlue)),
      error: (err, stack) => Center(child: Text('Lỗi: $err', style: TextStyle(color: AppTheme.iosRed))),
      data: (pool) {
        final contributions = pool?.contributions ?? [];
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tripPoolControllerProvider(widget.tripId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: AppTheme.thinBorder,
                    ),
                    child: Column(
                      children: [
                        Text('Số dư Quỹ nhóm hiện tại', style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatMoney(pool?.balance ?? 0.0)} ${pool?.currency ?? widget.baseCurrency}',
                          style: GoogleFonts.inter(color: kGold, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => _showContributeDialog(context),
                          icon: const Icon(Icons.add_card_rounded, color: Colors.black),
                          label: Text('Đóng góp vào Quỹ', style: GoogleFonts.beVietnamPro(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('Lịch sử đóng góp', style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              if (contributions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Chưa có thành viên nào đóng góp quỹ.', style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.4))),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = contributions[index];
                        final memberName = _getMemberName(c.userId, detailsState);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: AppTheme.thinBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(memberName, style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(c.contributedAt), style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.4), fontSize: 11)),
                                ],
                              ),
                              Text(
                                '+${_formatMoney(c.amount)} ${pool?.currency ?? widget.baseCurrency}',
                                style: GoogleFonts.beVietnamPro(color: Colors.greenAccent[200], fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: contributions.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(
    AsyncValue<TripDetailModel> detailsState,
    Color kNavy, Color kAzure, Color kGold, Color kLight
  ) {
    return detailsState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.iosBlue)),
      error: (err, stack) => Center(child: Text('Lỗi: $err', style: TextStyle(color: AppTheme.iosRed))),
      data: (details) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thành viên nhóm (${details.members.length})', style: GoogleFonts.inter(color: kLight, fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _handleLeaveTrip(context),
                      icon: Icon(Icons.logout_rounded, color: kLight, size: 16),
                      label: Text('Rời chuyến', style: GoogleFonts.beVietnamPro(color: kLight, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = details.members[index];
                    final isOwner = member.role == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: AppTheme.thinBorder,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: kAzure.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_rounded, color: kAzure),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.nickName ?? 'Thành viên mới',
                                    style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOwner ? 'Trưởng nhóm' : 'Thành viên',
                                    style: GoogleFonts.beVietnamPro(color: isOwner ? kGold : kLight.withOpacity(0.5), fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (member.userTier > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('PRO', style: GoogleFonts.beVietnamPro(color: kGold, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: details.members.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showContributeDialog(BuildContext context) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.canvasDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Đóng góp Quỹ nhóm',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Số tiền đóng góp (${widget.baseCurrency})',
              labelStyle: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.6), fontSize: 13),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () async {
                final amountVal = double.tryParse(amountController.text.trim());
                if (amountVal != null && amountVal > 0) {
                  try {
                    await ref.read(tripPoolControllerProvider(widget.tripId).notifier).contribute(amountVal, widget.baseCurrency);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đóng góp quỹ thành công!'), backgroundColor: AppTheme.iosGreen),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi đóng góp: ${e.toString().replaceAll('ApiException: ', '')}'), backgroundColor: AppTheme.iosRed),
                      );
                    }
                  }
                }
              },
              child: const Text('Đóng góp', style: TextStyle(color: AppTheme.iosGold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, AsyncValue<TripDetailModel> detailsState) {
    detailsState.whenData((details) {
      final descController = TextEditingController();
      final amountController = TextEditingController();
      int selectedSplitType = 0; // 0: Equal, 1: Custom, 3: TripPool

      // Track participants (equal split) or amounts (custom split)
      final List<String> selectedUserIds = details.members.map((m) => m.userId).toList();
      final Map<String, TextEditingController> customAmountControllers = {
        for (var m in details.members) m.userId: TextEditingController()
      };

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: AppTheme.canvasDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  'Thêm chi tiêu mới',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: descController,
                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Nội dung chi tiêu',
                          labelStyle: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Tổng số tiền (${widget.baseCurrency})',
                          labelStyle: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Split Type selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hình thức chia:', style: TextStyle(color: Colors.white, fontSize: 12)),
                          DropdownButton<int>(
                            value: selectedSplitType,
                            dropdownColor: AppTheme.canvasDark,
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Chia đều')),
                              DropdownMenuItem(value: 1, child: Text('Tùy chỉnh')),
                              DropdownMenuItem(value: 3, child: Text('Trả bằng Quỹ')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedSplitType = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dynamic split widgets depending on type
                      if (selectedSplitType == 0) ...[
                        Text('Ai sẽ tham gia chia đều?', style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 8),
                        ...details.members.map((m) {
                          final isChecked = selectedUserIds.contains(m.userId);
                          return CheckboxListTile(
                            title: Text(m.nickName ?? 'Thành viên', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            value: isChecked,
                            activeColor: AppTheme.iosBlue,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedUserIds.add(m.userId);
                                } else {
                                  selectedUserIds.remove(m.userId);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ] else if (selectedSplitType == 1) ...[
                        Text('Nhập số tiền cho từng thành viên:', style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 8),
                        ...details.members.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(m.nickName ?? 'Thành viên', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: customAmountControllers[m.userId],
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.surfaceDark,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else if (selectedSplitType == 3) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Khoản chi tiêu này sẽ được thanh toán trực tiếp từ Số dư quỹ nhóm, các thành viên không phát sinh nợ mới.',
                            style: TextStyle(color: AppTheme.iosGold, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.5))),
                  ),
                  TextButton(
                    onPressed: () async {
                      final desc = descController.text.trim();
                      final totalAmountVal = double.tryParse(amountController.text.trim());
                      if (desc.isEmpty || totalAmountVal == null || totalAmountVal <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng điền nội dung và số tiền hợp lệ'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      // Prepare Splits payload
                      List<Map<String, dynamic>> splits = [];

                      if (selectedSplitType == 0) {
                        // Equal splits
                        if (selectedUserIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người tham gia chia tiền'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }
                        splits = selectedUserIds.map((uid) => {
                          'userId': uid,
                          'amount': null,
                          'percentage': null,
                        }).toList();
                      } else if (selectedSplitType == 1) {
                        // Custom splits
                        double customTotal = 0.0;
                        for (var m in details.members) {
                          final amt = double.tryParse(customAmountControllers[m.userId]?.text.trim() ?? '');
                          if (amt != null && amt > 0) {
                            customTotal += amt;
                            splits.add({
                              'userId': m.userId,
                              'amount': amt,
                              'percentage': null,
                            });
                          }
                        }

                        if (customTotal != totalAmountVal) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tổng số tiền tùy chỉnh ($customTotal) phải khớp với Tổng số tiền chi tiêu ($totalAmountVal)'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                      } else if (selectedSplitType == 3) {
                        // TripPool splits: backend splits equally among all members from pool
                        splits = details.members.map((m) => {
                          'userId': m.userId,
                          'amount': null,
                          'percentage': null,
                        }).toList();
                      }

                      try {
                        await ref.read(tripExpensesProvider(widget.tripId).notifier).createExpense(
                          description: desc,
                          amount: totalAmountVal,
                          currency: widget.baseCurrency,
                          tripBaseCurrency: widget.baseCurrency,
                          splitType: selectedSplitType,
                          splits: splits,
                        );

                        // Trigger refresh on related states
                        ref.invalidate(tripBalancesProvider(widget.tripId));
                        ref.invalidate(tripPoolControllerProvider(widget.tripId));

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thêm chi tiêu thành công!'), backgroundColor: AppTheme.iosGreen),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi tạo chi tiêu: ${e.toString().replaceAll('ApiException: ', '')}'), backgroundColor: AppTheme.iosRed),
                          );
                        }
                      }
                    },
                    child: const Text('Thêm', style: TextStyle(color: AppTheme.iosBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  void _handleLeaveTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.canvasDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Xác nhận rời nhóm',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn rời khỏi chuyến đi này không? Nếu bạn có nợ chưa thanh toán, bạn không thể rời chuyến.',
            style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: Colors.white.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final repo = ref.read(tripRepositoryProvider);
                  await repo.leaveTrip(widget.tripId);
                  ref.invalidate(tripsProvider);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Exit workspace
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã rời khỏi chuyến đi thành công'), backgroundColor: AppTheme.iosGreen),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi rời chuyến: ${e.toString().replaceAll('ApiException: ', '')}'), backgroundColor: AppTheme.iosRed),
                    );
                  }
                }
              },
              child: Text('Rời chuyến', style: GoogleFonts.beVietnamPro(color: AppTheme.iosRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _getMemberName(String userId, AsyncValue<TripDetailModel> detailsState) {
    return detailsState.maybeWhen(
      data: (details) {
        final member = details.members.firstWhere((m) => m.userId.toLowerCase() == userId.toLowerCase(), orElse: () => TripMemberModel(userId: userId, role: 1, userTier: 0, joinedAt: DateTime.now()));
        return member.nickName ?? 'Thành viên';
      },
      orElse: () => 'Thành viên',
    );
  }

  String _formatMoney(double amount) {
    final int val = amount.round();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return val.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
