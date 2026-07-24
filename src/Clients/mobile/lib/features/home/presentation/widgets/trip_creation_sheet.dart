import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../domain/models/trip_models.dart';
import '../../domain/services/trip_creation_validator.dart';
import '../controllers/trips_provider.dart';

class TripCreationSheet extends ConsumerStatefulWidget {
  const TripCreationSheet({super.key});

  @override
  ConsumerState<TripCreationSheet> createState() => _TripCreationSheetState();
}

class _TripCreationSheetState extends ConsumerState<TripCreationSheet> {
  static const _aiThumbnailEndpoint = String.fromEnvironment(
    'MIANE_AI_IMAGE_URL',
    defaultValue: 'http://localhost:8000/api/v1/image/generate-trip-thumbnail',
  );
  static const _aiThumbnailTimeout = Duration(seconds: 120);

  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  DateTime _endDate = DateTime.now().add(const Duration(days: 17));
  Uint8List? _coverBytes;
  _AiThumbnail? _aiThumbnail;
  _TripPlace? _selectedPlace;
  bool _isGeneratingCover = false;
  bool _isPickingCover = false;
  bool _isSubmitting = false;
  int _aiRequestGeneration = 0;
  String _coverFileName = 'trip-cover.jpg';
  String? _coverError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _durationDays => _endDate.difference(_startDate).inDays + 1;

