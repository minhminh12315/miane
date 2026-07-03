import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../home/presentation/controllers/trips_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider).valueOrNull ?? [];
    final activeTrips = trips.where((trip) => trip.status == 0).length;
    final upcomingTrips = trips.where((trip) => trip.status == 2).length;

    final categories = [
      const _CategoryExpense(
        name: 'Di chuyển',
        amount: 4850000,
        percentage: 0.545,
        color: AppTheme.iosBlue,
        icon: CupertinoIcons.airplane,
      ),
      const _CategoryExpense(
        name: 'Lưu trú',
        amount: 2800000,
        percentage: 0.315,
        color: AppTheme.iosGold,
        icon: CupertinoIcons.bed_double,
      ),
      const _CategoryExpense(
        name: 'Ăn uống',
        amount: 1250000,
        percentage: 0.14,
        color: AppTheme.iosGreen,
        icon: CupertinoIcons.cart,
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Báo cáo'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => showIosProSheet(context,
                  featureName: 'Xuất báo cáo Excel/PDF'),
              child: const Icon(CupertinoIcons.square_arrow_down),
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Chuyến đi',
              children: [
                _StatsRow(
                    total: trips.length,
                    active: activeTrips,
                    upcoming: upcomingTrips),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Chi tiêu mẫu',
              footer:
                  'Số liệu danh mục hiện là dữ liệu minh họa cho báo cáo tổng quan.',
              children: [
                Container(
                  color: iosGroupedSurface(context),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size.square(190),
                              painter:
                                  _DonutChartPainter(categories: categories),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tổng chi',
                                  style: AppTheme.labelSm(
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '8.9M đ',
                                  style: AppTheme.headlineMd(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Theo hạng mục',
              children: categories
                  .map((category) => _CategoryTile(category: category))
                  .toList(),
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Phương thức chia',
              children: [
                const IosListTile(
                  icon: CupertinoIcons.check_mark,
                  iconColor: AppTheme.iosGreen,
                  title: 'Chia đều / Chia tiền cụ thể',
                  subtitle: 'Có sẵn trong gói Basic',
                ),
                IosListTile(
                  icon: CupertinoIcons.star,
                  iconColor: AppTheme.iosGold,
                  title: 'Chia theo tỷ lệ hoặc thời gian tham gia',
                  subtitle: 'Yêu cầu MIANE Pro',
                  onTap: () => showIosProSheet(context,
                      featureName: 'Chia chi phí nâng cao'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int upcoming;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: iosGroupedSurface(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(child: _Stat(label: 'Tổng số', value: '$total')),
          Expanded(child: _Stat(label: 'Đang đi', value: '$active')),
          Expanded(child: _Stat(label: 'Sắp đi', value: '$upcoming')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.headlineMd(color: AppTheme.iosBlue)),
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

class _CategoryTile extends StatelessWidget {
  final _CategoryExpense category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: iosGroupedSurface(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: CupertinoColors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppTheme.bodyMd()),
                const SizedBox(height: 7),
                _ProgressBar(value: category.percentage, color: category.color),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(category.percentage * 100).toStringAsFixed(1)}%',
                style: AppTheme.bodySm(color: AppTheme.iosGold),
              ),
              const SizedBox(height: 3),
              Text(
                '${_formatAmount(category.amount)} đ',
                style: AppTheme.labelSm(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    return formatMoney(amount.toDouble());
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _CategoryExpense {
  final String name;
  final int amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const _CategoryExpense({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_CategoryExpense> categories;

  _DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeWidth = 18.0;
    final chartRadius = radius - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = AppTheme.surfaceSecondaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, chartRadius, bgPaint);

    var startAngle = -math.pi / 2;
    for (final category in categories) {
      final sweepAngle = category.percentage * 2 * math.pi;
      final arcPaint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: chartRadius),
        startAngle + 0.05,
        math.max(sweepAngle - 0.1, 0),
        false,
        arcPaint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
