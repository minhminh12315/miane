import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';
import 'trip_workspace_screen.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(tripsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: ModernPage(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => ref.read(tripsProvider.notifier).refresh(),
              ),
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Chuyến đi'),
              ),
              tripsState.when(
                loading: () => const SliverFillRemaining(child: IosLoading()),
                error: (err, stack) => SliverFillRemaining(
                  child: IosEmptyState(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title: 'Không tải được chuyến đi',
                    message: err.toString(),
                  ),
                ),
                data: (trips) {
                  final activeTrips =
                      trips.where((trip) => trip.status == 0).toList();
                  final pastTrips =
                      trips.where((trip) => trip.status != 0).toList();

                  if (trips.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: IosEmptyState(
                        icon: CupertinoIcons.map,
                        title: 'Chưa có chuyến đi',
                        message:
                            'Tạo chuyến đi ở Trang chủ hoặc nhập mã mời để tham gia nhóm.',
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: _TripsSummaryCard(
                            total: trips.length,
                            active: activeTrips.length,
                            finished: pastTrips.length,
                          ),
                        ),
                        if (activeTrips.isNotEmpty)
                          _TripGroup(title: 'Đang diễn ra', trips: activeTrips),
                        if (pastTrips.isNotEmpty)
                          _TripGroup(title: 'Đã kết thúc', trips: pastTrips),
                        const SizedBox(height: 132),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsSummaryCard extends StatelessWidget {
  final int total;
  final int active;
  final int finished;

  const _TripsSummaryCard({
    required this.total,
    required this.active,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF142036),
          Color(0xFF151515),
          Color(0xFF211A12),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.iosBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.iosBlue.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              CupertinoIcons.map_fill,
              color: AppTheme.iosBlue,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng quan chuyến đi', style: AppTheme.titleSm()),
                const SizedBox(height: 7),
                Text(
                  '$total chuyến đi • $active đang diễn ra • $finished đã kết thúc',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _TripGroup extends StatelessWidget {
  final String title;
  final List<TripModel> trips;

  const _TripGroup({required this.title, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: AppTheme.labelSm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final trip in trips) _TripListCard(trip: trip),
        ],
      ),
    );
  }
}

class _TripListCard extends StatelessWidget {
  final TripModel trip;

  const _TripListCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isActive = trip.status == 0;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.iosBlue : AppTheme.iosGray)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isActive ? CupertinoIcons.airplane : CupertinoIcons.archivebox,
              color: isActive ? AppTheme.iosBlue : AppTheme.iosGray,
              size: 25,
            ),
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
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.baseCurrency,
                style: AppTheme.labelSm(color: AppTheme.iosGold),
              ),
              const SizedBox(height: 10),
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