  int get _durationNights => math.max(0, _durationDays - 1);

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
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
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    math.max(26, keyboard + 26),
                  ),
                  children: [
                    IosAnimatedEntry(
                      dy: 20,
                      child: _CreateTripHero(
                        title: _nameController.text.trim().isEmpty
                            ? 'Tên chuyến đi'
                            : _nameController.text.trim(),
                        subtitle:
                            '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                        coverBytes: _coverBytes,
                        coverUrl:
                            _coverBytes == null ? _aiThumbnail?.imageUrl : null,
                        onClose: () => Navigator.of(context).pop(),
                        onSave:
                            _isSubmitting || _isPickingCover ? null : _submit,
                        onPickCover: _showCoverSourceSheet,
                      ),
                    ),
                    ...[
                      const SizedBox(height: 20),
                      IosAnimatedEntry(
                        delay: 0.08,
                        child: _TripNameField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      IosAnimatedEntry(
                        delay: 0.14,
                        child: _DestinationCard(
                          place: _selectedPlace,
                          onTap: _openPlaceSearch,
                        ),
                      ),
                      const SizedBox(height: 14),
                      IosAnimatedEntry(
                        delay: 0.20,
                        child: _DateRangeCard(
                          startDate: _startDate,
                          endDate: _endDate,
                          durationDays: _durationDays,
                          durationNights: _durationNights,
                          onTap: _openDateRangePicker,
                        ),
                      ),
                      if (_isGeneratingCover ||
                          _isPickingCover ||
                          _coverBytes != null ||
                          _coverError != null) ...[
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _coverStateWidget(context),
                        ),
                      ],
                      const SizedBox(height: 20),
                      IosPrimaryButton(
                        label: _isSubmitting ? 'Đang tạo...' : 'Tạo chuyến đi',
                        isLoading: _isSubmitting,
                        onPressed:
                            _isSubmitting || _isPickingCover ? null : _submit,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverStateWidget(BuildContext context) {
    if (_isPickingCover) {
      return const _CoverInfoPanel(
        key: ValueKey('cover-picking'),
        icon: CupertinoIcons.photo_on_rectangle,
        iconColor: AppTheme.iosBlue,
        title: 'Đang tối ưu ảnh',
        message: 'MIANE đang thu nhỏ ảnh để tải lên nhanh hơn.',
      );
    }

    if (_isGeneratingCover) {
      return const _CoverInfoPanel(
        key: ValueKey('cover-generating'),
        icon: CupertinoIcons.sparkles,
        iconColor: AppTheme.iosGold,
        title: 'Đang tạo ảnh AI trong nền',
        message: 'Bạn vẫn có thể tiếp tục nhập thông tin chuyến đi.',
      );
    }

    if (_coverError != null) {
      return _CoverErrorPanel(
        key: const ValueKey('cover-error'),
        onRetry: _selectedPlace == null
            ? null
            : () => _generateAiCoverForPlace(_selectedPlace!),
      );
    }

    if (_coverBytes != null) {
      return _CoverInfoPanel(
        key: const ValueKey('cover-manual'),
        icon: CupertinoIcons.photo_fill_on_rectangle_fill,
        iconColor: AppTheme.iosBlue,
        title: 'Đang dùng ảnh bạn đã chọn',
        message: 'Ảnh thủ công luôn được ưu tiên hơn ảnh AI.',
        actionLabel: 'Xóa ảnh',
        onAction: _clearUserCover,
      );
    }

    return const SizedBox.shrink(key: ValueKey('cover-empty'));
  }

  Future<void> _openPlaceSearch() async {
    final place = await showGlassBottomSheet<_TripPlace>(
      context: context,
      heightFactor: 0.92,
      builder: (_) => _PlaceSearchSheet(
        initialPlace: _selectedPlace,
      ),
    );

    if (place == null || !mounted) return;
    await _selectPlace(place);
  }

  Future<void> _selectPlace(_TripPlace place) async {
    setState(() {
      _selectedPlace = place;
      _aiThumbnail = null;
      _coverError = null;
    });

    if (_coverBytes == null) {
      unawaited(_generateAiCoverForPlace(place));
    }
  }

  Future<void> _generateAiCoverForPlace(_TripPlace place) async {
    final generation = ++_aiRequestGeneration;
    setState(() {
      _isGeneratingCover = true;
      _coverError = null;
    });

    final thumbnail = await _requestAiThumbnail(place);
    if (!mounted || generation != _aiRequestGeneration) return;

    setState(() {
      _aiThumbnail = thumbnail;
      _isGeneratingCover = false;
      _coverError = thumbnail == null ? 'Không thể tạo ảnh.' : null;
    });
  }

  Future<_AiThumbnail?> _requestAiThumbnail(_TripPlace place) async {
    try {
      final response = await http
          .post(
            Uri.parse(_aiThumbnailEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'placeId': place.placeId,
              'placeName': place.name,
              'formattedAddress': place.formattedAddress,
              'latitude': place.latitude,
              'longitude': place.longitude,
              'city': place.city,
              'province': place.province,
              'country': place.country,
            }),
          )
          .timeout(_aiThumbnailTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      return _AiThumbnail.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDateRangePicker() async {
    final range = await showGlassBottomSheet<_DateRange>(
      context: context,
      heightFactor: 0.72,
      builder: (_) => _DateRangePickerSheet(
        initialStart: _startDate,
        initialEnd: _endDate,
      ),
    );

    if (range == null || !mounted) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  Future<void> _showCoverSourceSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Ảnh nền chuyến đi'),
        message: const Text('Chọn ảnh thủ công hoặc để MIANE dùng ảnh AI.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickCover(ImageSource.gallery);
            },
            child: const Text('Thư viện'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickCover(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          if (_coverBytes != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _clearUserCover();
              },
              child: const Text('Xóa ảnh thủ công'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  Future<void> _pickCover(ImageSource source) async {
    setState(() {
      _isPickingCover = true;
      _coverError = null;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 78,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _aiRequestGeneration++;
        _isGeneratingCover = false;
        _coverBytes = bytes;
        _coverFileName =
            image.name.trim().isEmpty ? 'trip-cover.jpg' : image.name;
        _coverError = null;
      });
    } catch (e) {
      if (!mounted) return;
      await showIosMessage(
        context,
        message: 'Không thể chọn ảnh: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingCover = false);
      }
    }
  }

  Future<void> _clearUserCover() async {
    setState(() => _coverBytes = null);
    final place = _selectedPlace;
    if (place != null && _aiThumbnail == null) {
      unawaited(_generateAiCoverForPlace(place));
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final place = _selectedPlace;
    final validation = TripCreationValidator.validate(
      name: name,
      destination: place?.name,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (!validation.isValid) {
      await showIosMessage(
        context,
        message: validation.errorMessage!,
        isError: true,
      );
      return;
    }

    if (validation.needsConfirmation) {
      final confirmed = await _confirmUnusualDates(validation);
      if (!confirmed || !mounted) return;
    }

    if (_isGeneratingCover && _coverBytes == null) {
      final confirmed = await showIosConfirm(
        context,
        title: 'Ảnh bìa chưa hoàn tất',
        message:
            'Ảnh AI vẫn đang được tạo. Nếu tiếp tục ngay, chuyến đi sẽ được tạo mà chưa có ảnh bìa.',
        confirmLabel: 'Tạo ngay',
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(tripsProvider.notifier).createTripDraft(
            TripCreationDraft(
              name: name,
              place: place!.toTripPlaceData(),
              startDate: _startDate,
              endDate: _endDate,
              baseCurrency: 'VND',
              coverImageUrl:
                  _coverBytes == null ? _aiThumbnail?.imageUrl : null,
              coverImagePrompt:
                  _coverBytes == null ? _aiThumbnail?.prompt : null,
              coverImageLandmark:
                  _coverBytes == null ? _aiThumbnail?.landmark : null,
            ),
          );

      if (_coverBytes != null) {
        final bytes = _coverBytes!;
        ref
            .read(tripCoverMemoryProvider.notifier)
            .setCover(result.tripId, bytes);
        unawaited(
          ref.read(tripCoverUploadProvider.notifier).upload(
                tripId: result.tripId,
                bytes: bytes,
                fileName: _coverFileName,
              ),
        );
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể tạo chuyến đi: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmUnusualDates(
    TripCreationValidation validation,
  ) async {
    final messages = <String>[];
    if (validation.warnings.contains(TripCreationWarning.alreadyEnded)) {
      messages.add(
        'Toàn bộ thời gian của chuyến đi đã nằm trong quá khứ.',
      );
    } else if (validation.warnings
        .contains(TripCreationWarning.alreadyStarted)) {
      messages.add('Ngày bắt đầu của chuyến đi đã qua.');
    }
    if (validation.warnings.contains(TripCreationWarning.unusuallyLong)) {
      messages.add(
        'Chuyến đi kéo dài ${validation.durationDays} ngày, dài hơn mức thông thường.',
      );
    }

    return showIosConfirm(
      context,
      title: 'Xác nhận thời gian',
      message: '${messages.join('\n\n')}\n\nBạn vẫn muốn tạo chuyến đi này?',
      confirmLabel: 'Vẫn tạo',
    );
  }
}

class _CreateTripHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final String? coverUrl;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final VoidCallback onPickCover;

  const _CreateTripHero({
    required this.title,
    required this.subtitle,
    required this.coverBytes,
    required this.coverUrl,
    required this.onClose,
    required this.onSave,
    required this.onPickCover,
  });

  bool get _hasCover => coverBytes != null || (coverUrl ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: 224,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 1.035, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _heroBackground(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.black.withValues(alpha: 0.10),
                    CupertinoColors.black.withValues(alpha: 0.12),
                    CupertinoColors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: [
                  _HeroCapsuleButton(
                    label: 'Hủy',
                    onTap: onClose,
                  ),
                  const Spacer(),
                  _HeroCapsuleButton(
                    label: 'Lưu',
                    emphasized: true,
                    onTap: onSave,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 27,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(
                      color: CupertinoColors.white.withValues(alpha: 0.78),
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _HeroCoverButton(onTap: onPickCover),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBackground() {
    if (coverBytes != null) {
      return Image.memory(
        coverBytes!,
        key: const ValueKey('manual-cover'),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if ((coverUrl ?? '').isNotEmpty) {
      return Image.network(
        coverUrl!,
        key: ValueKey(coverUrl),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
      );
    }

    return _CoverPlaceholder(
      key: ValueKey(_hasCover),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF273442),
            Color(0xFF22251F),
            Color(0xFF111111),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _DestinationPlaceholderPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DestinationPlaceholderPainter extends CustomPainter {
  const _DestinationPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = CupertinoColors.white.withValues(alpha: 0.12);

    for (var i = 0; i < 5; i++) {
      final path = Path()..moveTo(-20, size.height * (0.28 + i * 0.12));
      for (var x = -20.0; x <= size.width + 20; x += 28) {
        path.lineTo(
          x,
          size.height * (0.28 + i * 0.12) + math.sin(x / 34 + i) * 10,
        );
      }
      canvas.drawPath(path, paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.iosGold.withValues(alpha: 0.38),
          CupertinoColors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.24),
          radius: size.width * 0.46,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.24),
      size.width * 0.46,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroCapsuleButton extends StatelessWidget {
  final String label;
  final bool emphasized;
  final VoidCallback? onTap;

  const _HeroCapsuleButton({
    required this.label,
    this.emphasized = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: emphasized
                ? CupertinoColors.white.withValues(alpha: 0.92)
                : CupertinoColors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: AppTheme.labelSm(
              color: emphasized ? AppTheme.iosOrange : CupertinoColors.white,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _HeroCoverButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroCoverButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: AppTheme.radiusPill,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.photo,
              color: CupertinoColors.white,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              'Nền',
              style: AppTheme.labelSm(color: CupertinoColors.white).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripNameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _TripNameField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.iosOrange,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Tên chuyến đi',
                style: AppTheme.labelSm(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          CupertinoTextField.borderless(
            controller: controller,
            placeholder: 'Ví dụ: Du lịch Đà Lạt cùng gia đình',
            minLines: 1,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            clearButtonMode: OverlayVisibilityMode.editing,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                TripCreationValidator.maxNameLength,
              ),
            ],
            onChanged: onChanged,
            padding: EdgeInsets.zero,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            placeholderStyle: TextStyle(
              color: CupertinoColors.secondaryLabel
                  .resolveFrom(context)
                  .withValues(alpha: 0.74),
              fontSize: 18,
              height: 1.18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final _TripPlace? place;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: place == null
            ? const _EmptyDestinationContent(key: ValueKey('empty-place'))
            : _SelectedDestinationContent(
                key: ValueKey(place!.placeId ?? place!.name),
                place: place!,
              ),
      ),
    );
  }
}

class _EmptyDestinationContent extends StatelessWidget {
  const _EmptyDestinationContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const _IconBubble(
            icon: CupertinoIcons.location_solid,
            color: AppTheme.iosOrange,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn địa điểm', style: AppTheme.titleSm()),
                const SizedBox(height: 5),
                Text(
                  'Chọn từ gợi ý có sẵn hoặc nhập địa điểm thủ công.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SelectedDestinationContent extends StatelessWidget {
  final _TripPlace place;

  const _SelectedDestinationContent({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _MiniMapPreview(place: place),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: AppTheme.iosOrange,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.titleSm(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  place.shortAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if ((place.city ?? '').isNotEmpty)
                      _TinyChip(label: place.city!),
                    if ((place.country ?? '').isNotEmpty)
                      _TinyChip(label: place.country!),
                    if (place.latitude != null && place.longitude != null)
                      const _TinyChip(label: 'Đã có tọa độ'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  final _TripPlace place;

  const _MiniMapPreview({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 86,
        height: 86,
        child: CustomPaint(painter: _MiniMapPainter(place.name)),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final String seed;

  const _MiniMapPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final code = seed.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final baseHue = (code % 70) + 170;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSVColor.fromAHSV(1, baseHue.toDouble(), 0.32, 0.44).toColor(),
            const Color(0xFF1B241E),
          ],
        ).createShader(rect),
    );

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = CupertinoColors.white.withValues(alpha: 0.30);
    final orangePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.iosOrange.withValues(alpha: 0.84);

    for (var i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(-8, size.height * (0.24 + i * 0.18))
        ..cubicTo(
          size.width * 0.24,
          size.height * (0.08 + i * 0.12),
          size.width * 0.70,
          size.height * (0.38 + i * 0.10),
          size.width + 8,
          size.height * (0.22 + i * 0.19),
        );
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, orangePaint);
    }

    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.48),
      10,
      Paint()..color = AppTheme.iosOrange,
    );
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.48),
      4,
      Paint()..color = CupertinoColors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _DateRangeCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int durationNights;
  final VoidCallback onTap;

  const _DateRangeCard({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.durationNights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            const _IconBubble(
              icon: CupertinoIcons.calendar,
              color: AppTheme.iosBlue,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  key: ValueKey('${startDate.toIso8601String()}$endDate'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thời gian', style: AppTheme.titleSm()),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _formatFullDate(startDate),
                          style: AppTheme.bodyMd(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            CupertinoIcons.arrow_right,
                            color: AppTheme.iosBlue.withValues(alpha: 0.9),
                            size: 14,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatFullDate(endDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyMd(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$durationDays ngày • $durationNights đêm',
                      style: AppTheme.bodySm(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverInfoPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CoverInfoPanel({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleSm()),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(width: 10),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(32, 32),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTheme.labelSm(color: AppTheme.iosBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverErrorPanel extends StatelessWidget {
  final VoidCallback? onRetry;

  const _CoverErrorPanel({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: AppTheme.iosRed,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Không thể tạo ảnh.', style: AppTheme.titleSm()),
                const SizedBox(height: 4),
                Text(
                  'Bạn vẫn có thể tạo chuyến đi bình thường.',
                  style: AppTheme.bodySm(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(34, 34),
              onPressed: onRetry,
              child: Text(
                'Thử lại',
                style: AppTheme.labelSm(color: AppTheme.iosBlue),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  final _TripPlace? initialPlace;

  const _PlaceSearchSheet({
    this.initialPlace,
  });

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  List<_TripPlacePreview> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlace;
    if (initial != null) {
      _controller.text = initial.name;
    }
    _suggestions = _fallbackSuggestions(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheetScaffold(
      title: 'Chọn địa điểm',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        children: [
          ModernGlass(
            radius: 26,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: CupertinoTextField.borderless(
              controller: _controller,
              autofocus: true,
              placeholder: 'Đà Lạt, Tokyo Tower, Eiffel Tower...',
              prefix: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.search,
                  color: AppTheme.iosBlue,
                  size: 19,
                ),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
            ),
          ),
          const SizedBox(height: 12),
          for (final suggestion in _suggestions)
            _PlaceResultTile(
              suggestion: suggestion,
              onTap: () => _selectSuggestion(suggestion),
            ),
          if (_controller.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _ManualDestinationButton(
              query: _controller.text.trim(),
              onTap: () => Navigator.of(context).pop(
                _TripPlace.manual(_controller.text.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onQueryChanged(String value) {
    setState(() {
      _suggestions = _fallbackSuggestions(value.trim());
    });
  }

  void _selectSuggestion(_TripPlacePreview suggestion) {
    final fallback = suggestion.fallbackPlace;
    Navigator.of(context).pop(fallback ?? _TripPlace.manual(suggestion.title));
  }

  List<_TripPlacePreview> _fallbackSuggestions(String query) {
    final normalized = _normalize(query);
    final places = _popularPlaces
        .where((place) =>
            normalized.isEmpty ||
            _normalize(place.searchText).contains(normalized))
        .take(8)
        .map(_TripPlacePreview.fromPlace)
        .toList();

    return places.isEmpty ? [_TripPlacePreview.manual(query)] : places;
  }
}

class _PlaceResultTile extends StatelessWidget {
  final _TripPlacePreview suggestion;
  final VoidCallback onTap;

  const _PlaceResultTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: ModernGlass(
          radius: 24,
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              _IconBubble(
                icon: suggestion.isManual
                    ? CupertinoIcons.pencil
                    : CupertinoIcons.location_solid,
                color:
                    suggestion.isManual ? AppTheme.iosBlue : AppTheme.iosOrange,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleSm(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualDestinationButton extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const _ManualDestinationButton({
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.pencil,
                color: AppTheme.iosBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dùng "$query"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangePickerSheet extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;

  const _DateRangePickerSheet({
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late DateTime _visibleMonth;
  late DateTime _draftStart;
  late DateTime _draftEnd;
  bool _selectingEnd = false;

  int get _days => _draftEnd.difference(_draftStart).inDays + 1;

  int get _nights => math.max(0, _days - 1);

  @override
  void initState() {
    super.initState();
    _draftStart = _dateOnly(widget.initialStart);
    _draftEnd = _dateOnly(widget.initialEnd);
    _visibleMonth = DateTime(_draftStart.year, _draftStart.month);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.resolveFrom(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(42, 42),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Hủy',
                    style: AppTheme.titleSm(color: AppTheme.iosOrange)),
              ),
              Expanded(
                child: Text(
                  '${_formatShortDate(_draftStart)} → ${_formatShortDate(_draftEnd)}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineMd(),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(42, 42),
                onPressed: () {
                  Navigator.of(context).pop(
                    _DateRange(start: _draftStart, end: _draftEnd),
                  );
                },
                child: Text(
                  'Xác nhận',
                  style: AppTheme.titleSm(color: AppTheme.iosOrange),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: CupertinoColors.separator
              .resolveFrom(context)
              .withValues(alpha: 0.16),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(38, 38),
                    onPressed: () => setState(() {
                      _visibleMonth =
                          DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                    }),
                    child: const Icon(CupertinoIcons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      'tháng ${_visibleMonth.month} năm ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(38, 38),
                    onPressed: () => setState(() {
                      _visibleMonth =
                          DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                    }),
                    child: const Icon(CupertinoIcons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  _WeekdayLabel('TH 2'),
                  _WeekdayLabel('TH 3'),
                  _WeekdayLabel('TH 4'),
                  _WeekdayLabel('TH 5'),
                  _WeekdayLabel('TH 6'),
                  _WeekdayLabel('TH 7'),
                  _WeekdayLabel('CN'),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 54,
                ),
                itemCount: _calendarCellCount,
                itemBuilder: (context, index) {
                  final day = _dayForCell(index);
                  if (day == null) return const SizedBox.shrink();
                  return _CalendarDayCell(
                    day: day,
                    selectedStart: _isSameDay(day, _draftStart),
                    selectedEnd: _isSameDay(day, _draftEnd),
                    inRange: _isInRange(day),
                    connectsLeft: _connectsLeft(day),
                    connectsRight: _connectsRight(day),
                    onTap: () => _selectDay(day),
                  );
                },
              ),
              const SizedBox(height: 18),
              ModernGlass(
                radius: 24,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.moon_stars_fill,
                      color: AppTheme.iosGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectingEnd
                            ? 'Chọn ngày kết thúc'
                            : 'Chọn ngày bắt đầu',
                        style: AppTheme.bodyMd(),
                      ),
                    ),
                    Text(
                      '$_days ngày • $_nights đêm',
                      style: AppTheme.titleSm(color: AppTheme.iosGold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int get _leadingEmptyCells {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    return (first.weekday - DateTime.monday) % 7;
  }

  int get _daysInVisibleMonth =>
      DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

  int get _calendarCellCount {
    final total = _leadingEmptyCells + _daysInVisibleMonth;
    return (total / 7).ceil() * 7;
  }

  DateTime? _dayForCell(int index) {
    final dayNumber = index - _leadingEmptyCells + 1;
    if (dayNumber < 1 || dayNumber > _daysInVisibleMonth) return null;
    return DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
  }

  void _selectDay(DateTime day) {
    final selected = _dateOnly(day);
    setState(() {
      if (!_selectingEnd || selected.isBefore(_draftStart)) {
        _draftStart = selected;
        _draftEnd = selected;
        _selectingEnd = true;
      } else {
        _draftEnd = selected;
        _selectingEnd = false;
      }
    });
  }

  bool _isInRange(DateTime day) =>
      !day.isBefore(_draftStart) && !day.isAfter(_draftEnd);

  bool _connectsLeft(DateTime day) {
    if (!_isInRange(day) || day.weekday == DateTime.monday) return false;
    return _isInRange(day.subtract(const Duration(days: 1)));
  }

  bool _connectsRight(DateTime day) {
    if (!_isInRange(day) || day.weekday == DateTime.sunday) return false;
    return _isInRange(day.add(const Duration(days: 1)));
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.labelSm(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool selectedStart;
  final bool selectedEnd;
  final bool inRange;
  final bool connectsLeft;
  final bool connectsRight;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.selectedStart,
    required this.selectedEnd,
    required this.inRange,
    required this.connectsLeft,
    required this.connectsRight,
    required this.onTap,
  });

  bool get _isEndpoint => selectedStart || selectedEnd;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(42, 42),
      onPressed: onTap,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (inRange)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 38,
                margin: EdgeInsets.only(
                  left: connectsLeft ? 0 : 27,
                  right: connectsRight ? 0 : 27,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.iosOrange.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(connectsLeft ? 0 : 19),
                    right: Radius.circular(connectsRight ? 0 : 19),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _isEndpoint ? 48 : 42,
              height: _isEndpoint ? 48 : 42,
              decoration: BoxDecoration(
                color: _isEndpoint
                    ? AppTheme.iosOrange
                    : CupertinoColors.transparent,
                shape: BoxShape.circle,
                boxShadow: _isEndpoint
                    ? [
                        BoxShadow(
                          color: AppTheme.iosOrange.withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: _isEndpoint
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                    fontSize: 17,
                    fontWeight: inRange ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBubble({
    required this.icon,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: size * 0.45),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String label;

  const _TinyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.labelXs(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

class _AiThumbnail {
  final String imageUrl;
  final String prompt;
  final String landmark;
  final bool cached;

  const _AiThumbnail({
    required this.imageUrl,
    required this.prompt,
    required this.landmark,
    required this.cached,
  });

  factory _AiThumbnail.fromJson(Map<String, dynamic> json) {
    return _AiThumbnail(
      imageUrl: (json['imageUrl'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      landmark: (json['landmark'] ?? '').toString(),
      cached: json['cached'] == true,
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}

class _TripPlacePreview {
  final String? placeId;
  final String title;
  final String subtitle;
  final _TripPlace? fallbackPlace;
  final bool isManual;

  const _TripPlacePreview({
    required this.placeId,
    required this.title,
    required this.subtitle,
    this.fallbackPlace,
    this.isManual = false,
  });

  factory _TripPlacePreview.fromPlace(_TripPlace place) {
    return _TripPlacePreview(
      placeId: place.placeId,
      title: place.name,
      subtitle: place.shortAddress,
      fallbackPlace: place,
    );
  }

  factory _TripPlacePreview.manual(String query) {
    final value = query.trim().isEmpty ? 'Địa điểm mới' : query.trim();
    return _TripPlacePreview(
      placeId: null,
      title: value,
      subtitle: 'Sử dụng địa điểm bạn đã nhập',
      fallbackPlace: _TripPlace.manual(value),
      isManual: true,
    );
  }
}

class _TripPlace {
  final String? placeId;
  final String name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? country;
  final String? city;
  final String? province;
  final List<String> types;

  const _TripPlace({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.country,
    this.city,
    this.province,
    this.types = const [],
  });

  factory _TripPlace.manual(String value) {
    return _TripPlace(
      placeId: null,
      name: value.trim(),
      formattedAddress: value.trim(),
      city: value.trim(),
    );
  }

  String get shortAddress {
    final pieces = [
      if ((province ?? '').isNotEmpty && province != city) province,
      if ((country ?? '').isNotEmpty) country,
    ].whereType<String>().toList();
    if (pieces.isNotEmpty) return pieces.join(', ');
    return formattedAddress ?? 'Đã chọn địa điểm';
  }

  String get searchText =>
      '$name ${formattedAddress ?? ''} ${city ?? ''} ${country ?? ''}';

  TripPlaceData toTripPlaceData() {
    return TripPlaceData(
      placeId: placeId,
      name: name,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
      country: country,
      city: city,
      province: province,
      types: types,
    );
  }
}

final _popularPlaces = <_TripPlace>[
  const _TripPlace(
    placeId: 'fallback-da-lat',
    name: 'Đà Lạt',
    formattedAddress: 'Đà Lạt, Lâm Đồng, Việt Nam',
    city: 'Đà Lạt',
    province: 'Lâm Đồng',
    country: 'Việt Nam',
    latitude: 11.9404,
    longitude: 108.4583,
    types: ['locality', 'tourist_destination'],
  ),
  const _TripPlace(
    placeId: 'fallback-da-nang',
    name: 'Đà Nẵng',
    formattedAddress: 'Đà Nẵng, Việt Nam',
    city: 'Đà Nẵng',
    country: 'Việt Nam',
    latitude: 16.0471,
    longitude: 108.2068,
    types: ['locality', 'tourist_destination'],
  ),
  const _TripPlace(
    placeId: 'fallback-ba-na-hills',
    name: 'Sun World Bà Nà Hills',
    formattedAddress: 'Hòa Vang, Đà Nẵng, Việt Nam',
    city: 'Đà Nẵng',
    country: 'Việt Nam',
    latitude: 15.9970,
    longitude: 107.9881,
    types: ['tourist_attraction'],
  ),
  const _TripPlace(
    placeId: 'fallback-phu-quoc',
    name: 'Bãi Sao Phú Quốc',
    formattedAddress: 'Phú Quốc, Kiên Giang, Việt Nam',
    city: 'Phú Quốc',
    province: 'Kiên Giang',
    country: 'Việt Nam',
    latitude: 10.0552,
    longitude: 104.0357,
    types: ['natural_feature', 'tourist_attraction'],
  ),
  const _TripPlace(
    placeId: 'fallback-tokyo-tower',
    name: 'Tokyo Tower',
    formattedAddress: 'Minato City, Tokyo, Nhật Bản',
    city: 'Tokyo',
    country: 'Nhật Bản',
    latitude: 35.6586,
    longitude: 139.7454,
    types: ['tourist_attraction', 'landmark'],
  ),
  const _TripPlace(
    placeId: 'fallback-eiffel',
    name: 'Eiffel Tower',
    formattedAddress: 'Paris, Pháp',
    city: 'Paris',
    country: 'Pháp',
    latitude: 48.8584,
    longitude: 2.2945,
    types: ['tourist_attraction', 'landmark'],
  ),
  const _TripPlace(
    placeId: 'fallback-ninh-binh',
    name: 'Ninh Bình',
    formattedAddress: 'Ninh Bình, Việt Nam',
    city: 'Ninh Bình',
    country: 'Việt Nam',
    latitude: 20.2506,
    longitude: 105.9745,
    types: ['administrative_area_level_1', 'tourist_destination'],
  ),
  const _TripPlace(
    placeId: 'fallback-bangkok',
    name: 'Bangkok',
    formattedAddress: 'Bangkok, Thái Lan',
    city: 'Bangkok',
    country: 'Thái Lan',
    latitude: 13.7563,
    longitude: 100.5018,
    types: ['locality'],
  ),
];

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} thg ${date.month}, ${date.year}';

String _formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} thg ${date.month}';

String _formatFullDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _normalize(String value) {
  var text = value.toLowerCase().trim();
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };
  replacements.forEach((from, to) {
    text = text.replaceAll(from, to);
  });
  return text.replaceAll(RegExp(r'\s+'), ' ');
}
