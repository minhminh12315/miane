import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trip_workspace_screen.dart';
import '../../domain/models/trip_models.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/trips_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    final tripsState = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: tripsState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: kAzure)),
          error: (err, stack) => Center(
            child: Text(
              'Có lỗi xảy ra: $err',
              style: GoogleFonts.beVietnamPro(color: Colors.redAccent),
            ),
          ),
          data: (trips) {
            final activeTrips = trips.where((t) => t.status == 0).toList();
            final pastTrips = trips.where((t) => t.status == 1).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top greeting bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Khách du lịch',
                              style: GoogleFonts.inter(
                                color: kLight,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kNavy,
                              border: Border.all(
                                color: kAzure.withOpacity(0.3),
                                width: 1.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: kAzure,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistics Overview Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(16), // rounded: lg
                        border: Border.all(
                          color: const Color(0xFF38383A),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Chuyến đi', trips.length.toString(), kAzure, kLight),
                          Container(width: 0.5, height: 40, color: const Color(0xFF38383A)),
                          _buildStatColumn('Đang đi', activeTrips.length.toString(), kAzure, kLight),
                          Container(width: 0.5, height: 40, color: const Color(0xFF38383A)),
                          _buildStatColumn('Đã kết thúc', pastTrips.length.toString(), kLight, kLight),
                        ],
                      ),
                    ),
                  ),
                ),

                // Header Section: "Chuyến đi của bạn", "Tham gia" & "Tạo mới"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chuyến đi của bạn',
                          style: GoogleFonts.inter(
                            color: kLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _handleJoinTrip(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: kNavy,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF38383A), width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.group_add_rounded, color: kGold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tham gia',
                                      style: GoogleFonts.beVietnamPro(
                                        color: kGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _handleAddNewTrip(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: kNavy,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF38383A), width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_rounded, color: kAzure, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tạo mới',
                                      style: GoogleFonts.beVietnamPro(
                                        color: kAzure,
                                        fontSize: 12,
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

                // Active Trips Section
                if (activeTrips.isNotEmpty) ...[
                  _buildSectionTitle('ĐANG DIỄN RA', kAzure),
                  _buildTripList(activeTrips, kNavy, kAzure, kGold, kLight),
                ],

                // Past Trips Section
                if (pastTrips.isNotEmpty) ...[
                  _buildSectionTitle('ĐÃ KẾT THÚC', kLight.withOpacity(0.3)),
                  _buildTripList(pastTrips, kNavy, kAzure, kGold, kLight),
                ],

                // Empty state if no trips
                if (trips.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Chưa có chuyến đi nào.',
                        style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.5)),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, Color kLight) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: kLight.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTripList(
    List<TripModel> items,
    Color kNavy,
    Color kAzure,
    Color kGold,
    Color kLight,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final trip = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(16), // rounded: lg
                border: Border.all(
                  color: const Color(0xFF38383A),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripWorkspaceScreen(
                          tripId: trip.id,
                          tripName: trip.name,
                          destination: trip.description ?? 'Không có mô tả',
                          baseCurrency: trip.baseCurrency,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: GoogleFonts.beVietnamPro(
                                  color: kLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(99), // capsule pill
                              ),
                              child: Text(
                                '${trip.memberCount} thành viên',
                                style: GoogleFonts.beVietnamPro(
                                  color: kAzure,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: kGold, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                trip.description ?? 'Không có mô tả',
                                style: GoogleFonts.beVietnamPro(
                                  color: kLight.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mã mời: ${trip.inviteCode}',
                              style: GoogleFonts.beVietnamPro(
                                color: kAzure,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tiền tệ: ${trip.baseCurrency}',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  void _handleJoinTrip(BuildContext context) {
    final codeController = TextEditingController();
    final nickController = TextEditingController();

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
            'Tham gia chuyến đi',
            style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Mã mời (Invite Code)',
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
                controller: nickController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Biệt danh của bạn',
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
                final code = codeController.text.trim();
                final nick = nickController.text.trim();
                if (code.isNotEmpty) {
                  try {
                    await ref.read(tripsProvider.notifier).joinTrip(code, nick.isEmpty ? null : nick);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Không thể tham gia: ${e.toString().replaceAll('ApiException: ', '')}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text('Tham gia', style: GoogleFonts.beVietnamPro(color: kAzure, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleAddNewTrip(BuildContext context) {
    // Check user tier limits
    final tripsState = ref.read(tripsProvider);
    tripsState.whenData((trips) {
      if (trips.length >= 2) {
        _showProPaywall(context);
      } else {
        _showCreateTripDialog(context);
      }
    });
  }

  void _showCreateTripDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final currencyController = TextEditingController(text: 'VND');

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
                controller: descController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Mô tả chuyến đi',
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
                controller: currencyController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Loại tiền tệ gốc (VND, USD)',
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
                final desc = descController.text.trim();
                final currency = currencyController.text.trim().toUpperCase();
                if (name.isNotEmpty) {
                  try {
                    await ref.read(tripsProvider.notifier).createTrip(
                      name,
                      desc.isEmpty ? null : desc,
                      currency.isEmpty ? 'VND' : currency,
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

