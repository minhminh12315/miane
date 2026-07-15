import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
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
    final tierState = ref.watch(currentUserTierProvider);
    final isPro = tierState.valueOrNull == 1;

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
                  title: 'Khách du lịch',
                  subtitle: 'traveler@example.com',
                  value: isPro ? 'PRO' : 'BASIC',
                ),
                if (isPro)
                  const IosListTile(
                    icon: CupertinoIcons.star_fill,
                    iconColor: AppTheme.iosGold,
                    title: 'MIANE Pro',
                    subtitle: 'Chuyến đi và thành viên không giới hạn',
                    value: 'Đã kích hoạt',
                  )
                else
                  IosListTile(
                    icon: CupertinoIcons.star,
                    iconColor: AppTheme.iosGold,
                    title: 'Nâng cấp MIANE Pro',
                    subtitle: 'Chuyến đi và thành viên không giới hạn',
                    onTap: () =>
                        showIosProSheet(context, featureName: 'MIANE Pro'),
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
                  value: '$_bankName ($_bankAccount)',
                  onTap: _showWalletDialog,
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

  void _showWalletDialog() {
    final bankController = TextEditingController(text: _bankName);
    final accountController = TextEditingController(text: _bankAccount);

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Ví nhận tiền'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              IosTextField(
                controller: bankController,
                placeholder: 'Ngân hàng / Ví',
                prefixIcon: CupertinoIcons.creditcard,
              ),
              const SizedBox(height: 10),
              IosTextField(
                controller: accountController,
                placeholder: 'Số tài khoản / Số điện thoại',
                prefixIcon: CupertinoIcons.number,
                keyboardType: TextInputType.number,
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
            onPressed: () {
              setState(() {
                _bankName = bankController.text.trim();
                _bankAccount = accountController.text.trim();
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
