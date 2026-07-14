import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../settings/presentation/controllers/payment_account_provider.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';
import '../widgets/trip_creation_sheet.dart';
import '../widgets/trip_share_sheet.dart';
import 'join_trip_scan_screen.dart';
import 'trip_workspace_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(tripsProvider);
    final paymentAccount = ref.watch(paymentAccountProvider);
    final tierState = ref.watch(currentUserTierProvider);
    final isVip = (tierState.valueOrNull ?? 0) >= 1;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: ModernPage(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => ref.read(tripsProvider.notifier).refresh(),
              ),
              if (!isVip)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _VipPromoCard(
                      onUpgrade: () => showIosProSheet(
                        context,
                        featureName: 'quyền lợi MIANE VIP',
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, isVip ? 18 : 14, 20, 0),
                  child: _PaymentAccountCard(
                    account: paymentAccount,
                    onConfigure: () => _showPaymentAccountEditor(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _TravelHeroCard(
                    onCreate: () => _handleAddNewTrip(context, ref),
                    onJoin: () => _handleJoinTrip(context, ref),
                  ),
                ),
              ),
              if (tripsState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: IosLoading(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 126)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddNewTrip(BuildContext context, WidgetRef ref) async {
    if (!await _ensurePaymentAccountConfigured(context, ref)) return;
    if (!context.mounted) return;

    final trips = ref.read(tripsProvider).valueOrNull ?? const <TripModel>[];
    final activeTripCount =
        trips.where((trip) => !trip.isCompletedByDate).length;
    final userTier = await ref.read(currentUserTierProvider.future);
    if (!context.mounted) return;
    if (userTier <= 0 && activeTripCount >= 2) {
      showIosProSheet(context, featureName: 'tạo thêm chuyến đi');
      return;
    }

    final result = await showGlassBottomSheet<TripCreationResult>(
      context: context,
      heightFactor: 0.90,
      builder: (_) => const TripCreationSheet(),
    );
    if (result != null && context.mounted) {
      await showTripShareSheet(context, result);
      if (!context.mounted) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => TripWorkspaceScreen(
            tripId: result.tripId,
            tripName: 'Chuyến đi mới',
            destination: 'Đang tải thông tin...',
            baseCurrency: 'VND',
          ),
        ),
      );
    }
  }

  Future<void> _handleJoinTrip(BuildContext context, WidgetRef ref) async {
    if (!await _ensurePaymentAccountConfigured(context, ref)) return;
    if (!context.mounted) return;

    final codeController = TextEditingController();
    final nickController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Tham gia chuyến đi'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              IosTextField(
                controller: codeController,
                placeholder: 'Mã mời',
                prefixIcon: CupertinoIcons.number,
              ),
              const SizedBox(height: 10),
              IosTextField(
                controller: nickController,
                placeholder: 'Biệt danh của bạn',
                prefixIcon: CupertinoIcons.person,
              ),
              const SizedBox(height: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 6),
                onPressed: () async {
                  final scanned = await Navigator.of(context).push<String>(
                    CupertinoPageRoute(
                      builder: (_) => const JoinTripScanScreen(),
                    ),
                  );
                  if (scanned != null && scanned.isNotEmpty) {
                    codeController.text = scanned;
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.qrcode_viewfinder, size: 20),
                    SizedBox(width: 6),
                    Text('Quét mã QR'),
                  ],
                ),
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
              final code = codeController.text.trim();
              final nick = nickController.text.trim();
              if (code.isEmpty) return;

              try {
                await ref.read(tripsProvider.notifier).joinTrip(
                      code,
                      nick.isEmpty ? null : nick,
                    );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) {
                  await showIosMessage(
                    context,
                    message:
                        'Không thể tham gia: ${e.toString().replaceAll('ApiException: ', '')}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensurePaymentAccountConfigured(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final account = ref.read(paymentAccountProvider);
    if (account.isConfigured) return true;

    await _showPaymentSetupRequired(context);
    return false;
  }

  Future<void> _showPaymentSetupRequired(BuildContext context) {
    return showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.52,
      builder: (sheetContext) => _PaymentRequiredSheet(
        onConfigure: () {
          Navigator.of(sheetContext).pop();
          Future.microtask(() {
            if (context.mounted) _showPaymentAccountEditor(context);
          });
        },
      ),
    );
  }

  Future<void> _showPaymentAccountEditor(BuildContext context) {
    return showGlassBottomSheet<void>(
      context: context,
      heightFactor: 0.64,
      builder: (_) => const _PaymentAccountEditorSheet(),
    );
  }
}

