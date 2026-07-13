import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';
import '../widgets/trip_creation_sheet.dart';
import '../widgets/trip_share_sheet.dart';
import 'join_trip_scan_screen.dart';
import 'trip_workspace_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(tripsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: ModernPage(
        child: SafeArea(
          bottom: false,
          child: tripsState.when(
            loading: () => const IosLoading(),
            error: (err, stack) => IosEmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Không tải được chuyến đi',
              message: err.toString(),
            ),
            data: (trips) {
              final activeTrips =
                  trips.where((trip) => trip.status == 0).toList();
              final pastTrips =
                  trips.where((trip) => trip.status != 0).toList();
              final featuredTrip =
                  activeTrips.isNotEmpty ? activeTrips.first : null;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () => ref.read(tripsProvider.notifier).refresh(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _HomeHeader(
                        onSettings: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: _TravelHeroCard(
                        trip: featuredTrip,
                        onCreate: () => _handleAddNewTrip(context, ref),
                        onJoin: () => _handleJoinTrip(context, ref),
                        onSettings: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _StatsStrip(
                        total: trips.length,
                        active: activeTrips.length,
                        finished: pastTrips.length,
                      ),
                    ),
                  ),
                  if (activeTrips.isNotEmpty)
                    _TripSection(title: 'Đang diễn ra', trips: activeTrips),
                  if (pastTrips.isNotEmpty)
                    _TripSection(title: 'Đã kết thúc', trips: pastTrips),
                  if (trips.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: IosEmptyState(
                        icon: CupertinoIcons.map,
                        title: 'Chưa có chuyến đi',
                        message:
                            'Tạo chuyến đầu tiên hoặc nhập mã mời để tham gia nhóm.',
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 126)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddNewTrip(BuildContext context, WidgetRef ref) async {
    final trips = ref.read(tripsProvider).valueOrNull ?? [];
    if (trips.length >= 2) {
      showIosProSheet(context, featureName: 'Tạo thêm chuyến đi');
      return;
    }
    final result = await showGlassBottomSheet<TripCreationResult>(
      context: context,
      heightFactor: 0.90,
      builder: (_) => const TripCreationSheet(),
    );
    if (result != null && context.mounted) {
      await showTripShareSheet(context, result);
      if (!context.mounted) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => TripWorkspaceScreen(
            tripId: result.tripId,
            tripName: 'Chuyến đi mới',
            destination: 'Đang tải thông tin...',
            baseCurrency: 'VND',
          ),
        ),
      );
    }
  }

  void _handleJoinTrip(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final nickController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Tham gia chuyến đi'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              IosTextField(
                controller: codeController,
                placeholder: 'Mã mời',
                prefixIcon: CupertinoIcons.number,
              ),
              const SizedBox(height: 10),
              IosTextField(
                controller: nickController,
                placeholder: 'Biệt danh của bạn',
                prefixIcon: CupertinoIcons.person,
              ),
              const SizedBox(height: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 6),
                onPressed: () async {
                  final scanned = await Navigator.of(context).push<String>(
                    CupertinoPageRoute(
                      builder: (_) => const JoinTripScanScreen(),
                    ),
                  );
                  if (scanned != null && scanned.isNotEmpty) {
                    codeController.text = scanned;
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.qrcode_viewfinder, size: 20),
                    SizedBox(width: 6),
                    Text('Quét mã QR'),
                  ],
                ),
              ),
            ],
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
              final code = codeController.text.trim();
              final nick = nickController.text.trim();
              if (code.isEmpty) return;

              try {
                await ref.read(tripsProvider.notifier).joinTrip(
                      code,
                      nick.isEmpty ? null : nick,
                    );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) {
                  await showIosMessage(
                    context,
                    message:
                        'Không thể tham gia: ${e.toString().replaceAll('ApiException: ', '')}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onSettings;

  const _HomeHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào',
                style: AppTheme.bodySm(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 3),
              Text('Khách du lịch', style: AppTheme.displayLg()),
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onSettings,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondaryDark,
              shape: BoxShape.circle,
              border: Border.all(
                  color: CupertinoColors.white.withValues(alpha: 0.1)),
            ),
            child:
                const Icon(CupertinoIcons.person_fill, color: AppTheme.iosBlue),
          ),
        ),
      ],
    );
  }
}

class _TravelHeroCard extends StatelessWidget {
  final TripModel? trip;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onSettings;

  const _TravelHeroCard({
    required this.trip,
    required this.onCreate,
    required this.onJoin,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final title = trip?.name ?? 'Your Travel Companion';
    final subtitle = trip?.description ??
        'Tạo chuyến đi, chia tiền và giữ mọi thứ gọn trong một app.';

    return ModernCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A3325),
          Color(0xFF24221F),
          Color(0xFF111111),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMd(
              color: CupertinoColors.white.withValues(alpha: 0.72),
            ).copyWith(height: 1.35),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ModernActionCircle(
                  icon: CupertinoIcons.add,
                  label: 'New trip',
                  color: AppTheme.iosLight,
                  onTap: onCreate,
                ),
              ),
              Expanded(
                child: ModernActionCircle(
                  icon: CupertinoIcons.person_add,
                  label: 'Join',
                  color: AppTheme.iosGold,
                  onTap: onJoin,
                ),
              ),
              const Expanded(
                child: ModernActionCircle(
                  icon: CupertinoIcons.map,
                  label: 'Trips',
                  color: AppTheme.iosBlue,
                ),
              ),
              Expanded(
                child: ModernActionCircle(
                  icon: CupertinoIcons.settings,
                  label: 'Profile',
                  color: AppTheme.iosPink,
                  onTap: onSettings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ModernGlass(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _RoutePoint(
                    label: trip == null ? 'Start' : 'Invite',
                    value: trip?.inviteCode ?? 'MIANE',
                    alignEnd: false,
                  ),
                ),
                const Icon(CupertinoIcons.airplane,
                    color: AppTheme.iosBlue, size: 28),
                Expanded(
                  child: _RoutePoint(
                    label: trip == null ? 'Ready' : 'Currency',
                    value: trip?.baseCurrency ?? 'GO',
                    alignEnd: true,
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

class _RoutePoint extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _RoutePoint({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSm(
            color: CupertinoColors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int total;
  final int active;
  final int finished;

  const _StatsStrip({
    required this.total,
    required this.active,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      radius: 26,
      child: Row(
        children: [
          Expanded(child: _StatItem(label: 'Tổng', value: '$total')),
          Expanded(child: _StatItem(label: 'Đang đi', value: '$active')),
          Expanded(child: _StatItem(label: 'Kết thúc', value: '$finished')),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.headlineMd(color: AppTheme.iosGold)),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.labelSm(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _TripSection extends StatelessWidget {
  final String title;
  final List<TripModel> trips;

  const _TripSection({required this.title, required this.trips});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleSm()),
            const SizedBox(height: 12),
            ...trips.map((trip) => _TripCard(trip: trip)),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => TripWorkspaceScreen(
              tripId: trip.id,
              tripName: trip.name,
              destination: trip.description ?? 'Không có mô tả',
              baseCurrency: trip.baseCurrency,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.iosBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(CupertinoIcons.map_fill,
                color: AppTheme.iosBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleSm(),
                ),
                const SizedBox(height: 5),
                Text(
                  trip.description ?? 'Không có mô tả',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(label: '${trip.memberCount} người'),
                    const SizedBox(width: 8),
                    _Pill(label: trip.baseCurrency),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.inviteCode,
                style: AppTheme.labelSm(color: AppTheme.iosGold),
              ),
              const SizedBox(height: 16),
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: AppTheme.labelXs(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
