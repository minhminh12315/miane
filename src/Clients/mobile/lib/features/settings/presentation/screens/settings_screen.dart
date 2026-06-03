// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../notification/presentation/screens/notification_history_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'Tiếng Việt';
  String _region = 'Việt Nam (VND)';
  String _bankName = 'Vietcombank';
  String _bankAccount = '1029384756';

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 24),
              // User Profile Card Mock
              Container(
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
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2C2C2E),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: kAzure,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khách du lịch',
                            style: GoogleFonts.beVietnamPro(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'traveler@example.com',
                            style: GoogleFonts.beVietnamPro(
                              color: kLight.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAzure.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99), // capsule pill
                      ),
                      child: Text(
                        'BASIC',
                        style: GoogleFonts.beVietnamPro(
                          color: kAzure,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // MIANE Pro Banner
              GestureDetector(
                onTap: () => _showProPaywall(context),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(16), // rounded: lg
                    border: Border.all(
                      color: kGold.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: kGold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nâng cấp MIANE Pro',
                              style: GoogleFonts.beVietnamPro(
                                color: kGold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mở khóa AI Plan, AI OCR & Unlimited Trips',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: kGold,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings Items
              Text(
                'Tài khoản & Bản địa hóa',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSettingItem(
                icon: Icons.language_rounded,
                title: 'Ngôn ngữ hệ thống',
                trailing: _language,
                kAzure: kAzure,
                kLight: kLight,
                onTap: () => _showLanguageDialog(context),
              ),
              _buildSettingItem(
                icon: Icons.public_rounded,
                title: 'Quốc gia / Vùng',
                trailing: _region,
                kAzure: kAzure,
                kLight: kLight,
                onTap: () => _showRegionDialog(context),
              ),
              _buildSettingItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Ví nhận tiền (VietQR/MoMo)',
                trailing: '$_bankName ($_bankAccount)',
                kAzure: kAzure,
                kLight: kLight,
                onTap: () => _showWalletDialog(context),
              ),
              
              const SizedBox(height: 16),
              Text(
                'Ứng dụng & Hỗ trợ',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSettingItem(
                icon: Icons.notifications_none_rounded,
                title: 'Thông báo đẩy',
                kAzure: kAzure,
                kLight: kLight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationHistoryScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.security_rounded,
                title: 'Bảo mật & Quyền riêng tư',
                kAzure: kAzure,
                kLight: kLight,
              ),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: 'Trợ giúp & Phản hồi',
                kAzure: kAzure,
                kLight: kLight,
              ),

              const SizedBox(height: 32),
              // Logout Button
              GestureDetector(
                onTap: () {
                  ref.read(appAuthProvider.notifier).logout();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12), // rounded: md
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Đăng xuất',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.redAccent[100],
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color kAzure,
    required Color kLight,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16), // rounded: lg
          border: Border.all(
            color: const Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: kAzure,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: GoogleFonts.beVietnamPro(
                  color: kLight.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: kLight.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    const Color kDark = AppTheme.surfaceDark;
    const Color kLight = AppTheme.iosLight;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Chọn ngôn ngữ',
            style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tiếng Việt', style: GoogleFonts.beVietnamPro(color: kLight)),
                leading: Radio<String>(
                  value: 'Tiếng Việt',
                  groupValue: _language,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() => _language = val!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('English', style: GoogleFonts.beVietnamPro(color: kLight)),
                leading: Radio<String>(
                  value: 'English',
                  groupValue: _language,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() => _language = val!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegionDialog(BuildContext context) {
    const Color kDark = AppTheme.surfaceDark;
    const Color kLight = AppTheme.iosLight;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Chọn quốc gia / vùng',
            style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Việt Nam (VND)', style: GoogleFonts.beVietnamPro(color: kLight)),
                leading: Radio<String>(
                  value: 'Việt Nam (VND)',
                  groupValue: _region,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() => _region = val!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Mỹ (USD)', style: GoogleFonts.beVietnamPro(color: kLight)),
                leading: Radio<String>(
                  value: 'Mỹ (USD)',
                  groupValue: _region,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() => _region = val!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWalletDialog(BuildContext context) {
    const Color kDark = AppTheme.surfaceDark;
    const Color kNavy = Color(0xFF2C2C2E);
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;

    final bankController = TextEditingController(text: _bankName);
    final accountController = TextEditingController(text: _bankAccount);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Cài đặt ví nhận tiền',
            style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Ngân hàng / Ví',
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
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Số tài khoản / Số điện thoại',
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
              onPressed: () {
                setState(() {
                  _bankName = bankController.text;
                  _bankAccount = accountController.text;
                });
                Navigator.pop(context);
              },
              child: Text('Lưu', style: GoogleFonts.beVietnamPro(color: kAzure, fontWeight: FontWeight.bold)),
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
                'Mở khóa không giới hạn số lượng chuyến đi, số thành viên nhóm, tự động quy đổi ngoại tệ cùng với AI bóc tách hóa đơn & AI trợ lý du lịch.',
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
}
