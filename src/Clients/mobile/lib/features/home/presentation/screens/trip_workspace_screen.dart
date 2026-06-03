import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class TripWorkspaceScreen extends StatelessWidget {
  final String tripName;
  final String destination;
  final String budgetText;
  final double budgetProgress;
  final String spentText;
  final String remainingText;

  const TripWorkspaceScreen({
    super.key,
    required this.tripName,
    required this.destination,
    required this.budgetText,
    required this.budgetProgress,
    required this.spentText,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar with back button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kNavy,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38383A),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: kLight,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chi tiết chuyến đi • ',
                                style: GoogleFonts.beVietnamPro(
                                  color: kLight.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kNavy,
                                  borderRadius: BorderRadius.circular(99), // capsule pill
                                ),
                                child: Text(
                                  'BASIC',
                                  style: GoogleFonts.beVietnamPro(
                                    color: kAzure,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tripName,
                            style: GoogleFonts.inter(
                              color: kLight,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 1. Lịch trình tiếp theo (Itinerary Card)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch trình tiếp theo',
                      style: GoogleFonts.inter(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kAzure.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12), // rounded: md
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: kAzure,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tham quan Dinh Độc Lập',
                                  style: GoogleFonts.beVietnamPro(
                                    color: kLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hôm nay, 14:00 • Quận 1, TP. HCM',
                                  style: GoogleFonts.beVietnamPro(
                                    color: kLight.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kLight,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Tổng ngân sách nhóm (Group Budget Card)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kNavy, Color(0xFF2C2C2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16), // rounded: lg
                    border: Border.all(
                      color: const Color(0xFF38383A),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng ngân sách chi tiêu nhóm',
                            style: GoogleFonts.beVietnamPro(
                              color: kLight.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Gói Basic',
                            style: GoogleFonts.beVietnamPro(
                              color: kAzure,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            spentText,
                            style: GoogleFonts.beVietnamPro(
                              color: kLight,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/ $budgetText',
                            style: GoogleFonts.beVietnamPro(
                              color: kLight.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99), // capsule pill
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          minHeight: 8,
                          backgroundColor: kDark.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(kAzure),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã chi ${(budgetProgress * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.beVietnamPro(
                              color: kAzure,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Còn lại $remainingText',
                            style: GoogleFonts.beVietnamPro(
                              color: kLight.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Trạng thái tài chính cá nhân (Personal Debt status card)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài chính cá nhân',
                      style: GoogleFonts.inter(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12), // rounded: md
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bạn đang nợ Nam',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.redAccent[100],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '250.000 đ',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.redAccent[100],
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12), // rounded: md
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Huy đang nợ bạn',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.greenAccent[200],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '120.000 đ',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.greenAccent[200],
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // AI Smart Actions Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showProPaywall(context, 'Quét hóa đơn AI'),
                        child: _buildAiActionCard(
                          title: 'Quét hóa đơn AI',
                          subtitle: 'AI bóc tách OCR',
                          icon: Icons.document_scanner_rounded,
                          kNavy: kNavy,
                          kGold: kGold,
                          kLight: kLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showProPaywall(context, 'Lên lịch trình AI'),
                        child: _buildAiActionCard(
                          title: 'Lên lịch trình AI',
                          subtitle: 'Gợi ý điểm đến',
                          icon: Icons.psychology_rounded,
                          kNavy: kNavy,
                          kGold: kGold,
                          kLight: kLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giao dịch chuyến đi',
                      style: GoogleFonts.inter(
                        color: kLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Xem thêm',
                      style: GoogleFonts.beVietnamPro(
                        color: kAzure,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Transaction List
            _buildTransactionList(kNavy: kNavy, kAzure: kAzure, kGold: kGold, kLight: kLight),
          ],
        ),
      ),
    );
  }

  Widget _buildAiActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color kNavy,
    required Color kGold,
    required Color kLight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(16), // rounded: lg
        border: Border.all(
          color: kGold.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: kGold,
                size: 24,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99), // capsule pill
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.beVietnamPro(
                    color: kGold,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              color: kLight.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList({
    required Color kNavy,
    required Color kAzure,
    required Color kGold,
    required Color kLight,
  }) {
    final transactions = [
      _MockTransaction(
        title: 'Vé máy bay khứ hồi',
        category: 'Di chuyển',
        amount: -4500000,
        date: 'Hôm nay, 10:24 AM',
        icon: Icons.flight_takeoff_rounded,
        iconColor: kAzure,
      ),
      _MockTransaction(
        title: 'Đặt phòng khách sạn',
        category: 'Lưu trú',
        amount: -2800000,
        date: 'Hôm nay, 08:15 AM',
        icon: Icons.hotel_rounded,
        iconColor: kGold,
      ),
      _MockTransaction(
        title: 'Nhận quỹ nhóm',
        category: 'Thu nhập',
        amount: 5000000,
        date: 'Hôm qua, 06:30 PM',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Colors.greenAccent,
      ),
      _MockTransaction(
        title: 'Ăn tối hải sản',
        category: 'Ăn uống',
        amount: -1250000,
        date: 'Hôm qua, 07:45 PM',
        icon: Icons.restaurant_rounded,
        iconColor: Colors.orangeAccent,
      ),
      _MockTransaction(
        title: 'Thuê xe máy tự lái',
        category: 'Di chuyển',
        amount: -350000,
        date: '01 Thg 6, 09:00 AM',
        icon: Icons.motorcycle_rounded,
        iconColor: kAzure,
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = transactions[index];
            final isExpense = tx.amount < 0;
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tx.iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.icon,
                      color: tx.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: GoogleFonts.beVietnamPro(
                            color: kLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.date,
                          style: GoogleFonts.beVietnamPro(
                            color: kLight.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${isExpense ? "" : "+"}${_formatAmount(tx.amount)} đ',
                    style: GoogleFonts.beVietnamPro(
                      color: isExpense ? Colors.redAccent[100] : Colors.greenAccent[200],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: transactions.length,
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
      barrierColor: Colors.black.withValues(alpha: 0.8),
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
                  color: kLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
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
                  color: kLight.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.all_inclusive_rounded, color: kGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Không giới hạn chuyến đi & thành viên',
                      style: GoogleFonts.beVietnamPro(
                        color: kLight.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.currency_exchange_rounded, color: kGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đa tiền tệ & Quy đổi tỷ giá thời gian thực',
                      style: GoogleFonts.beVietnamPro(
                        color: kLight.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: kGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI OCR Quét hóa đơn & AI Lên lịch trình',
                      style: GoogleFonts.beVietnamPro(
                        color: kLight.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
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
                        color: kGold.withValues(alpha: 0.25),
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
                    color: kLight.withValues(alpha: 0.5),
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

  String _formatAmount(int amount) {
    final absVal = amount.abs();
    if (absVal >= 1000000) {
      final double millions = absVal / 1000000;
      return '${amount < 0 ? "-" : ""}${millions.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${amount < 0 ? "-" : ""}${absVal.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.')}';
  }
}

class _MockTransaction {
  final String title;
  final String category;
  final int amount;
  final String date;
  final IconData icon;
  final Color iconColor;

  _MockTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconColor,
  });
}
