import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/notification_controller.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Thông báo'),
        previousPageTitle: 'Cài đặt',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            try {
              await ref.read(notificationsProvider.notifier).readAll();
              if (context.mounted) {
                await showIosMessage(
                  context,
                  title: 'Đã cập nhật',
                  message: 'Đã đánh dấu đọc tất cả thông báo.',
                );
              }
            } catch (_) {}
          },
          child: const Icon(CupertinoIcons.check_mark_circled),
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
          notificationsState.when(
            loading: () => const SliverFillRemaining(child: IosLoading()),
            error: (err, stack) => SliverFillRemaining(
              child: IosEmptyState(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Không tải được thông báo',
                message: err.toString(),
              ),
            ),
            data: (feed) {
              final notifications = feed.notifications;
              if (notifications.isEmpty) {
                return const SliverFillRemaining(
                  child: IosEmptyState(
                    icon: CupertinoIcons.bell,
                    title: 'Không có thông báo',
                    message: 'Các cập nhật của chuyến đi sẽ xuất hiện tại đây.',
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: IosSection(
                  children: notifications.map((notification) {
                    return IosListTile(
                      icon: CupertinoIcons.bell,
                      iconColor: notification.isRead
                          ? AppTheme.iosGray
                          : AppTheme.iosBlue,
                      title: notification.title,
                      subtitle: notification.body,
                      value: notification.isRead ? null : 'Mới',
                      onTap: notification.isRead
                          ? null
                          : () => ref
                              .read(notificationsProvider.notifier)
                              .read(notification.id),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
