import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/trips_provider.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);

    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;
    const Color kBorder = AppTheme.iosBorderDark;

    return Scaffold(
      backgroundColor: kDark,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
          child: Row(
            children: [
              // Home Button
              _buildFloatingButton(
                icon: Icons.wallet_rounded,
                isSelected: _currentIndex == 0,
                onTap: () => _onTabSelected(0),
                kAzure: kAzure,
                kNavy: kNavy,
                kLight: kLight,
                kBorder: kBorder,
              ),
              const SizedBox(width: 12),
              // Search Button
              _buildFloatingButton(
                icon: Icons.search_rounded,
                isSelected: _currentIndex == 1,
                onTap: () => _onTabSelected(1),
                kAzure: kAzure,
                kNavy: kNavy,
                kLight: kLight,
                kBorder: kBorder,
              ),
              const SizedBox(width: 12),
              // Stats Button (Expanded, Middle)
              Expanded(
                child: _buildFloatingStatsButton(
                  isSelected: _currentIndex == 2,
                  onTap: () => _onTabSelected(2),
                  tripCount: trips.valueOrNull?.length ?? 0,
                  kAzure: kAzure,
                  kNavy: kNavy,
                  kLight: kLight,
                  kBorder: kBorder,
                ),
              ),
              const SizedBox(width: 12),
              // Add Button
              _buildFloatingButton(
                icon: Icons.add_rounded,
                isSelected: false,
                onTap: () => _handleAddNewTrip(context),
                kAzure: kAzure,
                kNavy: kNavy,
                kLight: kLight,
                kBorder: kBorder,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color kAzure,
    required Color kNavy,
    required Color kLight,
    required Color kBorder,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 54,
        height: 54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPrimary
                    ? kAzure
                    : (isSelected
                        ? kAzure.withOpacity(0.15)
                        : kNavy.withOpacity(0.7)),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: isPrimary
                      ? kAzure
                      : (isSelected
                          ? kAzure.withOpacity(0.5)
                          : kBorder.withOpacity(0.4)),
                  width: 0.5,
                ),
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : (isSelected ? kAzure : kLight.withOpacity(0.4)),
                size: isPrimary ? 26 : 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingStatsButton({
    required bool isSelected,
    required VoidCallback onTap,
    required int tripCount,
    required Color kAzure,
    required Color kNavy,
    required Color kLight,
    required Color kBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? kAzure.withOpacity(0.15)
                    : kNavy.withOpacity(0.7),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: isSelected
                      ? kAzure.withOpacity(0.5)
                      : kBorder.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: isSelected ? kAzure : kLight.withOpacity(0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thống kê ($tripCount)',
                    style: GoogleFonts.beVietnamPro(
                      color: isSelected ? kAzure : kLight.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddNewTrip(BuildContext context) {
    final tripsState = ref.read(tripsProvider);
    final tripsList = tripsState.valueOrNull ?? [];
    if (tripsList.length >= 2) {
      _showProPaywall(context);
      return;
    }

    final nameController = TextEditingController();
    final destController = TextEditingController();

    const Color kDark = Color(0xFF1C1C1E);
    const Color kNavy = Color(0xFF2C2C2E);
    const Color kAzure = Color(0xFF007AFF);
    const Color kLight = Color(0xFFFFFFFF);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Tạo chuyến đi mới',
            style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tên chuyến đi',
                  labelStyle: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.6), fontSize: 13),
                  filled: true,
                  fillColor: kNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Điểm đến',
                  labelStyle: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.6), fontSize: 13),
                  filled: true,
                  fillColor: kNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final dest = destController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await ref.read(tripsProvider.notifier).createTrip(
                      name,
                      dest.isEmpty ? null : 'Điểm đến: $dest',
                      'VND',
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Không thể tạo chuyến đi: ${e.toString().replaceAll('ApiException: ', '')}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text('Tạo', style: GoogleFonts.beVietnamPro(color: kAzure, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }



  void _showProPaywall(BuildContext context) {
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
                'Bạn đang dùng gói Basic (Giới hạn tối đa 2 chuyến đi). Nâng cấp MIANE Pro để tạo không giới hạn chuyến đi & quản lý mọi dự án du lịch!',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  color: kLight.withOpacity(0.7),
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
                        color: kLight.withOpacity(0.8),
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
                        color: kLight.withOpacity(0.8),
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
                        color: kLight.withOpacity(0.8),
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
}
