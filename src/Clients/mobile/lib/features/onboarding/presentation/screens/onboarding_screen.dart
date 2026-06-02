import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Đồng bộ\nLịch trình',
      'subtitle': 'Lập kế hoạch chi tiết cùng bạn bè theo thời gian thực.',
      'imageText': '✈️',
    },
    {
      'title': 'Đơn giản\nChi tiêu',
      'subtitle': 'Tự động phân chia chi phí nhóm hợp lý, minh bạch.',
      'imageText': '💳',
    },
    {
      'title': 'Quét hóa đơn\nBằng AI',
      'subtitle': 'Nhận diện hóa đơn lập tức bằng công nghệ OCR thông minh.',
      'imageText': '🔍',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Custom colors from DESIGN.md
    const Color primaryColor = Color(0xFF0D2C54);
    const Color secondaryColor = Color(0xFF4A90E2);
    const Color accentGold = Color(0xFFF4BD64);
    const Color surfaceDark = Color(0xFF05101E);

    return Scaffold(
      backgroundColor: surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: TextButton(
                  onPressed: () {
                    // Navigate to next screen / home
                  },
                  child: Text(
                    'Bỏ qua',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stylized Premium Vector/Emoji Container
                        Center(
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: secondaryColor.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                item['imageText']!,
                                style: const TextStyle(fontSize: 72),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Title
                        Text(
                          item['title']!,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          item['subtitle']!,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? accentGold : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _onboardingData.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Navigate to Auth / Home
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(32), // 32px rounded
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _onboardingData.length - 1
                                ? 'Bắt đầu'
                                : 'Tiếp tục',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
