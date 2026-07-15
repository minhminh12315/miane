import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../../notification/presentation/controllers/push_notification_controller.dart';
import '../../../notification/presentation/screens/notification_history_screen.dart';
import '../controllers/payment_account_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'Tiếng Việt';
  String _region = 'Việt Nam (VND)';

  @override
  Widget build(BuildContext context) {
    final paymentAccount = ref.watch(paymentAccountProvider);
    final tierState = ref.watch(currentUserTierProvider);
    final userState = ref.watch(currentUserProvider);
    final pushNotificationState = ref.watch(pushNotificationSettingsProvider);
    final user = userState.valueOrNull;
    final isPro = tierState.valueOrNull != null && tierState.valueOrNull! >= 1;

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Cài đặt'),
            previousPageTitle: 'Miane',
          ),
          SliverToBoxAdapter(
            child: IosSection(
              children: [
                IosListTile(
                  icon: CupertinoIcons.person,
                  title: _displayNameFor(user, isPro),
                  subtitle: _displayEmailFor(user, userState.isLoading),
                  value: isPro ? 'VIP' : 'CƠ BẢN',
                  onTap: userState.isLoading
                      ? null
                      : () => _showProfileDialog(user),
                ),
                if (!isPro)
                  IosListTile(
                    icon: CupertinoIcons.star,
                    iconColor: AppTheme.iosGold,
                    title: 'Nâng cấp MIANE VIP',
                    subtitle:
                        'Lập lịch AI, quét hóa đơn AI và không giới hạn chuyến đi',
                    onTap: () =>
                        showIosProSheet(context, featureName: 'MIANE VIP'),
                  )
                else
                  const IosListTile(
                    icon: CupertinoIcons.check_mark_circled_solid,
                    iconColor: AppTheme.iosGreen,
                    title: 'MIANE VIP đang hoạt động',
                    subtitle: 'Không giới hạn chuyến đi và thành viên',
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Tài khoản và bản địa hóa',
              children: [
                IosListTile(
                  icon: CupertinoIcons.globe,
                  title: 'Ngôn ngữ hệ thống',
                  value: _language,
                  onTap: () => _showChoiceSheet(
                    title: 'Chọn ngôn ngữ',
                    values: const ['Tiếng Việt', 'English'],
                    current: _language,
                    onSelected: (value) => setState(() => _language = value),
                  ),
                ),
                IosListTile(
                  icon: CupertinoIcons.location,
                  title: 'Quốc gia / Vùng',
                  value: _region,
                  onTap: () => _showChoiceSheet(
                    title: 'Chọn quốc gia / vùng',
                    values: const ['Việt Nam (VND)', 'Mỹ (USD)'],
                    current: _region,
                    onSelected: (value) => setState(() => _region = value),
                  ),
                ),
                IosListTile(
                  icon: CupertinoIcons.creditcard,
                  title: 'Ví nhận tiền',
                  subtitle: paymentAccount.displaySubtitle,
                  value: paymentAccount.displayValue,
                  onTap: () => _showWalletDialog(paymentAccount),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Ứng dụng và hỗ trợ',
              children: [
                IosListTile(
                  icon: CupertinoIcons.bell,
                  title: 'Thông báo đẩy',
                  subtitle: _pushNotificationSubtitle(pushNotificationState),
                  trailing: _PushNotificationSwitch(
                    state: pushNotificationState,
                    onChanged: _togglePushNotifications,
                  ),
                  onTap: pushNotificationState.valueOrNull?.canToggle == true
                      ? () => _togglePushNotifications(
                            !(pushNotificationState.valueOrNull?.enabled ??
                                false),
                          )
                      : null,
                ),
                IosListTile(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Lịch sử thông báo',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                          builder: (_) => const NotificationHistoryScreen()),
                    );
                  },
                ),
                const IosListTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Bảo mật và quyền riêng tư',
                ),
                const IosListTile(
                  icon: CupertinoIcons.question_circle,
                  title: 'Trợ giúp và phản hồi',
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              children: [
                IosListTile(
                  icon: CupertinoIcons.square_arrow_right,
                  iconColor: AppTheme.iosRed,
                  title: 'Đăng xuất',
                  destructive: true,
                  onTap: () => ref.read(appAuthProvider.notifier).logout(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 132)),
        ],
      ),
    );
  }

  String _pushNotificationSubtitle(
    AsyncValue<PushNotificationPreference> state,
  ) {
    return state.when(
      data: (preference) => preference.subtitle,
      loading: () => 'Đang kiểm tra...',
      error: (error, _) => error.toString(),
    );
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    try {
      await ref
          .read(pushNotificationSettingsProvider.notifier)
          .setEnabled(enabled);
      if (!mounted) return;
      await showIosMessage(
        context,
        message: enabled
            ? 'Thông báo đẩy đã được bật.'
            : 'Thông báo đẩy đã được tắt.',
      );
    } catch (error) {
      if (!mounted) return;
      await showIosMessage(
        context,
        message: error.toString(),
        isError: true,
      );
    }
  }

  void _showChoiceSheet({
    required String title,
    required List<String> values,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: values.map((value) {
          return CupertinoActionSheetAction(
            isDefaultAction: value == current,
            onPressed: () {
              Navigator.of(context).pop();
              onSelected(value);
            },
            child: Text(value == current ? '$value ✓' : value),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  Future<void> _showProfileDialog(UserModel? current) async {
    final nameController = TextEditingController(
      text: current?.fullName.trim().isNotEmpty == true
          ? current!.fullName.trim()
          : _usernameFromEmail(current?.email ?? ''),
    );
    final avatarController =
        TextEditingController(text: current?.avatarUrl?.trim() ?? '');

    try {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Thông tin tài khoản'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                _ReadonlyInfoRow(
                  label: 'Email đăng nhập',
                  value: current?.email.trim().isNotEmpty == true
                      ? current!.email.trim()
                      : 'Chưa tải được email',
                ),
                const SizedBox(height: 10),
                IosTextField(
                  controller: nameController,
                  placeholder: 'Tên hiển thị',
                  prefixIcon: CupertinoIcons.person,
                ),
                const SizedBox(height: 10),
                IosTextField(
                  controller: avatarController,
                  placeholder: 'URL ảnh đại diện (không bắt buộc)',
                  prefixIcon: CupertinoIcons.photo,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final fullName = nameController.text.trim();
                if (fullName.isEmpty) {
                  await showIosMessage(
                    dialogContext,
                    message: 'Vui lòng nhập tên hiển thị.',
                    isError: true,
                  );
                  return;
                }

                try {
                  await ref.read(authRepositoryProvider).updateMe(
                        fullName: fullName,
                        avatarUrl: avatarController.text.trim().isEmpty
                            ? null
                            : avatarController.text.trim(),
                      );
                  ref.invalidate(currentUserProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    await showIosMessage(
                      context,
                      message: 'Thông tin tài khoản đã được cập nhật.',
                    );
                  }
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  await showIosMessage(
                    dialogContext,
                    message: error.toString(),
                    isError: true,
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      avatarController.dispose();
    }
  }

  Future<void> _showWalletDialog(PaymentAccountConfig current) async {
    var selectedDestination =
        current.destination ?? supportedPaymentDestinations.first;
    PaymentAccountValidationResult? validation = current.isConfigured
        ? selectedDestination.validateAccountNumber(current.accountNumber)
        : null;
    final accountController =
        TextEditingController(text: current.accountNumber);
    final holderController = TextEditingController(text: current.accountHolder);

    try {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            void runCheck() {
              setDialogState(() {
                validation = selectedDestination
                    .validateAccountNumber(accountController.text);
              });
            }

            return CupertinoAlertDialog(
              title: const Text('Ví nhận tiền'),
              content: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    _DestinationPickerButton(
                      destination: selectedDestination,
                      onPressed: () async {
                        final selected =
                            await _showDestinationSheet(selectedDestination);
                        if (selected == null || !dialogContext.mounted) return;
                        setDialogState(() {
                          selectedDestination = selected;
                          validation = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    IosTextField(
                      controller: holderController,
                      placeholder: 'Tên tài khoản',
                      prefixIcon: CupertinoIcons.person,
                    ),
                    const SizedBox(height: 10),
                    IosTextField(
                      controller: accountController,
                      placeholder: selectedDestination.accountNumberLabel,
                      prefixIcon: CupertinoIcons.number,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setDialogState(() {
                        validation = null;
                      }),
                    ),
                    if (validation != null) ...[
                      const SizedBox(height: 10),
                      _ValidationMessage(result: validation!),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                CupertinoDialogAction(
                  onPressed: runCheck,
                  child: const Text('Kiểm tra'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () async {
                    final holder = holderController.text.trim();
                    final result = selectedDestination
                        .validateAccountNumber(accountController.text);
                    if (holder.isEmpty) {
                      await showIosMessage(
                        dialogContext,
                        message: 'Vui lòng nhập tên tài khoản.',
                        isError: true,
                      );
                      return;
                    }
                    if (!result.isValid) {
                      setDialogState(() => validation = result);
                      return;
                    }

                    try {
                      await ref.read(paymentAccountProvider.notifier).save(
                            destination: selectedDestination,
                            accountNumber: result.normalizedAccountNumber,
                            accountHolder: holder,
                          );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      await showIosMessage(
                        dialogContext,
                        message: error.toString(),
                        isError: true,
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      accountController.dispose();
      holderController.dispose();
    }
  }

  Future<PaymentDestination?> _showDestinationSheet(
    PaymentDestination current,
  ) {
    return showCupertinoModalPopup<PaymentDestination>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Chọn ngân hàng / ví nhận tiền'),
        actions: supportedPaymentDestinations.map((destination) {
          final selected = destination.code == current.code;
          return CupertinoActionSheetAction(
            isDefaultAction: selected,
            onPressed: () => Navigator.of(sheetContext).pop(destination),
            child: Text(
              selected ? '${destination.name} ✓' : destination.name,
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  String _displayNameFor(UserModel? user, bool isPro) {
    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) return _usernameFromEmail(email);

    return isPro ? 'Thành viên VIP' : 'Khách du lịch';
  }

  String _displayEmailFor(UserModel? user, bool isLoading) {
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) return email;
    return isLoading ? 'Đang tải tài khoản...' : 'Chưa có email';
  }

  String _usernameFromEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split('@').first;
  }
}

class _DestinationPickerButton extends StatelessWidget {
  final PaymentDestination destination;
  final VoidCallback onPressed;

  const _DestinationPickerButton({
    required this.destination,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondaryDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.creditcard,
              color: AppTheme.iosBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destination.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd(),
              ),
            ),
            Icon(CupertinoIcons.chevron_down, color: secondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PushNotificationSwitch extends StatelessWidget {
  final AsyncValue<PushNotificationPreference> state;
  final ValueChanged<bool> onChanged;

  const _PushNotificationSwitch({
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (preference) {
        if (preference.busy) {
          return const CupertinoActivityIndicator(radius: 10);
        }

        return CupertinoSwitch(
          value: preference.enabled,
          activeTrackColor: AppTheme.iosGreen,
          onChanged: preference.canToggle ? onChanged : null,
        );
      },
      loading: () => const CupertinoActivityIndicator(radius: 10),
      error: (_, __) => const CupertinoSwitch(
        value: false,
        activeTrackColor: AppTheme.iosGreen,
        onChanged: null,
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  final PaymentAccountValidationResult result;

  const _ValidationMessage({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.isValid ? AppTheme.iosGreen : AppTheme.iosRed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          result.isValid
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.exclamationmark_triangle_fill,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            result.message,
            style: AppTheme.labelSm(color: color),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadonlyInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.labelSm(color: secondary)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySm(),
          ),
        ],
      ),
    );
  }
}
