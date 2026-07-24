import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ios_ui.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'home_screen.dart';
import 'trips_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TripsScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsProvider);

    return ModernPage(
      child: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ModernBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              prominentIndex: 2,
              items: const [
                ModernBottomNavItem(
                  icon: CupertinoIcons.house_fill,
                  label: 'Trang chủ',
                ),
                ModernBottomNavItem(
                  icon: CupertinoIcons.map_fill,
                  label: 'Chuyến đi',
                ),
                ModernBottomNavItem(
                  icon: CupertinoIcons.search,
                  label: 'Tìm kiếm',
                ),
                ModernBottomNavItem(
                  icon: CupertinoIcons.person_fill,
                  label: 'Tài khoản',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
