import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';
import '../widgets/trip_share_sheet.dart';
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
                  final covers = ref.watch(tripCoverMemoryProvider);
                  final ongoingTrips = trips
                      .where(
                        (trip) =>
                            trip.timelineStatus == TripTimelineStatus.ongoing,
                      )
                      .toList();
                  final upcomingTrips = trips
                      .where(
                        (trip) =>
                            trip.timelineStatus == TripTimelineStatus.upcoming,
                      )
                      .toList();
                  final pastTrips = trips
                      .where(
                        (trip) =>
                            trip.timelineStatus == TripTimelineStatus.completed,
                      )
                      .toList();

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
                            ongoing: ongoingTrips.length,
                            upcoming: upcomingTrips.length,
                            finished: pastTrips.length,
                          ),
                        ),
                        if (ongoingTrips.isNotEmpty)
                          _TripGroup(
                            title: 'Đang diễn ra',
                            trips: ongoingTrips,
                            covers: covers,
                            onDeleteTrip: (trip) =>
                                _confirmDeleteTrip(context, ref, trip),
                          ),
                        if (upcomingTrips.isNotEmpty)
                          _TripGroup(
                            title: 'Sắp diễn ra',
                            trips: upcomingTrips,
                            covers: covers,
                            onDeleteTrip: (trip) =>
                                _confirmDeleteTrip(context, ref, trip),
                          ),
                        if (pastTrips.isNotEmpty)
                          _TripGroup(
                            title: 'Đã đi',
                            trips: pastTrips,
                            covers: covers,
                            onDeleteTrip: (trip) =>
                                _confirmDeleteTrip(context, ref, trip),
                          ),
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

  Future<void> _confirmDeleteTrip(
    BuildContext context,
    WidgetRef ref,
    TripModel trip,
  ) async {
    final confirmed = await showIosConfirm(
      context,
      title: 'Xóa chuyến đi?',
      message:
          'Chuyến "${trip.name}" sẽ bị xóa cùng thành viên, lịch trình và tệp liên quan. Thao tác này không thể hoàn tác.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(tripsProvider.notifier).deleteTrip(trip.id);
      if (!context.mounted) return;
      await showIosMessage(
        context,
        title: 'Đã xóa chuyến đi',
        message: 'Chuyến "${trip.name}" đã được xóa.',
      );
    } catch (e) {
      if (!context.mounted) return;
      await showIosMessage(
        context,
        message:
            'Không thể xóa chuyến đi: ${e.toString().replaceAll('ApiException: ', '')}',
        isError: true,
      );
    }
  }
}

class _TripsSummaryCard extends StatelessWidget {
  final int total;
  final int ongoing;
  final int upcoming;
  final int finished;

  const _TripsSummaryCard({
    required this.total,
    required this.ongoing,
    required this.upcoming,
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
                  '$total chuyến đi • $ongoing đang diễn ra • $upcoming sắp diễn ra • $finished đã đi',
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
  final Map<String, Uint8List> covers;
  final ValueChanged<TripModel> onDeleteTrip;

  const _TripGroup({
    required this.title,
    required this.trips,
    required this.covers,
    required this.onDeleteTrip,
  });

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
          for (final trip in trips)
            _TripListCard(
              trip: trip,
              coverBytes: covers[trip.id],
              onDelete: trip.userRole == 0 ? () => onDeleteTrip(trip) : null,
            ),
        ],
      ),
    );
  }
}

class _TripListCard extends StatelessWidget {
  final TripModel trip;
  final Uint8List? coverBytes;
  final VoidCallback? onDelete;

