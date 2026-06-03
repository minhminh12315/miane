import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/notification_controller.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;

    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử thông báo',
          style: GoogleFonts.inter(color: kLight, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: kAzure),
            onPressed: () async {
              try {
                await ref.read(notificationsProvider.notifier).readAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu đọc tất cả thông báo'),
                      backgroundColor: AppTheme.iosGreen,
                    ),
                  );
                }
              } catch (_) {}
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
          child: notificationsState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: kAzure)),
            error: (err, stack) => Center(child: Text('Lỗi: $err', style: const TextStyle(color: AppTheme.iosRed))),
            data: (notifications) {
              if (notifications.isEmpty) {
                return Center(
                  child: Text(
                    'Không có thông báo nào.',
                    style: GoogleFonts.beVietnamPro(color: kLight.withOpacity(0.4)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return GestureDetector(
                    onTap: () {
                      if (!notif.isRead) {
                        ref.read(notificationsProvider.notifier).read(notif.id);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: notif.isRead ? kNavy.withOpacity(0.5) : kNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: notif.isRead ? Colors.transparent : kAzure.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (notif.isRead ? kLight : kAzure).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: notif.isRead ? kLight.withOpacity(0.5) : kAzure,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.title,
                                  style: GoogleFonts.beVietnamPro(
                                    color: kLight,
                                    fontSize: 14,
                                    fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.body,
                                  style: GoogleFonts.beVietnamPro(
                                    color: kLight.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kAzure,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
