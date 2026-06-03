import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/controllers/trips_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(tripsProvider);
    final tripsList = tripsState.value ?? [];

    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    // Mock category expenses
    final categories = [
      _CategoryExpense(
        name: 'Di chuyển',
        amount: 4850000,
        percentage: 0.545,
        color: kAzure,
        icon: Icons.flight_takeoff_rounded,
      ),
      _CategoryExpense(
        name: 'Lưu trú',
        amount: 2800000,
        percentage: 0.315,
        color: kGold,
        icon: Icons.hotel_rounded,
      ),
      _CategoryExpense(
        name: 'Ăn uống',
        amount: 1250000,
        percentage: 0.14,
        color: Colors.orangeAccent,
        icon: Icons.restaurant_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo chi tiêu',
                          style: GoogleFonts.inter(
                            color: kLight,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thống kê khoản chi của chuyến đi',
                          style: GoogleFonts.beVietnamPro(
                            color: kAzure,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Multi-currency Premium Switch
                  GestureDetector(
                    onTap: () => _showProPaywall(context, 'Đa tiền tệ & Tỷ giá thực'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(12), // rounded: md
                        border: Border.all(color: const Color(0xFF38383A), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_exchange_rounded, color: kGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Đa tiền tệ',
                            style: GoogleFonts.beVietnamPro(
                              color: kGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: AppTheme.thinBorder,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Tổng số', '${tripsList.length} chuyến', kAzure, kLight),
                    Container(width: 0.5, height: 32, color: kLight.withOpacity(0.1)),
                    _buildStatCol(
                      'Đang đi',
                      '${tripsList.where((t) => t.status == 0).length} chuyến',
                      AppTheme.iosGreen,
                      kLight,
                    ),
                    Container(width: 0.5, height: 32, color: kLight.withOpacity(0.1)),
                    _buildStatCol(
                      'Sắp đi',
                      '${tripsList.where((t) => t.status == 2).length} chuyến',
                      kGold,
                      kLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Donut Chart Container
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DonutChartPainter(
                            categories: categories,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tổng chi tiêu',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8.9M đ',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Export Report Pro Button
              GestureDetector(
                onTap: () => _showProPaywall(context, 'Xuất báo cáo Excel/PDF'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(12), // rounded: md
                    border: Border.all(
                      color: const Color(0xFF38383A),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download_rounded, color: kAzure, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Xuất báo cáo (Excel/PDF)',
                        style: GoogleFonts.beVietnamPro(
                          color: kAzure,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_rounded, color: kGold, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Category Details List
              Text(
                'Chi tiết theo hạng mục',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(16), // rounded: lg
                      border: Border.all(
                        color: const Color(0xFF38383A),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat.icon,
                            color: cat.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: GoogleFonts.beVietnamPro(
                                  color: kLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Custom progress indicator bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99), // capsule pill
                                child: LinearProgressIndicator(
                                  value: cat.percentage,
                                  backgroundColor: const Color(0xFF2C2C2E),
                                  valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(cat.percentage * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.beVietnamPro(
                                color: kGold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatAmount(cat.amount)} đ',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Split-Wise Basic/Pro differences
              Text(
                'Phương thức chia sẻ chi phí',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildSplitMethodRow(
                title: 'Chia đều / Chia tiền cụ thể',
                subtitle: 'Gói Basic miễn phí',
                isPro: false,
                kNavy: kNavy,
                kGold: kGold,
                kLight: kLight,
              ),
              const SizedBox(height: 12),
              _buildSplitMethodRow(
                title: 'Chia theo tỷ lệ % / Thời gian tham gia',
                subtitle: 'Yêu cầu mở khóa MIANE Pro',
                isPro: true,
                kNavy: kNavy,
                kGold: kGold,
                kLight: kLight,
                onTap: () => _showProPaywall(context, 'Chia chi phí nâng cao'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitMethodRow({
    required String title,
    required String subtitle,
    required bool isPro,
    required Color kNavy,
    required Color kGold,
    required Color kLight,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kNavy,
          borderRadius: BorderRadius.circular(16), // rounded: lg
          border: Border.all(
            color: isPro ? kGold.withOpacity(0.2) : const Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    color: kLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    color: isPro ? kGold : kLight.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (isPro)
              Icon(Icons.workspace_premium_rounded, color: kGold, size: 20)
            else
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showProPaywall(BuildContext context, String featureName) {
    const Color kDark = AppTheme.surfaceDark;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: kDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: kGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mở khóa MIANE Pro',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Để sử dụng tính năng "$featureName" và mở khóa không giới hạn thành viên, chuyến đi, tự động quy đổi ngoại tệ cùng với AI Trí Tuệ Nhân Tạo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  color: kLight.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildBenefitRow(Icons.all_inclusive_rounded, 'Không giới hạn chuyến đi & thành viên', kGold, kLight),
              const SizedBox(height: 12),
              _buildBenefitRow(Icons.currency_exchange_rounded, 'Đa tiền tệ & Quy đổi tỷ giá thời gian thực', kGold, kLight),
              const SizedBox(height: 12),
              _buildBenefitRow(Icons.psychology_rounded, 'AI OCR Quét hóa đơn & AI Lên lịch trình', kGold, kLight),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kGold,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Nâng cấp ngay • 99.000 đ / tháng',
                      style: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF1C1C1E),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Để sau',
                  style: GoogleFonts.beVietnamPro(
                    color: kLight.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, Color kGold, Color kLight) {
    return Row(
      children: [
        Icon(icon, color: kGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              color: kLight.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final double millions = amount / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }

  Widget _buildStatCol(String label, String value, Color color, Color textCol) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: textCol.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


class _CategoryExpense {
  final String name;
  final int amount;
  final double percentage;
  final Color color;
  final IconData icon;

  _CategoryExpense({
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
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = 18.0;
    final double chartRadius = radius - strokeWidth / 2;

    final Paint bgPaint = Paint()
      ..color = const Color(0xFF2C2C2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, chartRadius, bgPaint);

    double startAngle = -math.pi / 2;

    for (final cat in categories) {
      final double sweepAngle = cat.percentage * 2 * math.pi;

      final Paint arcPaint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: chartRadius),
        startAngle + 0.05,
        sweepAngle - 0.1,
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
