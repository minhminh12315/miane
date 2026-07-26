import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/payments/qr_download_helper.dart';
import '../../../../core/payments/viet_qr_payment.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../notification/presentation/screens/notification_history_screen.dart';
import '../controllers/payment_account_provider.dart';

enum _AvatarEditAction { gallery, camera, remove }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _avatarPicker = ImagePicker();

  String _language = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    final paymentAccount = ref.watch(paymentAccountProvider);
    final destinationState = ref.watch(paymentDestinationsProvider);
    final tierState = ref.watch(currentUserTierProvider);
    final userState = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(notificationUnreadCountProvider);
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
                _AccountProfileTile(
                  imageUrl: _resolveAvatarUrl(user?.avatarUrl),
                  title: _displayNameFor(user, isPro),
                  subtitle: _displayEmailFor(user, userState.isLoading),
                  tierLabel: isPro ? 'VIP' : 'CƠ BẢN',
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
                  icon: CupertinoIcons.creditcard,
                  title: 'Ví nhận tiền',
                  subtitle: destinationState.isLoading
                      ? 'Đang cập nhật danh sách ngân hàng...'
                      : paymentAccount.displaySubtitle,
                  value: paymentAccount.displayValue,
                  onTap: () => _showWalletDialog(paymentAccount),
                ),
                if (paymentAccount.isConfigured && paymentAccount.isBank)
                  IosListTile(
                    icon: CupertinoIcons.qrcode,
                    title: 'Mã VietQR nhận tiền',
                    subtitle: 'Tạo QR theo số tiền và nội dung chuyển khoản',
                    onTap: () => _showVietQrDialog(paymentAccount),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Ứng dụng và hỗ trợ',
              children: [
                IosListTile(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Thông báo',
                  subtitle: 'Tự động cập nhật từ hệ thống',
                  value: unreadCount > 0 ? '$unreadCount mới' : null,
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

  Future<void> _showProfileDialog(UserModel? current) async {
    final nameController = TextEditingController(
      text: current?.fullName.trim().isNotEmpty == true
          ? current!.fullName.trim()
          : _usernameFromEmail(current?.email ?? ''),
    );
    String? draftAvatarUrl = current?.avatarUrl?.trim();
    Uint8List? draftAvatarBytes;
    String? draftAvatarFileName;
    var isSaving = false;

    try {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> chooseAvatar() async {
              final action = await _showAvatarEditSheet(
                dialogContext,
                canRemove: draftAvatarBytes != null ||
                    (draftAvatarUrl?.isNotEmpty ?? false),
              );
              if (action == null || !dialogContext.mounted) return;

              if (action == _AvatarEditAction.remove) {
                setDialogState(() {
                  draftAvatarBytes = null;
                  draftAvatarFileName = null;
                  draftAvatarUrl = null;
                });
                return;
              }

              final source = action == _AvatarEditAction.camera
                  ? ImageSource.camera
                  : ImageSource.gallery;
              try {
                final image = await _avatarPicker.pickImage(
                  source: source,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 88,
                );
                if (image == null) return;

                final bytes = await image.readAsBytes();
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  draftAvatarBytes = bytes;
                  draftAvatarFileName = image.name.isEmpty
                      ? _fallbackAvatarFileName()
                      : image.name;
                });
              } catch (error) {
                if (!dialogContext.mounted) return;
                await showIosMessage(
                  dialogContext,
                  message: 'Không thể chọn ảnh đại diện: $error',
                  isError: true,
                );
              }
            }

            Future<void> saveProfile() async {
              final fullName = nameController.text.trim();
              if (fullName.isEmpty) {
                await showIosMessage(
                  dialogContext,
                  message: 'Vui lòng nhập tên hiển thị.',
                  isError: true,
                );
                return;
              }

              setDialogState(() => isSaving = true);
              var keepSavingState = true;
              try {
                var avatarUrl = draftAvatarUrl?.trim();
                final avatarBytes = draftAvatarBytes;
                if (avatarBytes != null) {
                  final updatedUser =
                      await ref.read(authRepositoryProvider).uploadAvatar(
                            fileBytes: avatarBytes,
                            fileName: draftAvatarFileName ??
                                _fallbackAvatarFileName(),
                          );
                  avatarUrl = updatedUser.avatarUrl?.trim();
                }

                await ref.read(authRepositoryProvider).updateMe(
                      fullName: fullName,
                      avatarUrl: avatarUrl == null || avatarUrl.isEmpty
                          ? null
                          : avatarUrl,
                    );
                ref.invalidate(currentUserProvider);
                if (!dialogContext.mounted) return;
                keepSavingState = false;
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
              } finally {
                if (keepSavingState && dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return CupertinoAlertDialog(
              title: const Text('Thông tin tài khoản'),
              content: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    _ProfileAvatarEditor(
                      imageBytes: draftAvatarBytes,
                      imageUrl: draftAvatarBytes == null
                          ? _resolveAvatarUrl(draftAvatarUrl)
                          : null,
                      onPressed: isSaving ? null : chooseAvatar,
                    ),
                    const SizedBox(height: 14),
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
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed:
                      isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: isSaving ? null : saveProfile,
                  child: isSaving
                      ? const CupertinoActivityIndicator(radius: 9)
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameController.dispose();
    }
  }

  Future<_AvatarEditAction?> _showAvatarEditSheet(
    BuildContext sheetContext, {
    required bool canRemove,
  }) {
    return showCupertinoModalPopup<_AvatarEditAction>(
      context: sheetContext,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Ảnh đại diện'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context).pop(_AvatarEditAction.gallery),
            child: const Text('Chọn từ thư viện'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context).pop(_AvatarEditAction.camera),
            child: const Text('Chụp ảnh mới'),
          ),
          if (canRemove)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.of(context).pop(_AvatarEditAction.remove),
              child: const Text('Xóa ảnh đại diện'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  Future<void> _showWalletDialog(PaymentAccountConfig current) async {
    final loadedDestinations =
        ref.read(paymentDestinationsProvider).valueOrNull;
    List<PaymentDestination> destinations;
    if (loadedDestinations == null) {
      try {
        destinations = await ref.read(paymentDestinationsProvider.future);
      } catch (_) {
        destinations = supportedPaymentDestinations
            .where((d) => !d.isWallet)
            .toList();
      }
      if (!mounted) return;
    } else {
      destinations = loadedDestinations;
    }
    destinations = destinations.isEmpty
        ? supportedPaymentDestinations.where((d) => !d.isWallet).toList()
        : destinations.where((d) => !d.isWallet).toList();
    var selectedDestination =
        current.resolveDestination(destinations) ?? destinations.first;
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
                        final selected = await _showDestinationSheet(
                          selectedDestination,
                          destinations,
                        );
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

  Future<void> _showVietQrDialog(PaymentAccountConfig current) async {
    final amountController = TextEditingController();
    final infoController = TextEditingController(text: 'MIANE');
    VietQrPaymentQr? qr;
    var isGenerating = false;

    try {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> generate() async {
              final amount = int.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                await showIosMessage(
                  dialogContext,
                  message: 'Vui lòng nhập số tiền VND hợp lệ.',
                  isError: true,
                );
                return;
              }

              setDialogState(() => isGenerating = true);
              var keepGeneratingState = true;
              try {
                final result =
                    await ref.read(paymentAccountProvider.notifier).generateQr(
                          amount: amount,
                          addInfo: infoController.text,
                        );
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  qr = result;
                  isGenerating = false;
                });
                keepGeneratingState = false;
              } catch (error) {
                if (!dialogContext.mounted) return;
                await showIosMessage(
                  dialogContext,
                  message: error.toString(),
                  isError: true,
                );
              } finally {
                if (keepGeneratingState && dialogContext.mounted) {
                  setDialogState(() => isGenerating = false);
                }
              }
            }

            final qrImageBytes = _decodeQrDataUrl(qr?.qrDataUrl);

            return CupertinoAlertDialog(
              title: const Text('Mã VietQR nhận tiền'),
              content: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    if (qr == null) ...[
                      _ReadonlyInfoRow(
                        label: 'Tài khoản nhận',
                        value:
                            '${current.destinationName} - ${current.accountNumber}',
                      ),
                      const SizedBox(height: 10),
                      IosTextField(
                        controller: amountController,
                        placeholder: 'Số tiền VND',
                        prefixIcon: CupertinoIcons.money_dollar,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 10),
                      IosTextField(
                        controller: infoController,
                        placeholder: 'Nội dung chuyển khoản',
                        prefixIcon: CupertinoIcons.text_alignleft,
                      ),
                    ] else ...[
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: qrImageBytes != null
                            ? Image.memory(qrImageBytes, fit: BoxFit.contain)
                            : QrImageView(
                                data: qr!.qrCode,
                                backgroundColor: CupertinoColors.white,
                              ),
                      ),
                      const SizedBox(height: 12),
                      _ReadonlyInfoRow(
                        label: 'Thông tin chuyển khoản',
                        value:
                            '${qr!.bankName} - ${qr!.accountNumber}\n${qr!.accountName}\n${qr!.amount} VND - ${qr!.addInfo}',
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: isGenerating
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(qr == null ? 'Hủy' : 'Đóng'),
                ),
                if (qr != null)
                  CupertinoDialogAction(
                    onPressed: isGenerating
                        ? null
                        : () => _downloadVietQr(
                              dialogContext,
                              qr!,
                              qrImageBytes,
                            ),
                    child: const Text('Tải QR'),
                  ),
                if (qr != null)
                  CupertinoDialogAction(
                    onPressed: isGenerating
                        ? null
                        : () {
                            setDialogState(() {
                              qr = null;
                              amountController.clear();
                              infoController.text = 'MIANE';
                            });
                          },
                    child: const Text('Tạo mã khác'),
                  )
                else
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: isGenerating ? null : generate,
                    child: isGenerating
                        ? const CupertinoActivityIndicator(radius: 9)
                        : const Text('Tạo QR'),
                  ),
              ],
            );
          },
        ),
      );
    } finally {
      amountController.dispose();
      infoController.dispose();
    }
  }

  Future<void> _downloadVietQr(
    BuildContext context,
    VietQrPaymentQr qr,
    Uint8List? qrImageBytes,
  ) async {
    try {
      final bytes = qrImageBytes ??
          await resolveQrPngBytes(
            dataUrl: qr.qrDataUrl,
            fallbackData: qr.qrCode,
          );
      final saved = await saveQrPngFile(
        bytes: bytes,
        fileName: 'miane-vietqr-${qr.accountNumber}-${qr.amount}',
      );
      if (!context.mounted) return;
      await showIosMessage(
        context,
        message: saved ? 'Đã tải mã QR.' : 'Đã hủy tải mã QR.',
      );
    } catch (error) {
      if (!context.mounted) return;
      await showIosMessage(
        context,
        message: 'Không thể tải mã QR: $error',
        isError: true,
      );
    }
  }

  Future<PaymentDestination?> _showDestinationSheet(
    PaymentDestination current,
    List<PaymentDestination> destinations,
  ) {
    return showCupertinoModalPopup<PaymentDestination>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Chọn ngân hàng / ví nhận tiền'),
        actions: destinations.map((destination) {
          final selected = destination.code == current.code ||
              (destination.bin.isNotEmpty && destination.bin == current.bin);
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

  String? _resolveAvatarUrl(String? avatarUrl) {
    final value = avatarUrl?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '${ApiEndpoints.baseUrl}$value';
    }
    return value;
  }

  String _fallbackAvatarFileName() {
    return 'avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  Uint8List? _decodeQrDataUrl(String? dataUrl) {
    final value = dataUrl?.trim() ?? '';
    if (value.isEmpty) return null;
    final commaIndex = value.indexOf(',');
    final base64Value =
        commaIndex >= 0 ? value.substring(commaIndex + 1) : value;
    try {
      return base64Decode(base64Value);
    } catch (_) {
      return null;
    }
  }

  String _usernameFromEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split('@').first;
  }
}

class _AccountProfileTile extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String tierLabel;
  final VoidCallback? onTap;

  const _AccountProfileTile({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.tierLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.transparent,
        child: Row(
          children: [
            _AvatarCircle(imageUrl: imageUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMd(color: label).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tierLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTheme.bodySm(color: secondary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: secondary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarEditor extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback? onPressed;

  const _ProfileAvatarEditor({
    required this.imageBytes,
    required this.imageUrl,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _AvatarCircle(
                imageBytes: imageBytes,
                imageUrl: imageUrl,
                size: 72,
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.iosBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceDark,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: AppTheme.iosLight,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Đổi ảnh đại diện',
            style: AppTheme.bodySm(color: secondary),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final double size;

  const _AvatarCircle({
    this.imageBytes,
    this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF123D6D),
        shape: BoxShape.circle,
      ),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    final resolvedUrl = imageUrl?.trim() ?? '';
    if (resolvedUrl.isNotEmpty) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        CupertinoIcons.person,
        color: AppTheme.iosBlue,
        size: size * 0.46,
      ),
    );
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