class _VipPromoCard extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _VipPromoCard({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF31261A),
          Color(0xFF182A2C),
          Color(0xFF101010),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.iosGold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.iosGold.withValues(alpha: 0.26),
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  color: AppTheme.iosGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mở khóa MIANE VIP', style: AppTheme.titleSm()),
                    const SizedBox(height: 5),
                    Text(
                      'Không giới hạn chuyến đi, thành viên, quét hóa đơn AI và trợ lý lịch trình.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 46),
            onPressed: onUpgrade,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.iosGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: AppTheme.iosGold.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: AppTheme.iosGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Xem gói VIP',
                    style: AppTheme.labelSm(color: AppTheme.iosGold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentAccountCard extends StatelessWidget {
  final PaymentAccountConfig account;
  final VoidCallback onConfigure;

  const _PaymentAccountCard({
    required this.account,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigured = account.isConfigured;
    final color = isConfigured ? AppTheme.iosGreen : AppTheme.iosOrange;

    return ModernCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.all(18),
      onTap: onConfigure,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.17),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.26)),
            ),
            child: Icon(
              isConfigured
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.creditcard,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tài khoản nhận tiền', style: AppTheme.titleSm()),
                const SizedBox(height: 5),
                Text(
                  isConfigured
                      ? account.displayValue
                      : 'Cấu hình trước khi tạo hoặc tham gia chuyến đi.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isConfigured ? 'Đổi' : 'Cấu hình',
            style: AppTheme.labelSm(color: color),
          ),
        ],
      ),
    );
  }
}

class _TravelHeroCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _TravelHeroCard({
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A3325),
          Color(0xFF24221F),
          Color(0xFF111111),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trợ lý du lịch MIANE',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tạo chuyến đi, chia tiền và giữ mọi thứ gọn trong một ứng dụng.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMd(
              color: CupertinoColors.white.withValues(alpha: 0.72),
            ).copyWith(height: 1.35),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                  child: _HeroActionButton(
                icon: CupertinoIcons.add,
                label: 'Tạo mới',
                color: AppTheme.iosLight,
                onTap: onCreate,
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: _HeroActionButton(
                icon: CupertinoIcons.person_add,
                label: 'Tham gia',
                color: AppTheme.iosGold,
                onTap: onJoin,
              )),
            ],
          ),
          const SizedBox(height: 24),
          const ModernGlass(
            radius: 24,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _RoutePoint(
                    label: 'Bắt đầu',
                    value: 'MIANE',
                    alignEnd: false,
                  ),
                ),
                Icon(CupertinoIcons.airplane,
                    color: AppTheme.iosBlue, size: 28),
                Expanded(
                  child: _RoutePoint(
                    label: 'Sẵn sàng',
                    value: 'ĐI',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 78),
      onPressed: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.labelSm(color: CupertinoColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRequiredSheet extends StatelessWidget {
  final VoidCallback onConfigure;

  const _PaymentRequiredSheet({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey
                    .resolveFrom(context)
                    .withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppTheme.iosOrange.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.iosOrange.withValues(alpha: 0.26),
                ),
              ),
              child: const Icon(
                CupertinoIcons.creditcard_fill,
                color: AppTheme.iosOrange,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Cần cấu hình tài khoản nhận tiền',
              textAlign: TextAlign.center,
              style: AppTheme.headlineMd(),
            ),
            const SizedBox(height: 8),
            Text(
              'MIANE cần thông tin này để tạo quỹ chuyến đi, nhận góp tiền và chia tiền minh bạch giữa các thành viên.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ).copyWith(height: 1.35),
            ),
            const SizedBox(height: 22),
            IosPrimaryButton(
              label: 'Cấu hình ngay',
              onPressed: onConfigure,
            ),
            const SizedBox(height: 10),
            IosSecondaryButton(
              label: 'Để sau',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentAccountEditorSheet extends ConsumerStatefulWidget {
  const _PaymentAccountEditorSheet();

  @override
  ConsumerState<_PaymentAccountEditorSheet> createState() =>
      _PaymentAccountEditorSheetState();
}

class _PaymentAccountEditorSheetState
    extends ConsumerState<_PaymentAccountEditorSheet> {
  late final TextEditingController _bankController;
  late final TextEditingController _holderController;
  late final TextEditingController _accountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = ref.read(paymentAccountProvider);
    _bankController = TextEditingController(text: account.bankName);
    _holderController = TextEditingController(text: account.accountHolder);
    _accountController = TextEditingController(text: account.accountNumber);
  }

  @override
  void dispose() {
    _bankController.dispose();
    _holderController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheetScaffold(
      title: 'Tài khoản nhận tiền',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          IosTextField(
            controller: _bankController,
            label: 'Ngân hàng / ví',
            placeholder: 'Ví dụ: Vietcombank, Momo',
            prefixIcon: CupertinoIcons.creditcard,
          ),
          const SizedBox(height: 14),
          IosTextField(
            controller: _holderController,
            label: 'Tên chủ tài khoản',
            placeholder: 'Tên người nhận tiền',
            prefixIcon: CupertinoIcons.person,
          ),
          const SizedBox(height: 14),
          IosTextField(
            controller: _accountController,
            label: 'Số tài khoản / số điện thoại',
            placeholder: 'Nhập số tài khoản',
            prefixIcon: CupertinoIcons.number,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 22),
          IosPrimaryButton(
            label: _isSaving ? 'Đang lưu...' : 'Lưu cấu hình',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final bankName = _bankController.text.trim();
    final accountNumber = _accountController.text.trim();
    if (bankName.isEmpty || accountNumber.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập ngân hàng/ví và số tài khoản.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(paymentAccountProvider.notifier).save(
          bankName: bankName,
          accountNumber: accountNumber,
          accountHolder: _holderController.text,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _RoutePoint({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSm(
            color: CupertinoColors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
