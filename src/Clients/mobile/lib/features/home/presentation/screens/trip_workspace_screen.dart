import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/platform/document_open.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../expense/domain/models/expense_models.dart';
import '../../../expense/presentation/controllers/expense_controller.dart';
import '../../../expense/presentation/controllers/pool_controller.dart';
import '../../../expense/presentation/controllers/scan_bill_controller.dart';
import '../../../expense/presentation/screens/scan_bill_screen.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/models/trip_leg_model.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';
import '../widgets/trip_share_sheet.dart';

const _googlePlacesApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

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

class _TripWorkspaceScreenState extends ConsumerState<TripWorkspaceScreen>
    with WidgetsBindingObserver {
  int _selectedTab = 0;
  int _selectedDayIndex = 0;
  final ImagePicker _documentImagePicker = ImagePicker();
  final Map<int, List<_TripActivityDraft>> _dayActivities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A member added on another device (or expenses they created) won't push
    // to an already-open client. Re-fetch trip data whenever the app returns
    // to the foreground so every member sees the shared expense list. The
    // backend returns all trip expenses to any member, so a fresh fetch is
    // all that's needed here.
    if (state == AppLifecycleState.resumed) {
      _refreshTripData();
    }
  }

  void _refreshTripData() {
    ref.invalidate(tripDetailsProvider(widget.tripId));
    ref.invalidate(tripExpensesProvider(widget.tripId));
    ref.invalidate(tripBalancesProvider(widget.tripId));
    ref.invalidate(tripPoolControllerProvider(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(tripExpensesProvider(widget.tripId));
    final balancesState = ref.watch(tripBalancesProvider(widget.tripId));
    final poolState = ref.watch(tripPoolControllerProvider(widget.tripId));
    final detailsState = ref.watch(tripDetailsProvider(widget.tripId));
    final filesState = ref.watch(tripFilesProvider(widget.tripId));
    final userIdState = ref.watch(currentUserIdProvider);
    final coverBytes = ref.watch(tripCoverMemoryProvider)[widget.tripId];
    final details = detailsState.valueOrNull;
    final title = details?.name ?? widget.tripName;
    final destination = details?.destinationLabel ?? widget.destination;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: Stack(
        children: [
          Positioned.fill(
            child: _TripMapBackdrop(
              seed: title,
              coverBytes: coverBytes,
              coverImageUrl: details?.coverImageUrl,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _TripFloatingTopBar(
                    title: title,
                    subtitle: destination,
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: () => showIosMessage(
                      context,
                      title: 'Tìm kiếm',
                      message:
                          'Tìm kiếm trong lịch trình, chi phí, tài liệu và địa điểm sẽ được nối API ở bước sau.',
                    ),
                    onMenu: () => _showTripSettings(context, detailsState),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: _WorkspaceSegmentedTabs(
                    selectedTab: _selectedTab,
                    onChanged: (value) => setState(() => _selectedTab = value),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: switch (_selectedTab) {
                        0 => _buildOverviewTab(
                          expensesState,
                          detailsState,
                          filesState,
                          coverBytes,
                        ),
                        1 => _buildBalancesTab(
                          balancesState,
                          detailsState,
                          userIdState,
                        ),
                        2 => _buildPoolTab(poolState, detailsState),
                        _ => _buildMembersTab(detailsState),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<List<ExpenseModel>> expensesState,
    AsyncValue<TripDetailModel> detailsState,
    AsyncValue<List<TripFileModel>> filesState,
    Uint8List? coverBytes,
  ) {
    final expenses = expensesState.valueOrNull ?? const <ExpenseModel>[];
    final totalSpent = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final details = detailsState.valueOrNull;
    final tripName = details?.name ?? widget.tripName;
    final destination = details?.destinationLabel ?? widget.destination;
    final baseCurrency = details?.baseCurrency ?? widget.baseCurrency;
    final days = _buildTripDays(details);
    final selectedIndex = _selectedDayIndex >= days.length
        ? days.length - 1
        : _selectedDayIndex;
    final selectedDay = days[selectedIndex];
    final selectedActivities = _sortedActivities(
      _dayActivities[selectedIndex] ?? const [],
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(tripDetailsProvider(widget.tripId));
            ref.invalidate(tripExpensesProvider(widget.tripId));
            ref.invalidate(tripPoolControllerProvider(widget.tripId));
            ref.invalidate(tripFilesProvider(widget.tripId));
          },
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: _TripHeroWorkspaceCard(
                  tripName: tripName,
                  destination: destination,
                  dateLabel: _formatTripDateRange(details),
                  coverBytes: coverBytes,
                  coverImageUrl: details?.coverImageUrl,
                  totalSpent: totalSpent,
                  baseCurrency: baseCurrency,
                  memberCount: details?.members.length ?? 1,
                  onShare: () => _showShareSheet(context, details),
                  onSettings: () => _showTripSettings(context, detailsState),
                ),
              ),
              _DaySelector(
                days: days,
                selectedIndex: selectedIndex,
                activityCounts: {
                  for (final entry in _dayActivities.entries)
                    entry.key: entry.value.length,
                },
                onSelected: (index) =>
                    setState(() => _selectedDayIndex = index),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: _DayPlanPanel(
                  dayIndex: selectedIndex,
                  day: selectedDay,
                  destination: destination,
                  activities: selectedActivities,
                  onAddActivity: () => _showAddActivitySheet(
                    selectedIndex,
                    selectedDay,
                    destination,
                  ),
                  onOpenDay: () => _showDayDetailSheet(
                    selectedIndex,
                    selectedDay,
                    destination,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Column(
                  children: [
                    _TripModuleCard(
                      icon: CupertinoIcons.folder_fill,
                      title: 'Tài liệu',
                      subtitle: _documentsSubtitle(filesState),
                      color: AppTheme.iosIndigo,
                      onTap: () => _showDocumentsSheet(),
                    ),
                    const SizedBox(height: 12),
                    _TripModuleCard(
                      icon: CupertinoIcons.money_dollar_circle_fill,
                      title: 'Chi phí',
                      subtitle:
                          '${formatMoney(totalSpent)} $baseCurrency đã ghi',
                      color: AppTheme.iosBlue,
                      onTap: () => _showAddExpenseSheet(context, detailsState),
                    ),
                    const SizedBox(height: 12),
                    _TripModuleCard(
                      icon: CupertinoIcons.cloud_sun_fill,
                      title: 'Thời tiết',
                      subtitle: 'Dự báo 7 ngày tại điểm đến',
                      color: AppTheme.iosIndigo,
                      onTap: () => _showModuleComingSoon('Thời tiết'),
                    ),
                  ],
                ),
              ),
              if (expensesState.hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: _InlineWarning(
                    message:
                        'Chưa tải được chi phí: ${expensesState.error.toString().replaceAll('ApiException: ', '')}',
                  ),
                ),
              const SizedBox(height: 28),
            ],
          ),
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

    return _GlassTabScroll(
      onRefresh: () async =>
          ref.invalidate(tripBalancesProvider(widget.tripId)),
      child: balancesState.when(
        loading: () => const IosLoading(),
        error: (err, stack) => IosEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Không tải được số dư',
          message: err.toString(),
        ),
        data: (balances) {
          if (balances.unsettledDebts.isEmpty &&
              balances.settledDebts.isEmpty) {
            return const IosEmptyState(
              icon: CupertinoIcons.check_mark_circled,
              title: 'Đã cân bằng',
              message: 'Hiện không có khoản nợ cần thanh toán.',
            );
          }

          return Column(
            children: [
              if (balances.unsettledDebts.isNotEmpty)
                IosSection(
                  header: 'Cần thanh toán',
                  children: balances.unsettledDebts.map((debt) {
                    final isOwedByMe =
                        debt.fromUserId.toLowerCase() == currentUserId;
                    final fromName = _getMemberName(
                      debt.fromUserId,
                      detailsState,
                    );
                    final toName = _getMemberName(debt.toUserId, detailsState);

                    return IosListTile(
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      iconColor: isOwedByMe
                          ? AppTheme.iosRed
                          : AppTheme.iosBlue,
                      title:
                          '${isOwedByMe ? 'Bạn' : fromName} nợ ${debt.toUserId.toLowerCase() == currentUserId ? 'Bạn' : toName}',
                      subtitle: '${formatMoney(debt.amount)} ${debt.currency}',
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
                      subtitle: '${formatMoney(debt.amount)} ${debt.currency}',
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPoolTab(
    AsyncValue<TripPoolModel?> poolState,
    AsyncValue<TripDetailModel> detailsState,
  ) {
    return _GlassTabScroll(
      onRefresh: () async =>
          ref.invalidate(tripPoolControllerProvider(widget.tripId)),
      child: poolState.when(
        loading: () => const IosLoading(),
        error: (err, stack) => IosEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Không tải được quỹ nhóm',
          message: err.toString(),
        ),
        data: (pool) {
          final contributions = pool?.contributions ?? [];
          final balance = pool?.balance ?? 0;
          final currency = pool?.currency ?? widget.baseCurrency;

          return Column(
            children: [
              IosSection(
                header: 'Quỹ nhóm',
                children: [
                  IosListTile(
                    icon: CupertinoIcons.creditcard,
                    iconColor: AppTheme.iosBlue,
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
                  padding: EdgeInsets.only(top: 60),
                  child: IosEmptyState(
                    icon: CupertinoIcons.creditcard,
                    title: 'Chưa có đóng góp',
                    message: 'Các khoản nạp vào quỹ nhóm sẽ hiển thị tại đây.',
                  ),
                )
              else
                IosSection(
                  header: 'Lịch sử đóng góp',
                  children: contributions.map((contribution) {
                    return IosListTile(
                      icon: CupertinoIcons.person,
                      title: _getMemberName(contribution.userId, detailsState),
                      subtitle: _formatDate(contribution.contributedAt),
                      value: '${formatMoney(contribution.amount)} $currency',
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersTab(AsyncValue<TripDetailModel> detailsState) {
    return _GlassTabScroll(
      onRefresh: () async => ref.invalidate(tripDetailsProvider(widget.tripId)),
      child: detailsState.when(
        loading: () => const IosLoading(),
        error: (err, stack) => IosEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Không tải được thành viên',
          message: err.toString(),
        ),
        data: (details) => Column(
          children: [
            IosSection(
              header: 'Chia sẻ',
              footer: 'Mã này dùng để mời thêm thành viên vào chuyến đi.',
              children: [
                IosListTile(
                  icon: CupertinoIcons.qrcode,
                  title: details.inviteCode,
                  subtitle:
                      details.shareUrl ??
                      'https://miane.app/trip/${details.inviteCode}',
                  onTap: () => _showShareSheet(context, details),
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
                      member.roleName ??
                      (member.role == 0 ? 'Chủ chuyến đi' : 'Thành viên'),
                  value: member.userTier == 1 ? 'PRO' : null,
                  onTap: () => _showMemberActions(member),
                );
              }).toList(),
            ),
            IosSection(
              header: 'Quản lý',
              children: [
                IosListTile(
                  icon: CupertinoIcons.person_badge_plus,
                  title: 'Mời thành viên',
                  onTap: () => _showShareSheet(context, details),
                ),
                IosListTile(
                  icon: CupertinoIcons.gear_solid,
                  title: 'Cài đặt chuyến đi',
                  onTap: () => _showTripSettings(context, detailsState),
                ),
                IosListTile(
                  icon: CupertinoIcons.square_arrow_right,
                  iconColor: AppTheme.iosRed,
                  title: 'Rời chuyến đi',
                  destructive: true,
                  onTap: () => _handleLeaveTrip(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _buildTripDays(TripDetailModel? details) {
    final now = DateTime.now();
    final rawStart = details?.startDate ?? now;
    final rawEnd = details?.endDate ?? rawStart.add(const Duration(days: 2));
    final start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    final end = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
    final count = end.difference(start).inDays + 1;
    final safeCount = count < 1 ? 1 : (count > 30 ? 30 : count);
    return List.generate(
      safeCount,
      (index) => start.add(Duration(days: index)),
    );
  }

  String _formatTripDateRange(TripDetailModel? details) {
    if (details?.startDate == null || details?.endDate == null) {
      return 'Chưa đặt ngày';
    }
    return '${_formatShortDate(details!.startDate!)} → ${_formatShortDate(details.endDate!)} • ${details.durationDays ?? 1} ngày';
  }

  String _formatShortDate(DateTime date) => '${date.day} thg ${date.month}';

  void _showShareSheet(BuildContext context, TripDetailModel? details) {
    final inviteCode = details?.inviteCode ?? '';
    showTripShareSheet(
      context,
      TripCreationResult(
        tripId: details?.id ?? widget.tripId,
        inviteCode: inviteCode,
        shareUrl:
            details?.shareUrl ??
            (inviteCode.isEmpty
                ? 'https://miane.app/trip/${widget.tripId}'
                : 'https://miane.app/trip/$inviteCode'),
      ),
    );
  }

  void _showAddActivitySheet(
    int dayIndex,
    DateTime day,
    String destination, {
    String? initialCategory,
  }) {
    var selectedCategory = initialCategory ?? _activityCategories.first.label;
    var selectedTime = DateTime(day.year, day.month, day.day, 9);
    final searchController = TextEditingController();

    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.92,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyword = searchController.text.trim().toLowerCase();
            final templates = _activityTemplates.where((template) {
              final matchCategory =
                  template.group == selectedCategory ||
                  selectedCategory == 'Tất cả';
              final matchSearch =
                  keyword.isEmpty ||
                  template.title.toLowerCase().contains(keyword) ||
                  template.subtitle.toLowerCase().contains(keyword);
              return matchCategory && matchSearch;
            }).toList();

            return GlassBottomSheetScaffold(
              title: 'Hoạt động mới',
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  IosTextField(
                    controller: searchController,
                    placeholder: 'Tìm hoạt động và địa điểm',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _ActivityTimeSelector(
                    timeLabel: _formatActivityTime(selectedTime),
                    onTap: () => _showActivityTimePicker(
                      context,
                      day,
                      selectedTime,
                      (value) => setSheetState(() => selectedTime = value),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 94,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final category = _activityCategories[index];
                        return _ActivityCategoryButton(
                          category: category,
                          selected: selectedCategory == category.label,
                          onTap: () => setSheetState(
                            () => selectedCategory = category.label,
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: _activityCategories.length,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    selectedCategory == 'Tất cả'
                        ? 'Gợi ý cho ${_formatShortDate(day)}'
                        : selectedCategory,
                    style: AppTheme.headlineMd(),
                  ),
                  const SizedBox(height: 10),
                  for (final template in templates)
                    _ActivityTemplateTile(
                      template: template,
                      destination: destination,
                      onTap: () {
                        if (template.usesPlacePicker) {
                          Navigator.of(sheetContext).pop();
                          _showPlaceActivitySheet(
                            dayIndex: dayIndex,
                            day: day,
                            destination: destination,
                            template: template,
                            selectedTime: selectedTime,
                          );
                          return;
                        }

                        _addActivity(
                          dayIndex,
                          template.toDraft(
                            time: selectedTime,
                            destination: destination,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  if (templates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: IosEmptyState(
                        icon: CupertinoIcons.search,
                        title: 'Không có gợi ý phù hợp',
                        message: 'Thử đổi từ khóa hoặc chọn nhóm khác.',
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addActivity(int dayIndex, _TripActivityDraft activity) {
    setState(() {
      final items = [
        ...(_dayActivities[dayIndex] ?? const <_TripActivityDraft>[]),
        activity,
      ]..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
      _dayActivities[dayIndex] = items;
      _selectedDayIndex = dayIndex;
    });
  }

  List<_TripActivityDraft> _sortedActivities(
    List<_TripActivityDraft> activities,
  ) {
    return [...activities]
      ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
  }

  String _formatActivityTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showActivityTimePicker(
    BuildContext context,
    DateTime day,
    DateTime initialTime,
    ValueChanged<DateTime> onSelected,
  ) {
    var draft = initialTime;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) => Container(
        height: 318,
        color: AppTheme.surfaceDark,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(modalContext).pop(),
                      child: const Text('Hủy'),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        onSelected(draft);
                        Navigator.of(modalContext).pop();
                      },
                      child: const Text('Xong'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: initialTime,
                  onDateTimeChanged: (value) {
                    draft = DateTime(
                      day.year,
                      day.month,
                      day.day,
                      value.hour,
                      value.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetailSheet(int dayIndex, DateTime day, String destination) {
    final activities = _sortedActivities(
      _dayActivities[dayIndex] ?? const <_TripActivityDraft>[],
    );

    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.88,
      builder: (_) => GlassBottomSheetScaffold(
        title: 'Ngày ${dayIndex + 1}',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 40),
          onPressed: () => _showAddActivitySheet(dayIndex, day, destination),
          child: const Icon(CupertinoIcons.add_circled_solid),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Text(
              '${_formatShortDate(day)} • $destination',
              style: AppTheme.bodySm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              _EmptyItineraryCard(
                onAdd: () => _showAddActivitySheet(dayIndex, day, destination),
              )
            else
              for (final activity in activities)
                _DetailedActivityCard(activity: activity),
          ],
        ),
      ),
    );
  }

  void _showPlaceActivitySheet({
    required int dayIndex,
    required DateTime day,
    required String destination,
    required _TripActivityTemplate template,
    required DateTime selectedTime,
  }) {
    final searchController = TextEditingController(text: destination);
    var currentTime = selectedTime;
    var suggestions = _mockPlaceSuggestions(template, destination);

    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.86,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return GlassBottomSheetScaffold(
              title: template.title,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  _GooglePlacesNotice(
                    configured: _googlePlacesApiKey.isNotEmpty,
                  ),
                  const SizedBox(height: 14),
                  _ActivityTimeSelector(
                    timeLabel: _formatActivityTime(currentTime),
                    onTap: () => _showActivityTimePicker(
                      context,
                      day,
                      currentTime,
                      (value) => setSheetState(() => currentTime = value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: searchController,
                    placeholder: 'Tìm trên Google Maps',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (value) {
                      setSheetState(() {
                        suggestions = _mockPlaceSuggestions(
                          template,
                          destination,
                          value,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Gợi ý địa điểm', style: AppTheme.headlineMd()),
                  const SizedBox(height: 10),
                  for (final suggestion in suggestions)
                    _PlaceSuggestionTile(
                      suggestion: suggestion,
                      color: template.color,
                      icon: template.icon,
                      onTap: () {
                        _addActivity(
                          dayIndex,
                          template.toDraft(
                            time: currentTime,
                            destination: destination,
                            placeName: suggestion.name,
                            placeAddress: suggestion.address,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  _ManualPlaceButton(
                    label: searchController.text.trim().isEmpty
                        ? 'Thêm địa điểm thủ công'
                        : 'Dùng "${searchController.text.trim()}"',
                    onTap: () {
                      final manualName = searchController.text.trim().isEmpty
                          ? template.title
                          : searchController.text.trim();
                      _addActivity(
                        dayIndex,
                        template.toDraft(
                          time: currentTime,
                          destination: destination,
                          placeName: manualName,
                          placeAddress: destination,
                        ),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_PlaceSuggestion> _mockPlaceSuggestions(
    _TripActivityTemplate template,
    String destination, [
    String keyword = '',
  ]) {
    final base = switch (template.title) {
      'Nhà hàng' => [
        _PlaceSuggestion('Nhà hàng địa phương', destination, '4.6'),
        _PlaceSuggestion('Quán ăn gần trung tâm', destination, '4.4'),
        _PlaceSuggestion('Bữa tối view đẹp', destination, '4.7'),
      ],
      'Cà phê' => [
        _PlaceSuggestion('Cà phê gần khách sạn', destination, '4.5'),
        _PlaceSuggestion('Quán cà phê yên tĩnh', destination, '4.6'),
        _PlaceSuggestion('Cà phê ngắm hoàng hôn', destination, '4.7'),
      ],
      _ => [
        _PlaceSuggestion('Điểm tham quan nổi bật', destination, '4.7'),
        _PlaceSuggestion('Khu phố đáng đi', destination, '4.5'),
        _PlaceSuggestion('Điểm chụp ảnh đẹp', destination, '4.6'),
      ],
    };

    final cleanKeyword = keyword.trim().toLowerCase();
    if (cleanKeyword.isEmpty) return base;
    return base
        .where(
          (place) =>
              place.name.toLowerCase().contains(cleanKeyword) ||
              place.address.toLowerCase().contains(cleanKeyword),
        )
        .toList();
  }

  /// Manages the legs (segments) of a multi-stop trip: shows the ordered list
  /// and lets the owner/admin add or remove a leg. Each leg is a destination
  /// with its own date range (e.g. Hà Nội → Đà Nẵng → Sài Gòn).
  void _showLegsManager(BuildContext context) {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.72,
      builder: (sheetContext) => GlassBottomSheetScaffold(
        title: 'Các chặng của chuyến đi',
        child: Consumer(
          builder: (consumerContext, ref, _) {
            final legsState = ref.watch(tripLegsProvider(widget.tripId));
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                legsState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (err, _) => _InlineWarning(
                    message:
                        'Không tải được các chặng: ${err.toString().replaceAll('ApiException: ', '')}',
                  ),
                  data: (legs) {
                    if (legs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Chưa có chặng nào. Thêm chặng để chia chuyến đi thành nhiều điểm đến.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySm(
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(consumerContext),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < legs.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LegCard(
                              index: i,
                              leg: legs[i],
                              dateLabel: _formatLegDates(legs[i]),
                              onDelete: () async {
                                try {
                                  await ref
                                      .read(tripLegsActionsProvider)
                                      .delete(widget.tripId, legs[i].id);
                                } catch (e) {
                                  if (consumerContext.mounted) {
                                    await showIosMessage(
                                      consumerContext,
                                      message:
                                          'Không thể xóa chặng: ${e.toString().replaceAll('ApiException: ', '')}',
                                      isError: true,
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: IosPrimaryButton(
                    label: '+ Thêm chặng',
                    onPressed: () => _showAddLegSheet(consumerContext, ref),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatLegDates(TripLegModel leg) {
    if (leg.startDate == null && leg.endDate == null) return '';
    final start = leg.startDate != null ? _formatShortDate(leg.startDate!) : '?';
    final end = leg.endDate != null ? _formatShortDate(leg.endDate!) : '?';
    return '$start → $end';
  }

  Future<void> _showAddLegSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    DateTime? start;
    DateTime? end;

    await showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.62,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => GlassBottomSheetScaffold(
          title: 'Thêm chặng',
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              IosTextField(
                controller: nameController,
                label: 'Tên chặng',
                placeholder: 'VD: Đà Nẵng',
                prefixIcon: CupertinoIcons.map_pin,
              ),
              const SizedBox(height: 12),
              IosTextField(
                controller: cityController,
                label: 'Điểm đến',
                placeholder: 'Thành phố',
                prefixIcon: CupertinoIcons.location,
              ),
              const SizedBox(height: 12),
              _DateRow(
                label: 'Bắt đầu',
                value: start != null ? _formatShortDate(start!) : 'Chọn ngày',
                onTap: () async {
                  final picked = await _pickDate(sheetContext,
                      initial: start ?? DateTime.now(), title: 'Ngày bắt đầu');
                  if (picked != null) setSheetState(() => start = picked);
                },
              ),
              const SizedBox(height: 10),
              _DateRow(
                label: 'Kết thúc',
                value: end != null ? _formatShortDate(end!) : 'Chọn ngày',
                onTap: () async {
                  final picked = await _pickDate(sheetContext,
                      initial: end ?? start ?? DateTime.now(),
                      title: 'Ngày kết thúc');
                  if (picked != null) setSheetState(() => end = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: IosPrimaryButton(
                  label: 'Lưu chặng',
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      await showIosMessage(sheetContext,
                          message: 'Vui lòng nhập tên chặng.', isError: true);
                      return;
                    }
                    try {
                      await ref.read(tripLegsActionsProvider).add(
                            widget.tripId,
                            name: name,
                            destinationCity: cityController.text.trim().isEmpty
                                ? null
                                : cityController.text.trim(),
                            startDate: start,
                            endDate: end,
                          );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        await showIosMessage(
                          sheetContext,
                          message:
                              'Không thể thêm chặng: ${e.toString().replaceAll('ApiException: ', '')}',
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required String title,
  }) async {
    DateTime picked = initial;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (popupContext) => Container(
        height: 320,
        color: AppTheme.surfaceDark,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTheme.titleSm()),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(popupContext).pop(picked),
                    child: const Text('Xong'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (value) => picked = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lets the owner shift the trip's start/end dates — e.g. when an added
  /// event/activity falls outside the current range, the day plan can be
  /// extended to fit it. Persists via UpdateTrip (PUT /trips/{id}).
  Future<void> _showEditTripDates(
    BuildContext context,
    TripDetailModel? details,
  ) async {
    final now = DateTime.now();
    var start = details?.startDate ?? now;
    var end = details?.endDate ?? start.add(const Duration(days: 2));

    await showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.5,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => GlassBottomSheetScaffold(
          title: 'Thay đổi thời gian',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DateRow(
                  label: 'Bắt đầu',
                  value: _formatShortDate(start),
                  onTap: () async {
                    final picked = await _pickDate(sheetContext,
                        initial: start, title: 'Ngày bắt đầu');
                    if (picked != null) {
                      setSheetState(() {
                        start = picked;
                        if (end.isBefore(start)) end = start;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateRow(
                  label: 'Kết thúc',
                  value: _formatShortDate(end),
                  onTap: () async {
                    final picked = await _pickDate(sheetContext,
                        initial: end, title: 'Ngày kết thúc');
                    if (picked != null) {
                      setSheetState(() {
                        end = picked.isBefore(start) ? start : picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: IosPrimaryButton(
                    label: 'Lưu thời gian',
                    onPressed: () async {
                      try {
                        await ref.read(updateTripDatesProvider)(
                          widget.tripId,
                          startDate: start,
                          endDate: end,
                        );
                        _refreshTripData();
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        if (context.mounted) {
                          await showIosMessage(context,
                              message: 'Đã cập nhật thời gian chuyến đi.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          await showIosMessage(
                            context,
                            message:
                                'Không thể cập nhật: ${e.toString().replaceAll('ApiException: ', '')}',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTripSettings(
    BuildContext context,
    AsyncValue<TripDetailModel> detailsState,
  ) {
    final details = detailsState.valueOrNull;
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.78,
      builder: (sheetContext) => GlassBottomSheetScaffold(
        title: 'Quản lý chuyến đi',
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            _TripSettingsHeader(
              title: details?.name ?? widget.tripName,
              subtitle: details?.destinationLabel ?? widget.destination,
              inviteCode: details?.inviteCode ?? '',
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: CupertinoIcons.square_arrow_up,
                  title: 'Chia sẻ chuyến đi',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showShareSheet(context, details);
                  },
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.person_2_fill,
                  title: 'Quản lý thành viên',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showMembersManager(context, detailsState);
                  },
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.map_pin_ellipse,
                  title: 'Quản lý chặng',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showLegsManager(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: CupertinoIcons.textformat,
                  title: 'Chỉnh sửa tên',
                  onTap: () =>
                      _showSettingPlaceholder(sheetContext, 'Chỉnh sửa tên'),
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.calendar,
                  title: 'Thay đổi ngày',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showEditTripDates(context, details);
                  },
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.photo,
                  title: 'Thay đổi nền',
                  onTap: () =>
                      _showSettingPlaceholder(sheetContext, 'Thay đổi nền'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: CupertinoIcons.doc_on_doc,
                  title: 'Sao chép chuyến đi',
                  onTap: () => _showSettingPlaceholder(
                    sheetContext,
                    'Sao chép chuyến đi',
                  ),
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.bell_slash,
                  title: 'Tắt thông báo',
                  onTap: () =>
                      _showSettingPlaceholder(sheetContext, 'Tắt thông báo'),
                ),
                _SettingsActionTile(
                  icon: CupertinoIcons.trash,
                  title: 'Xóa chuyến đi',
                  destructive: true,
                  onTap: () =>
                      _showSettingPlaceholder(sheetContext, 'Xóa chuyến đi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersManager(
    BuildContext context,
    AsyncValue<TripDetailModel> detailsState,
  ) {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.82,
      builder: (_) => GlassBottomSheetScaffold(
        title: 'Thành viên',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 40),
          onPressed: () => _showShareSheet(context, detailsState.valueOrNull),
          child: const Icon(CupertinoIcons.person_badge_plus),
        ),
        child: detailsState.when(
          loading: () => const IosLoading(),
          error: (err, stack) => IosEmptyState(
            icon: CupertinoIcons.exclamationmark_circle,
            title: 'Không tải được thành viên',
            message: err.toString(),
          ),
          data: (details) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              _InviteCodeCard(
                inviteCode: details.inviteCode,
                shareUrl:
                    details.shareUrl ??
                    'https://miane.app/trip/${details.inviteCode}',
                onShare: () => _showShareSheet(context, details),
              ),
              const SizedBox(height: 14),
              for (final member in details.members)
                _MemberManageCard(
                  member: member,
                  onTap: () => _showMemberActions(member),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMemberActions(TripMemberModel member) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(member.nickName ?? 'Thành viên'),
        message: Text(member.roleName ?? 'Thành viên'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Xem hồ sơ'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đổi vai trò'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Xóa khỏi chuyến đi'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ),
    );
  }

  void _showSettingPlaceholder(BuildContext sheetContext, String feature) {
    Navigator.of(sheetContext).pop();
    showIosMessage(
      context,
      title: feature,
      message:
          'Luồng $feature đã có vị trí trong phần quản lý chuyến đi và sẽ nối API chỉnh sửa ở bước tiếp theo.',
    );
  }

  String _documentsSubtitle(AsyncValue<List<TripFileModel>> filesState) {
    if (filesState.isLoading) return 'Đang tải vé, booking và ghi chú';
    if (filesState.hasError) return 'Chưa tải được tài liệu';

    final count = filesState.valueOrNull?.length ?? 0;
    if (count == 0) return 'Vé, booking, ghi chú và file đặt chỗ';
    return '$count tài liệu đã lưu cho chuyến đi';
  }

  void _showDocumentsSheet() {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.88,
      builder: (sheetContext) {
        return GlassBottomSheetScaffold(
          title: 'Tài liệu',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 40),
            onPressed: () => _showAddDocumentSheet(),
            child: const Icon(CupertinoIcons.add_circled),
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final filesState = ref.watch(tripFilesProvider(widget.tripId));
              return filesState.when(
                loading: () => const IosLoading(),
                error: (err, stack) => IosEmptyState(
                  icon: CupertinoIcons.exclamationmark_circle,
                  title: 'Không tải được tài liệu',
                  message: err.toString().replaceAll('ApiException: ', ''),
                ),
                data: (files) {
                  final grouped = _groupTripFiles(files);
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      _DocumentVaultHeader(files: files),
                      const SizedBox(height: 14),
                      if (files.isEmpty)
                        const IosEmptyState(
                          icon: CupertinoIcons.folder,
                          title: 'Chưa có tài liệu',
                          message:
                              'Lưu link vé máy bay, booking khách sạn, bảo hiểm hoặc ghi chú quan trọng ở đây.',
                        )
                      else
                        for (final entry in grouped.entries)
                          _DocumentFolderBlock(
                            folder: entry.key,
                            files: entry.value,
                            onOpenFile: _openDocument,
                            onCopyFile: _copyDocumentLink,
                            onDeleteFile: _deleteTripFile,
                          ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showAddDocumentSheet() {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.66,
      builder: (sheetContext) {
        return GlassBottomSheetScaffold(
          title: 'Thêm tài liệu',
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              _DocumentSourceTile(
                icon: CupertinoIcons.camera_fill,
                color: AppTheme.iosBlue,
                title: 'Chụp ảnh',
                subtitle: 'Chụp hộ chiếu, vé, hóa đơn, biển chỉ dẫn...',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDocumentImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _DocumentSourceTile(
                icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                color: AppTheme.iosGreen,
                title: 'Chọn ảnh từ thư viện',
                subtitle: 'Thêm ảnh đã có trong máy vào chuyến đi',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDocumentImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _DocumentSourceTile(
                icon: CupertinoIcons.doc_fill,
                color: AppTheme.iosOrange,
                title: 'Nhập tài liệu',
                subtitle: 'PDF, Word, Excel, CSV, text, PowerPoint',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImportedDocument();
                },
              ),
              const SizedBox(height: 10),
              _DocumentSourceTile(
                icon: CupertinoIcons.square_pencil,
                color: AppTheme.iosIndigo,
                title: 'Ghi chú',
                subtitle: 'Viết note nhanh rồi lưu cùng tài liệu chuyến đi',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showNoteDocumentSheet();
                },
              ),
              const SizedBox(height: 10),
              _DocumentSourceTile(
                icon: CupertinoIcons.text_badge_checkmark,
                color: AppTheme.iosIndigo,
                title: 'Chọn từ Ghi chú iPhone',
                subtitle: 'Chọn ghi chú đã lưu/xuất trong Files',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickIphoneNoteDocument();
                },
              ),
              const SizedBox(height: 10),
              _DocumentSourceTile(
                icon: CupertinoIcons.link,
                color: AppTheme.iosBlue,
                title: 'Thêm bằng liên kết',
                subtitle: 'Dán link booking, drive hoặc tài liệu online',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showLinkDocumentSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkDocumentSheet() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final tagsController = TextEditingController();
    var folder = _documentFolders.first;
    var isSaving = false;

    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.78,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return GlassBottomSheetScaffold(
              title: 'Thêm tài liệu',
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 40),
                onPressed: isSaving
                    ? null
                    : () => _submitTripFile(
                        sheetContext: sheetContext,
                        nameController: nameController,
                        urlController: urlController,
                        tagsController: tagsController,
                        folder: folder,
                        setSaving: (value) =>
                            setSheetState(() => isSaving = value),
                      ),
                child: isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text('Lưu'),
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  _DocumentFolderChips(
                    selected: folder,
                    onSelected: (value) => setSheetState(() => folder = value),
                  ),
                  const SizedBox(height: 18),
                  IosTextField(
                    controller: nameController,
                    label: 'Tên tài liệu',
                    placeholder: 'Vé máy bay, booking khách sạn...',
                    prefixIcon: CupertinoIcons.doc_text,
                  ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: urlController,
                    label: 'Liên kết',
                    placeholder: 'https://...',
                    prefixIcon: CupertinoIcons.link,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: tagsController,
                    label: 'Nhãn',
                    placeholder: 'visa, vé, khách sạn',
                    prefixIcon: CupertinoIcons.tag,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNoteDocumentSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    var folder = 'Ghi chú';
    var isSaving = false;

    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.82,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return GlassBottomSheetScaffold(
              title: 'Ghi chú mới',
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 40),
                onPressed: isSaving
                    ? null
                    : () => _submitTripNote(
                        sheetContext: sheetContext,
                        titleController: titleController,
                        contentController: contentController,
                        tagsController: tagsController,
                        folder: folder,
                        setSaving: (value) =>
                            setSheetState(() => isSaving = value),
                      ),
                child: isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text('Lưu'),
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  _DocumentFolderChips(
                    selected: folder,
                    onSelected: (value) => setSheetState(() => folder = value),
                  ),
                  const SizedBox(height: 18),
                  IosTextField(
                    controller: titleController,
                    label: 'Tiêu đề',
                    placeholder: 'Lịch nhận phòng, số hotline...',
                    prefixIcon: CupertinoIcons.textformat,
                  ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: contentController,
                    label: 'Nội dung',
                    placeholder: 'Nhập ghi chú cho chuyến đi',
                    prefixIcon: CupertinoIcons.square_pencil,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 14),
                  IosTextField(
                    controller: tagsController,
                    label: 'Nhãn',
                    placeholder: 'khách sạn, visa, cần nhớ',
                    prefixIcon: CupertinoIcons.tag,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDocumentImage(ImageSource source) async {
    try {
      final image = await _documentImagePicker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 88,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();

      await _uploadLocalTripFile(
        TripLocalFileDraft(
          filePath: image.path,
          fileBytes: bytes,
          fileName: image.name.isEmpty ? _fallbackImageFileName() : image.name,
          folder: 'Ảnh',
          tags: const ['ảnh'],
        ),
      );
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message: 'Không thể thêm ảnh: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickImportedDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        withData: true,
        allowedExtensions: const [
          'pdf',
          'txt',
          'md',
          'rtf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'csv',
          'ppt',
          'pptx',
        ],
      );
      if (result == null || result.files.isEmpty) return;

      var uploadedCount = 0;
      for (final file in result.files) {
        final path = file.path;
        final bytes = file.bytes;
        if ((path == null || path.isEmpty) && bytes == null) continue;

        await _uploadLocalTripFile(
          TripLocalFileDraft(
            filePath: path,
            fileBytes: bytes,
            fileName: file.name,
            folder: 'Giấy tờ',
            tags: const ['tài liệu'],
          ),
          showSuccess: false,
        );
        uploadedCount++;
      }

      if (mounted && uploadedCount > 0) {
        await showIosMessage(
          context,
          title: 'Đã thêm tài liệu',
          message: '$uploadedCount tài liệu đã được lưu vào chuyến đi.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message: 'Không thể nhập tài liệu: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickIphoneNoteDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        withData: true,
        allowedExtensions: const [
          'txt',
          'md',
          'rtf',
          'pdf',
        ],
      );
      if (result == null || result.files.isEmpty) return;

      var uploadedCount = 0;
      for (final file in result.files) {
        final path = file.path;
        final bytes = file.bytes;
        if ((path == null || path.isEmpty) && bytes == null) continue;

        await _uploadLocalTripFile(
          TripLocalFileDraft(
            filePath: path,
            fileBytes: bytes,
            fileName: file.name,
            folder: 'Ghi chú',
            tags: const ['ghi chú'],
          ),
          showSuccess: false,
        );
        uploadedCount++;
      }

      if (mounted && uploadedCount > 0) {
        await showIosMessage(
          context,
          title: 'Đã thêm ghi chú',
          message: '$uploadedCount ghi chú đã được lưu vào chuyến đi.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message: 'Không thể nhập ghi chú: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _uploadLocalTripFile(
    TripLocalFileDraft draft, {
    bool showSuccess = true,
  }) async {
    try {
      await ref
          .read(tripRepositoryProvider)
          .uploadTripFile(
            widget.tripId,
            draft,
          );
      ref.invalidate(tripFilesProvider(widget.tripId));

      if (mounted && showSuccess) {
        await showIosMessage(
          context,
          title: 'Đã thêm tài liệu',
          message: '"${draft.fileName}" đã được lưu vào chuyến đi.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể tải tài liệu lên: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    }
  }

  Future<void> _submitTripNote({
    required BuildContext sheetContext,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required TextEditingController tagsController,
    required String folder,
    required ValueChanged<bool> setSaving,
  }) async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập tiêu đề và nội dung ghi chú.',
        isError: true,
      );
      return;
    }

    setSaving(true);
    try {
      final tags = tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);

      await ref
          .read(tripRepositoryProvider)
          .addTripNote(
            widget.tripId,
            TripNoteDraft(
              title: title,
              content: content,
              folder: folder,
              tags: tags,
            ),
          );
      ref.invalidate(tripFilesProvider(widget.tripId));

      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể lưu ghi chú: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (sheetContext.mounted) setSaving(false);
    }
  }

  Future<void> _submitTripFile({
    required BuildContext sheetContext,
    required TextEditingController nameController,
    required TextEditingController urlController,
    required TextEditingController tagsController,
    required String folder,
    required ValueChanged<bool> setSaving,
  }) async {
    final fileName = nameController.text.trim();
    final fileUrl = urlController.text.trim();
    final parsedUrl = Uri.tryParse(fileUrl);

    if (fileName.isEmpty || parsedUrl == null || !parsedUrl.hasScheme) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập tên tài liệu và một liên kết hợp lệ.',
        isError: true,
      );
      return;
    }

    setSaving(true);
    try {
      final tags = tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);

      await ref
          .read(tripRepositoryProvider)
          .addTripFile(
            widget.tripId,
            TripFileDraft(
              fileName: fileName,
              fileUrl: fileUrl,
              folder: folder,
              contentType: _inferContentType(fileName, fileUrl),
              tags: tags,
            ),
          );
      ref.invalidate(tripFilesProvider(widget.tripId));

      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể lưu tài liệu: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (sheetContext.mounted) setSaving(false);
    }
  }

  Future<void> _openDocument(TripFileModel file) async {
    final documentUrl = _absoluteDocumentUrl(file.fileUrl);
    final endpoint = _documentApiEndpoint(file.fileUrl);

    if (endpoint == null) {
      final opened = await openDocumentUrl(documentUrl);
      if (!opened && mounted) await _showDocumentActions(file);
      return;
    }

    try {
      final bytes = await ref.read(apiClientProvider).getBytes(endpoint);
      final contentType = _documentContentType(file);

      if (_isImageDocument(file)) {
        if (mounted) _showImageDocumentPreview(file, bytes);
        return;
      }

      if (_isTextDocument(file)) {
        final text = utf8.decode(bytes, allowMalformed: true);
        if (mounted) _showTextDocumentPreview(file, text);
        return;
      }

      final opened = await openDocumentBytes(
        bytes: bytes,
        fileName: file.fileName,
        contentType: contentType,
      );

      if (!opened && mounted) {
        await Clipboard.setData(ClipboardData(text: documentUrl));
        if (!mounted) return;
        await showIosMessage(
          context,
          title: 'Chưa mở được tài liệu',
          message:
              'Thiết bị này chưa hỗ trợ xem trực tiếp loại tài liệu này. Liên kết đã được sao chép để bạn mở thủ công.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showIosMessage(
        context,
        message:
            'Không thể mở tài liệu: ${e.toString().replaceAll('ApiException: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _copyDocumentLink(TripFileModel file) async {
    await Clipboard.setData(
      ClipboardData(text: _absoluteDocumentUrl(file.fileUrl)),
    );
    if (!mounted) return;
    await showIosMessage(
      context,
      title: 'Đã sao chép',
      message: 'Liên kết tài liệu đã được sao chép.',
    );
  }

  void _showImageDocumentPreview(TripFileModel file, Uint8List bytes) {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.9,
      builder: (_) => GlassBottomSheetScaffold(
        title: file.fileName,
        child: InteractiveViewer(
          minScale: 0.7,
          maxScale: 4,
          child: Center(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _showTextDocumentPreview(TripFileModel file, String text) {
    showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.88,
      builder: (_) => GlassBottomSheetScaffold(
        title: file.fileName,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Text(
            text,
            style: AppTheme.bodyMd().copyWith(height: 1.45),
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentActions(TripFileModel file) {
    final documentUrl = _absoluteDocumentUrl(file.fileUrl);
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(file.fileName),
        message: Text(documentUrl),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await Clipboard.setData(ClipboardData(text: documentUrl));
              if (mounted) {
                await showIosMessage(
                  this.context,
                  title: 'Đã sao chép',
                  message: 'Liên kết tài liệu đã được sao chép.',
                );
              }
            },
            child: const Text('Sao chép liên kết'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTripFile(file);
            },
            child: const Text('Xóa khỏi chuyến đi'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ),
    );
  }

  Future<void> _deleteTripFile(TripFileModel file) async {
    final confirmed = await showIosConfirm(
      context,
      title: 'Xóa tài liệu?',
      message: 'Tài liệu "${file.fileName}" sẽ được gỡ khỏi chuyến đi.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(tripRepositoryProvider)
          .deleteTripFile(
            widget.tripId,
            file.id,
          );
      ref.invalidate(tripFilesProvider(widget.tripId));
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể xóa tài liệu: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    }
  }

  void _showModuleComingSoon(String module) {
    showIosMessage(
      context,
      title: module,
      message:
          '$module đã được đặt trong cấu trúc Trip workspace để mở rộng thành module riêng.',
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
            inputFormatters: const [MoneyInputFormatter()],
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
              final amount = parseMoneyInput(amountController.text.trim());
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

  /// Expense creation is scan-only (no manual entry): the user picks whether
  /// they're scanning an itemized bill or a bank-transfer slip, and both go
  /// through the on-device OCR + review flow (ScanBillScreen ->
  /// ScanResultReviewScreen). The review screen still allows editing every
  /// field before saving, keeping a human in the loop.
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
        void openScanner(ScanMode mode) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => ScanBillScreen(
                tripId: widget.tripId,
                baseCurrency: widget.baseCurrency,
                members: details.members,
                destination: details.destinationCity,
                mode: mode,
              ),
            ),
          );
        }

        showCupertinoModalPopup<void>(
          context: context,
          builder: (actionContext) => CupertinoActionSheet(
            title: const Text('Thêm chi phí'),
            message: const Text(
                'Quét hình ảnh để tự động điền — không cần nhập tay.'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(actionContext).pop();
                  openScanner(ScanMode.bill);
                },
                child: const Text('📷 Quét hóa đơn'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(actionContext).pop();
                  openScanner(ScanMode.transfer);
                },
                child: const Text('🏦 Quét biên lai chuyển khoản'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(actionContext).pop(),
              child: const Text('Hủy'),
            ),
          ),
        );
      },
    );
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
    String userId,
    AsyncValue<TripDetailModel> detailsState,
  ) {
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

const _documentFolders = <String>[
  'General',
  'Ảnh',
  'Vé',
  'Booking',
  'Giấy tờ',
  'Ghi chú',
];

Map<String, List<TripFileModel>> _groupTripFiles(List<TripFileModel> files) {
  final grouped = <String, List<TripFileModel>>{};
  for (final file in files) {
    grouped.putIfAbsent(file.displayFolder, () => []).add(file);
  }
  return grouped;
}

String? _inferContentType(String fileName, String fileUrl) {
  final source = '$fileName $fileUrl'.toLowerCase();
  if (source.contains('.pdf')) return 'application/pdf';
  if (source.contains('.png')) return 'image/png';
  if (source.contains('.webp')) return 'image/webp';
  if (source.contains('.heic')) return 'image/heic';
  if (source.contains('.jpg') || source.contains('.jpeg')) return 'image/jpeg';
  if (source.contains('.txt')) return 'text/plain';
  if (source.contains('.md')) return 'text/markdown';
  if (source.contains('.csv')) return 'text/csv';
  if (source.contains('.doc') || source.contains('.docx')) {
    return 'application/msword';
  }
  if (source.contains('.xls') || source.contains('.xlsx')) {
    return 'application/vnd.ms-excel';
  }
  if (source.contains('.ppt') || source.contains('.pptx')) {
    return 'application/vnd.ms-powerpoint';
  }
  return null;
}

IconData _documentIcon(TripFileModel file) {
  final contentType = (file.contentType ?? '').toLowerCase();
  final extension = file.extension.toLowerCase();
  if (contentType.contains('image') ||
      ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
    return CupertinoIcons.photo;
  }
  if (contentType.contains('pdf') || extension == 'pdf') {
    return CupertinoIcons.doc_richtext;
  }
  if (extension == 'doc' || extension == 'docx') {
    return CupertinoIcons.doc_text;
  }
  if (extension == 'xls' || extension == 'xlsx') {
    return CupertinoIcons.table;
  }
  if (extension == 'ppt' || extension == 'pptx') {
    return CupertinoIcons.rectangle_stack;
  }
  if (extension == 'txt' || extension == 'md' || extension == 'rtf') {
    return CupertinoIcons.text_alignleft;
  }
  return CupertinoIcons.link;
}

Color _documentColor(TripFileModel file) {
  final folder = file.displayFolder.toLowerCase();
  if (folder.contains('ảnh')) return AppTheme.iosGreen;
  if (folder.contains('vé')) return AppTheme.iosBlue;
  if (folder.contains('booking')) return AppTheme.iosGreen;
  if (folder.contains('giấy')) return AppTheme.iosOrange;
  if (folder.contains('ghi')) return AppTheme.iosIndigo;
  return AppTheme.iosBlue;
}

String _fallbackImageFileName() {
  final now = DateTime.now();
  return 'trip-photo-${now.millisecondsSinceEpoch}.jpg';
}

String _absoluteDocumentUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;

  final separator = value.startsWith('/') ? '' : '/';
  return '${ApiEndpoints.baseUrl}$separator$value';
}

String? _documentApiEndpoint(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (!uri.hasScheme) return value;

  final base = Uri.tryParse(ApiEndpoints.baseUrl);
  if (base == null) return null;
  if (uri.scheme != base.scheme ||
      uri.host != base.host ||
      uri.port != base.port) {
    return null;
  }

  return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
}

String _documentContentType(TripFileModel file) {
  final inferred = _inferContentType(file.fileName, file.fileUrl);
  return file.contentType ?? inferred ?? 'application/octet-stream';
}

bool _isImageDocument(TripFileModel file) {
  final contentType = _documentContentType(file).toLowerCase();
  final extension = file.extension.toLowerCase();
  return contentType.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension);
}

bool _isTextDocument(TripFileModel file) {
  final contentType = _documentContentType(file).toLowerCase();
  final extension = file.extension.toLowerCase();
  return contentType.startsWith('text/') ||
      ['txt', 'md', 'rtf'].contains(extension);
}

String _documentSubtitle(TripFileModel file) {
  final pieces = [
    file.displayFolder,
    _formatFileSize(file.fileSizeBytes),
    _formatDocumentDate(file.createdAt),
    if (file.tags.isNotEmpty) file.tags.take(2).join(', '),
  ].whereType<String>().where((value) => value.isNotEmpty).toList();
  return pieces.join(' • ');
}

String? _formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return null;
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
}

String _formatDocumentDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _DocumentSourceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocumentSourceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 24,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentVaultHeader extends StatelessWidget {
  final List<TripFileModel> files;

  const _DocumentVaultHeader({required this.files});

  @override
  Widget build(BuildContext context) {
    final folderCount = _groupTripFiles(files).length;
    final latest = files.isEmpty
        ? 'Chưa có'
        : _formatDocumentDate(
            files
                .map((file) => file.createdAt)
                .reduce(
                  (a, b) => a.isAfter(b) ? a : b,
                ),
          );

    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.iosIndigo.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.folder_fill,
              color: AppTheme.iosIndigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _DocumentHeaderMetric(
                    value: files.length.toString(),
                    label: 'Tài liệu',
                  ),
                ),
                Expanded(
                  child: _DocumentHeaderMetric(
                    value: folderCount.toString(),
                    label: 'Thư mục',
                  ),
                ),
                Expanded(
                  child: _DocumentHeaderMetric(
                    value: latest,
                    label: 'Mới nhất',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentHeaderMetric extends StatelessWidget {
  final String value;
  final String label;

  const _DocumentHeaderMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.titleSm(),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.labelXs(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _DocumentFolderChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _DocumentFolderChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _documentFolders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final folder = _documentFolders[index];
          final isSelected = selected == folder;
          return CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 40),
            onPressed: () => onSelected(folder),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.iosIndigo.withValues(alpha: 0.22)
                    : CupertinoColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.iosIndigo.withValues(alpha: 0.34)
                      : CupertinoColors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: Text(
                  folder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelSm(
                    color: isSelected
                        ? AppTheme.iosIndigo
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentFolderBlock extends StatelessWidget {
  final String folder;
  final List<TripFileModel> files;
  final ValueChanged<TripFileModel> onOpenFile;
  final ValueChanged<TripFileModel> onCopyFile;
  final ValueChanged<TripFileModel> onDeleteFile;

  const _DocumentFolderBlock({
    required this.folder,
    required this.files,
    required this.onOpenFile,
    required this.onCopyFile,
    required this.onDeleteFile,
  });

  @override
  Widget build(BuildContext context) {
    return IosSection(
      header: '$folder (${files.length})',
      children: files.map((file) {
        return Slidable(
          key: ValueKey(file.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.32,
            children: [
              SlidableAction(
                onPressed: (_) {
                  onCopyFile(file);
                },
                backgroundColor: AppTheme.iosBlue,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.link,
                borderRadius: BorderRadius.circular(18),
              ),
              SlidableAction(
                onPressed: (_) {
                  onDeleteFile(file);
                },
                backgroundColor: AppTheme.iosRed,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.trash,
                borderRadius: BorderRadius.circular(18),
              ),
            ],
          ),
          child: _DocumentFileTile(
            file: file,
            onTap: () => onOpenFile(file),
          ),
        );
      }).toList(),
    );
  }
}

class _DocumentFileTile extends StatelessWidget {
  final TripFileModel file;
  final VoidCallback onTap;

  const _DocumentFileTile({
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final extension = file.extension.isEmpty ? 'LINK' : file.extension;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.transparent,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _documentColor(file).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _documentIcon(file),
                color: _documentColor(file),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMd().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _documentSubtitle(file),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 46,
              child: Text(
                extension,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTheme.labelSm(color: secondary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, color: secondary, size: 18),
          ],
        ),
      ),
    );
  }
}

const _activityCategories = <_ActivityCategory>[
  _ActivityCategory(
    label: 'Tất cả',
    icon: CupertinoIcons.square_grid_2x2,
    color: AppTheme.iosBlue,
  ),
  _ActivityCategory(
    label: 'Di chuyển',
    icon: CupertinoIcons.airplane,
    color: Color(0xFF2EA7FF),
  ),
  _ActivityCategory(
    label: 'Lưu trú',
    icon: CupertinoIcons.house,
    color: Color(0xFFBF5AF2),
  ),
  _ActivityCategory(
    label: 'Ăn uống',
    icon: CupertinoIcons.cart,
    color: AppTheme.iosIndigo,
  ),
  _ActivityCategory(
    label: 'Địa điểm',
    icon: CupertinoIcons.map,
    color: AppTheme.iosPink,
  ),
  _ActivityCategory(
    label: 'Tài liệu',
    icon: CupertinoIcons.doc_text,
    color: AppTheme.iosIndigo,
  ),
];

const _activityTemplates = <_TripActivityTemplate>[
  _TripActivityTemplate(
    title: 'Chuyến bay',
    subtitle: 'Thêm giờ bay, sân bay, mã đặt chỗ',
    group: 'Di chuyển',
    defaultTime: '08:30',
    icon: CupertinoIcons.airplane,
    color: Color(0xFF2EA7FF),
  ),
  _TripActivityTemplate(
    title: 'Xe',
    subtitle: 'Taxi, thuê xe, đưa đón sân bay',
    group: 'Di chuyển',
    defaultTime: '10:00',
    icon: CupertinoIcons.car_detailed,
    color: AppTheme.iosBlue,
  ),
  _TripActivityTemplate(
    title: 'Tàu hoặc xe buýt',
    subtitle: 'Lịch trình công cộng, vé, ga khởi hành',
    group: 'Di chuyển',
    defaultTime: '09:15',
    icon: CupertinoIcons.bus,
    color: AppTheme.iosIndigo,
  ),
  _TripActivityTemplate(
    title: 'Nhận phòng',
    subtitle: 'Khách sạn, homestay, resort',
    group: 'Lưu trú',
    defaultTime: '14:00',
    icon: CupertinoIcons.house,
    color: Color(0xFFBF5AF2),
  ),
  _TripActivityTemplate(
    title: 'Nhà hàng',
    subtitle: 'Đặt bàn, món cần thử, ghi chú khẩu vị',
    group: 'Ăn uống',
    defaultTime: '19:00',
    icon: CupertinoIcons.cart,
    color: AppTheme.iosIndigo,
    usesPlacePicker: true,
  ),
  _TripActivityTemplate(
    title: 'Cà phê',
    subtitle: 'Quán nghỉ chân hoặc điểm gặp nhau',
    group: 'Ăn uống',
    defaultTime: '15:30',
    icon: CupertinoIcons.heart_fill,
    color: AppTheme.iosBlue,
    usesPlacePicker: true,
  ),
  _TripActivityTemplate(
    title: 'Điểm tham quan',
    subtitle: 'Bảo tàng, biển, chợ, khu phố',
    group: 'Địa điểm',
    defaultTime: '16:00',
    icon: CupertinoIcons.map,
    color: AppTheme.iosPink,
    usesPlacePicker: true,
  ),
  _TripActivityTemplate(
    title: 'Đi bộ khám phá',
    subtitle: 'Route nhẹ quanh khu lưu trú',
    group: 'Địa điểm',
    defaultTime: '17:30',
    icon: CupertinoIcons.person,
    color: AppTheme.iosGreen,
  ),
  _TripActivityTemplate(
    title: 'Tệp đặt chỗ',
    subtitle: 'Lưu vé, PDF, email xác nhận',
    group: 'Tài liệu',
    defaultTime: 'Cả ngày',
    icon: CupertinoIcons.doc_text,
    color: AppTheme.iosIndigo,
  ),
];

class _ActivityCategory {
  final String label;
  final IconData icon;
  final Color color;

  const _ActivityCategory({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TripActivityTemplate {
  final String title;
  final String subtitle;
  final String group;
  final String defaultTime;
  final IconData icon;
  final Color color;
  final bool usesPlacePicker;

  const _TripActivityTemplate({
    required this.title,
    required this.subtitle,
    required this.group,
    required this.defaultTime,
    required this.icon,
    required this.color,
    this.usesPlacePicker = false,
  });

  _TripActivityDraft toDraft({
    required DateTime time,
    required String destination,
    String? placeName,
    String? placeAddress,
  }) {
    return _TripActivityDraft(
      title: placeName ?? title,
      subtitle: placeAddress ?? subtitle,
      category: group,
      timeLabel:
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      minutesOfDay: time.hour * 60 + time.minute,
      location: placeName ?? destination,
      icon: icon,
      color: color,
    );
  }
}

class _TripActivityDraft {
  final String title;
  final String subtitle;
  final String category;
  final String timeLabel;
  final int minutesOfDay;
  final String location;
  final IconData icon;
  final Color color;

  const _TripActivityDraft({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timeLabel,
    required this.minutesOfDay,
    required this.location,
    required this.icon,
    required this.color,
  });
}

class _PlaceSuggestion {
  final String name;
  final String address;
  final String rating;

  const _PlaceSuggestion(this.name, this.address, this.rating);
}

class _TripMapBackdrop extends StatelessWidget {
  final String seed;
  final Uint8List? coverBytes;
  final String? coverImageUrl;

  const _TripMapBackdrop({
    required this.seed,
    this.coverBytes,
    this.coverImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverBytes != null)
          Image.memory(coverBytes!, fit: BoxFit.cover)
        else if ((coverImageUrl ?? '').isNotEmpty)
          Image.network(
            coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                CustomPaint(painter: _WorkspaceCoverPainter(seed)),
          )
        else
          CustomPaint(painter: _WorkspaceCoverPainter(seed)),
        CustomPaint(painter: _MapTexturePainter(seed)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CupertinoColors.black.withValues(alpha: 0.28),
                CupertinoColors.black.withValues(alpha: 0.48),
                CupertinoColors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapTexturePainter extends CustomPainter {
  final String seed;

  const _MapTexturePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = AppTheme.iosBlue.withValues(alpha: 0.20)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.12 + i * 0.1);
      final path = Path()
        ..moveTo(-30, y)
        ..cubicTo(
          size.width * 0.25,
          y - 32 + i * 5,
          size.width * 0.62,
          y + 40 - i * 3,
          size.width + 40,
          y - 10,
        );
      canvas.drawPath(path, i == 4 ? accentPaint : linePaint);
    }

    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.08 + i * 0.16);
      final path = Path()
        ..moveTo(x, -20)
        ..cubicTo(
          x + 46 - i * 3,
          size.height * 0.30,
          x - 34,
          size.height * 0.62,
          x + 28,
          size.height + 30,
        );
      canvas.drawPath(path, linePaint);
    }

    final pinPaint = Paint()..color = AppTheme.iosBlue;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.43),
      7,
      pinPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.43),
      13,
      Paint()
        ..color = AppTheme.iosBlue.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MapTexturePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _TripFloatingTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  const _TripFloatingTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FloatingCircle(icon: CupertinoIcons.chevron_left, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: ModernGlass(
            radius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleSm(),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelSm(
                    color: CupertinoColors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _FloatingCircle(icon: CupertinoIcons.search, onTap: onSearch),
        const SizedBox(width: 8),
        _FloatingCircle(icon: CupertinoIcons.ellipsis, onTap: onMenu),
      ],
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(46, 46),
      onPressed: onTap,
      child: ModernGlass(
        radius: 23,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: CupertinoColors.white, size: 22),
        ),
      ),
    );
  }
}

class _WorkspaceSegmentedTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _WorkspaceSegmentedTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 26,
      padding: const EdgeInsets.all(6),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selectedTab,
        backgroundColor: CupertinoColors.transparent,
        thumbColor: CupertinoColors.white.withValues(alpha: 0.16),
        children: const {
          0: _SegmentLabel(icon: CupertinoIcons.calendar, label: 'Lịch trình'),
          1: _SegmentLabel(
            icon: CupertinoIcons.arrow_right_arrow_left,
            label: 'Nợ',
          ),
          2: _SegmentLabel(icon: CupertinoIcons.creditcard, label: 'Quỹ'),
          3: _SegmentLabel(icon: CupertinoIcons.person_2, label: 'Khách'),
        },
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SegmentLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelXs(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripHeroWorkspaceCard extends StatelessWidget {
  final String tripName;
  final String destination;
  final String dateLabel;
  final Uint8List? coverBytes;
  final String? coverImageUrl;
  final double totalSpent;
  final String baseCurrency;
  final int memberCount;
  final VoidCallback onShare;
  final VoidCallback onSettings;

  const _TripHeroWorkspaceCard({
    required this.tripName,
    required this.destination,
    required this.dateLabel,
    this.coverBytes,
    this.coverImageUrl,
    required this.totalSpent,
    required this.baseCurrency,
    required this.memberCount,
    required this.onShare,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 34,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: SizedBox(
          height: 360,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverBytes != null)
                Image.memory(coverBytes!, fit: BoxFit.cover)
              else if ((coverImageUrl ?? '').isNotEmpty)
                Image.network(
                  coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      CustomPaint(painter: _WorkspaceCoverPainter(tripName)),
                )
              else
                CustomPaint(painter: _WorkspaceCoverPainter(tripName)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.black.withValues(alpha: 0.18),
                      CupertinoColors.black.withValues(alpha: 0.18),
                      CupertinoColors.black.withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    _HeroAction(
                      icon: CupertinoIcons.square_arrow_up,
                      onTap: onShare,
                    ),
                    const Spacer(),
                    _HeroAction(
                      icon: CupertinoIcons.gear_solid,
                      onTap: onSettings,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.labelSm(
                        color: CupertinoColors.white.withValues(alpha: 0.72),
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tripName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel,
                      style: AppTheme.bodySm(
                        color: CupertinoColors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _WorkspaceMetric(
                            icon: CupertinoIcons.money_dollar,
                            label: 'Đã chi',
                            value: '${formatMoney(totalSpent)} $baseCurrency',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkspaceMetric(
                            icon: CupertinoIcons.person_2,
                            label: 'Khách',
                            value: '$memberCount người',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CupertinoColors.black.withValues(alpha: 0.36),
          shape: BoxShape.circle,
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 20),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<DateTime> days;
  final int selectedIndex;
  final Map<int, int> activityCounts;
  final ValueChanged<int> onSelected;

  const _DaySelector({
    required this.days,
    required this.selectedIndex,
    required this.activityCounts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemBuilder: (context, index) {
          final day = days[index];
          return _DayChip(
            index: index,
            day: day,
            selected: selectedIndex == index,
            activityCount: activityCounts[index] ?? 0,
            onTap: () => onSelected(index),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: days.length,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int index;
  final DateTime day;
  final bool selected;
  final int activityCount;
  final VoidCallback onTap;

  const _DayChip({
    required this.index,
    required this.day,
    required this.selected,
    required this.activityCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.iosBlue : CupertinoColors.white;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(78, 88),
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 78,
        height: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.iosBlue.withValues(alpha: 0.26)
              : CupertinoColors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? AppTheme.iosBlue.withValues(alpha: 0.46)
                : CupertinoColors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppTheme.iosBlue.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ngày ${index + 1}',
              style: AppTheme.labelXs(color: color.withValues(alpha: 0.78)),
            ),
            const SizedBox(height: 6),
            Text(
              '${day.day}',
              style: TextStyle(
                color: color,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'thg ${day.month}',
              style: AppTheme.labelXs(color: color.withValues(alpha: 0.72)),
            ),
            if (activityCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.iosBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayPlanPanel extends StatelessWidget {
  final int dayIndex;
  final DateTime day;
  final String destination;
  final List<_TripActivityDraft> activities;
  final VoidCallback onAddActivity;
  final VoidCallback onOpenDay;

  const _DayPlanPanel({
    required this.dayIndex,
    required this.day,
    required this.destination,
    required this.activities,
    required this.onAddActivity,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ngày ${dayIndex + 1}', style: AppTheme.headlineMd()),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day} thg ${day.month} • $destination',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(42, 42),
                onPressed: onAddActivity,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppTheme.iosBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (activities.isEmpty)
            _EmptyItineraryCard(onAdd: onAddActivity)
          else ...[
            for (final activity in activities)
              _TimelineActivityRow(activity: activity),
            const SizedBox(height: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onOpenDay,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mở lịch ngày này',
                  style: AppTheme.titleSm(color: AppTheme.iosBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyItineraryCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyItineraryCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.calendar_badge_plus, size: 34),
          const SizedBox(height: 10),
          Text('Chưa có hoạt động', style: AppTheme.titleSm()),
          const SizedBox(height: 6),
          Text(
            'Thêm chuyến bay, lưu trú, nhà hàng hoặc điểm tham quan cho ngày này.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySm(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: AppTheme.iosBlue,
            borderRadius: BorderRadius.circular(22),
            onPressed: onAdd,
            child: const Text(
              'Thêm hoạt động',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineActivityRow extends StatelessWidget {
  final _TripActivityDraft activity;

  const _TimelineActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              activity.timeLabel,
              style: AppTheme.labelSm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, color: activity.color, size: 18),
              ),
              Container(
                width: 1,
                height: 42,
                color: CupertinoColors.white.withValues(alpha: 0.10),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TripModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelSm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppTheme.iosBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTabScroll extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _GlassTabScroll({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ActivityTimeSelector extends StatelessWidget {
  final String timeLabel;
  final VoidCallback onTap;

  const _ActivityTimeSelector({
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.iosBlue.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.clock,
                color: AppTheme.iosBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Giờ hoạt động',
                style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(timeLabel, style: AppTheme.titleSm(color: AppTheme.iosBlue)),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _GooglePlacesNotice extends StatelessWidget {
  final bool configured;

  const _GooglePlacesNotice({required this.configured});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            configured ? CupertinoIcons.check_mark_circled : CupertinoIcons.map,
            color: AppTheme.iosBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  configured
                      ? 'Google Places đã sẵn sàng'
                      : 'Placeholder Google Places',
                  style: AppTheme.titleSm(),
                ),
                const SizedBox(height: 4),
                Text(
                  configured
                      ? 'API key đã được truyền qua dart-define. Có thể đổi danh sách mock thành endpoint Places/proxy.'
                      : 'Chưa có GOOGLE_MAPS_API_KEY nên đang dùng gợi ý mẫu. Thêm key để nối Google Maps Places.',
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCategoryButton extends StatelessWidget {
  final _ActivityCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.20)
              : CupertinoColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected
                ? category.color.withValues(alpha: 0.38)
                : CupertinoColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: category.color, size: 28),
            const SizedBox(height: 8),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelXs(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  final _PlaceSuggestion suggestion;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PlaceSuggestionTile({
    required this.suggestion,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: iosSeparator(context), width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.name, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    '${suggestion.address} • ${suggestion.rating} sao',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.plus_circle,
              color: AppTheme.iosBlue,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPlaceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ManualPlaceButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: IosSecondaryButton(
        label: label,
        icon: CupertinoIcons.location,
        onPressed: onTap,
      ),
    );
  }
}

class _ActivityTemplateTile extends StatelessWidget {
  final _TripActivityTemplate template;
  final String destination;
  final VoidCallback onTap;

  const _ActivityTemplateTile({
    required this.template,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: iosSeparator(context), width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: template.color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(template.icon, color: template.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    '${template.defaultTime} • ${template.subtitle} • $destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.arrow_turn_up_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedActivityCard extends StatelessWidget {
  final _TripActivityDraft activity;

  const _DetailedActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernGlass(
        radius: 24,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activity.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(activity.icon, color: activity.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.timeLabel,
                    style: AppTheme.labelSm(color: activity.color),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.title, style: AppTheme.titleSm()),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
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

class _TripSettingsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String inviteCode;

  const _TripSettingsHeader({
    required this.title,
    required this.subtitle,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.iosBlue.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.flag_fill,
              color: AppTheme.iosBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleSm(),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          if (inviteCode.isNotEmpty)
            Text(inviteCode, style: AppTheme.labelSm(color: AppTheme.iosBlue)),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 58),
                child: Container(height: 0.5, color: iosSeparator(context)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool destructive;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppTheme.iosRed
        : CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: destructive ? AppTheme.iosRed : AppTheme.iosBlue,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyMd(
                  color: color,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;
  final String shareUrl;
  final VoidCallback onShare;

  const _InviteCodeCard({
    required this.inviteCode,
    required this.shareUrl,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(CupertinoIcons.qrcode, color: AppTheme.iosBlue, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inviteCode.isEmpty ? 'Chưa có mã' : inviteCode,
                  style: AppTheme.headlineMd(),
                ),
                const SizedBox(height: 4),
                Text(
                  shareUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(42, 42),
            onPressed: onShare,
            child: const Icon(CupertinoIcons.square_arrow_up),
          ),
        ],
      ),
    );
  }
}

class _MemberManageCard extends StatelessWidget {
  final TripMemberModel member;
  final VoidCallback onTap;

  const _MemberManageCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 0 || member.roleName == 'Owner';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: ModernGlass(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (isOwner ? AppTheme.iosBlue : AppTheme.iosBlue)
                      .withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOwner ? CupertinoIcons.star_fill : CupertinoIcons.person,
                  color: isOwner ? AppTheme.iosBlue : AppTheme.iosBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.nickName ?? 'Thành viên',
                      style: AppTheme.titleSm(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.roleName ??
                          (isOwner ? 'Chủ chuyến đi' : 'Thành viên'),
                      style: AppTheme.bodySm(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (member.userTier == 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.iosBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('PRO', style: AppTheme.labelXs()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkspaceMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.iosBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelXs(
                    color: CupertinoColors.white.withValues(alpha: 0.66),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelSm(color: CupertinoColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCoverPainter extends CustomPainter {
  final String seed;

  const _WorkspaceCoverPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final hash = seed.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSVColor.fromAHSV(1, (hash % 360).toDouble(), 0.58, 0.78).toColor(),
            const Color(0xFF102238),
            AppTheme.canvasDark,
          ],
        ).createShader(rect),
    );

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.iosBlue.withValues(alpha: 0.48),
              CupertinoColors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.28),
              radius: size.width * 0.45,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.45,
      glow,
    );

    final path = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.52,
        size.width * 0.46,
        size.height * 0.92,
        size.width,
        size.height * 0.62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = CupertinoColors.black.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _WorkspaceCoverPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondaryDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.calendar,
                    color: AppTheme.iosBlue, size: 18),
                const SizedBox(width: 10),
                Text(label, style: AppTheme.bodyMd()),
              ],
            ),
            Row(
              children: [
                Text(value, style: AppTheme.titleSm(color: AppTheme.iosBlue)),
                const SizedBox(width: 4),
                Icon(CupertinoIcons.chevron_right,
                    size: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegCard extends StatelessWidget {
  final int index;
  final TripLegModel leg;
  final String dateLabel;
  final VoidCallback onDelete;

  const _LegCard({
    required this.index,
    required this.leg,
    required this.dateLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.iosBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leg.name, style: AppTheme.titleSm()),
                if (leg.destinationLabel != leg.name)
                  Text(
                    leg.destinationLabel,
                    style: AppTheme.bodySm(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: AppTheme.bodySm(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            child: const Icon(CupertinoIcons.trash,
                color: AppTheme.iosRed, size: 18),
          ),
        ],
      ),
    );
  }
}
