import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  String _selectedCurrency = 'VND';
  final _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thiết lập ban đầu',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vùng quốc gia được chọn sẽ tự động thiết lập đơn vị tiền tệ mặc định cho chuyến đi và định dạng số hiển thị.',
                style: GoogleFonts.beVietnamPro(
                  color: kAzure.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              // Currency Selection Header
              Text(
                'Tiền tệ mặc định',
                style: GoogleFonts.beVietnamPro(
                  color: kLight.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Currency Selection Row
              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyCard(
                      label: 'VND (đ)',
                      isSelected: _selectedCurrency == 'VND',
                      onTap: () => setState(() => _selectedCurrency = 'VND'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCurrencyCard(
                      label: 'USD (\$)',
                      isSelected: _selectedCurrency == 'USD',
                      onTap: () => setState(() => _selectedCurrency = 'USD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // Initial Balance Header
              Text(
                'Số dư ban đầu',
                style: GoogleFonts.beVietnamPro(
                  color: kLight.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Initial Balance input field
              Container(
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius: BorderRadius.circular(12), // rounded: md
                  border: Border.all(
                    color: kAzure.withOpacity(0.25),
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.beVietnamPro(
                    color: kLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.beVietnamPro(
                      color: kLight.withOpacity(0.3),
                    ),
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        _selectedCurrency == 'VND' ? 'đ' : '\$',
                        style: GoogleFonts.beVietnamPro(
                          color: kGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 56),
              // Complete Button
              GestureDetector(
                onTap: () {
                  ref.read(appAuthProvider.notifier).completeSetup();
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kAzure,
                    borderRadius: BorderRadius.circular(12), // rounded: md
                    boxShadow: [
                      BoxShadow(
                        color: kAzure.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Hoàn thành',
                      style: GoogleFonts.beVietnamPro(
                        color: kLight,
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

  Widget _buildCurrencyCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? kNavy : kNavy.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12), // rounded: md
          border: Border.all(
            color: isSelected ? kGold : kAzure.withOpacity(0.15),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              color: isSelected ? kGold : kLight.withOpacity(0.7),
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