  const _TripListCard({
    required this.trip,
    this.coverBytes,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip.timelineStatus;
    final statusColor = switch (status) {
      TripTimelineStatus.upcoming => AppTheme.iosGold,
      TripTimelineStatus.ongoing => AppTheme.iosGreen,
      TripTimelineStatus.completed => AppTheme.iosGray,
    };
    final destination = trip.destinationLabel;
    final createdAgo = _relativeDate(trip.createdAt);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => TripWorkspaceScreen(
              tripId: trip.id,
              tripName: trip.name,
              destination: trip.destinationLabel,
              baseCurrency: trip.baseCurrency,
            ),
          ),
        );
      },
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        radius: AppTheme.radiusXl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 176,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverBytes != null)
                      Image.memory(coverBytes!, fit: BoxFit.cover)
                    else if ((trip.coverImageUrl ?? '').isNotEmpty)
                      Image.network(trip.coverImageUrl!, fit: BoxFit.cover)
                    else
                      CustomPaint(painter: _TripCoverPainter(trip.name)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CupertinoColors.black.withValues(alpha: 0.05),
                            CupertinoColors.black.withValues(alpha: 0.74),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(
                            label: trip.timelineStatusLabel,
                            color: statusColor,
                          ),
                          const SizedBox(height: 9),
                          Text(
                            trip.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 26,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySm(
                              color:
                                  CupertinoColors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TripMetric(
                            icon: CupertinoIcons.person_2_fill,
                            label: 'Thành viên',
                            value: '${trip.memberCount}',
                          ),
                        ),
                        Expanded(
                          child: _TripMetric(
                            icon: CupertinoIcons.money_dollar,
                            label: 'Tiền tệ',
                            value: trip.baseCurrency,
                          ),
                        ),
                        Expanded(
                          child: _TripMetric(
                            icon: CupertinoIcons.calendar,
                            label: 'Tạo lúc',
                            value: createdAgo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MemberAvatarStack(count: trip.memberCount),
                        const Spacer(),
                        if (onDelete != null) ...[
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 44),
                            onPressed: onDelete,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.iosRed.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      AppTheme.iosRed.withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: AppTheme.iosRed,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          onPressed: () {
                            showTripShareSheet(
                              context,
                              TripCreationResult(
                                tripId: trip.id,
                                inviteCode: trip.inviteCode,
                                shareUrl: trip.shareUrl ??
                                    'https://miane.app/trip/${trip.inviteCode}',
                              ),
                            );
                          },
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.iosBlue.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                              border: Border.all(
                                color: AppTheme.iosBlue.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.square_arrow_up,
                                    color: AppTheme.iosBlue, size: 18),
                                const SizedBox(width: 7),
                                Text(
                                  trip.inviteCode,
                                  style:
                                      AppTheme.labelSm(color: AppTheme.iosBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          size: 18,
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

  String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Hôm nay';
    if (days < 30) return '$days ngày';
    return '${(days / 30).floor()} tháng';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: AppTheme.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.labelSm(color: CupertinoColors.white)),
        ],
      ),
    );
  }
}

class _TripMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.iosBlue, size: 18),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.titleSm()),
        const SizedBox(height: 3),
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

class _MemberAvatarStack extends StatelessWidget {
  final int count;

  const _MemberAvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, 4);
    return SizedBox(
      width: 24.0 + visible * 22,
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * 20,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HSVColor.fromAHSV(
                        1,
                        (210 + i * 38) % 360,
                        0.65,
                        0.95,
                      ).toColor(),
                      AppTheme.iosBlue,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceDark, width: 2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: AppTheme.labelSm(color: CupertinoColors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripCoverPainter extends CustomPainter {
  final String seed;

  const _TripCoverPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final code = seed.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSVColor.fromAHSV(1, (code % 360).toDouble(), 0.58, 0.75).toColor(),
            const Color(0xFF133452),
            const Color(0xFF050505),
          ],
        ).createShader(rect),
    );

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.iosGold.withValues(alpha: 0.56),
          CupertinoColors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.24),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.24),
      size.width * 0.42,
      glow,
    );

    final mountain = Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.20);
    final path = Path()
      ..moveTo(0, size.height * 0.74)
      ..lineTo(size.width * 0.24, size.height * 0.48)
      ..lineTo(size.width * 0.45, size.height * 0.69)
      ..lineTo(size.width * 0.66, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, mountain);
  }

  @override
  bool shouldRepaint(covariant _TripCoverPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
