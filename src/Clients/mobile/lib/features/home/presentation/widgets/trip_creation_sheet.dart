import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../domain/models/trip_models.dart';
import '../controllers/trips_provider.dart';

class TripCreationSheet extends ConsumerStatefulWidget {
  const TripCreationSheet({super.key});

  @override
  ConsumerState<TripCreationSheet> createState() => _TripCreationSheetState();
}

class _TripCreationSheetState extends ConsumerState<TripCreationSheet> {
  static const _aiImageEndpoint = String.fromEnvironment(
    'MIANE_AI_IMAGE_URL',
    defaultValue: 'http://localhost:8000/api/generate-trip-image',
  );

  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  DateTime _endDate = DateTime.now().add(const Duration(days: 20));
  Uint8List? _coverBytes;
  String? _aiCoverUrl;
  String? _coverStatus;
  _PlaceSuggestion? _selectedPlace;
  bool _showPlaceSuggestions = false;
  bool _isGeneratingCover = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _durationDays => _endDate.difference(_startDate).inDays + 1;

  List<_PlaceSuggestion> get _filteredPlaces {
    final input = _destinationController.text.trim();
    if (input.length < 2) return [];

    final query = _normalize(input);
    final matches = _popularPlaces
        .where((place) => _normalize(place.searchText).contains(query))
        .take(5)
        .toList();

    final hasExact =
        matches.any((place) => _normalize(place.displayName) == query);
    if (!hasExact) {
      matches.add(
        _PlaceSuggestion.manual(input),
      );
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final destinationText = _destinationController.text.trim();

    return GlassBottomSheetScaffold(
      title: 'Tạo chuyến đi',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          _CreateTripHero(
            name: _nameController.text.trim().isEmpty
                ? 'Chuyến đi mới'
                : _nameController.text.trim(),
            destination:
                destinationText.isEmpty ? 'Chọn điểm đến' : destinationText,
            dateLabel: '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
            durationLabel: '$_durationDays ngày',
            coverBytes: _coverBytes,
            coverUrl: _aiCoverUrl,
            isGeneratingCover: _isGeneratingCover,
          ),
          const SizedBox(height: 18),
          _SheetSection(
            title: 'Thông tin chuyến đi',
            children: [
              IosTextField(
                controller: _nameController,
                label: 'Tên chuyến đi *',
                placeholder: 'Mùa hè tại Đà Nẵng',
                prefixIcon: CupertinoIcons.map_fill,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              IosTextField(
                controller: _destinationController,
                label: 'Địa điểm *',
                placeholder: 'Nhập thành phố hoặc quốc gia',
                prefixIcon: CupertinoIcons.location_solid,
                onChanged: (value) {
                  setState(() {
                    _selectedPlace = null;
                    _aiCoverUrl = null;
                    _coverStatus = null;
                    _showPlaceSuggestions = value.trim().length >= 2;
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showPlaceSuggestions && _filteredPlaces.isNotEmpty
                    ? Padding(
                        key: const ValueKey('place-suggestions'),
                        padding: const EdgeInsets.only(top: 10),
                        child: _PlaceSuggestionPanel(
                          places: _filteredPlaces,
                          onSelected: _selectPlace,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty-suggestions')),
              ),
              if (_selectedPlace != null) ...[
                const SizedBox(height: 10),
                _SelectedPlacePill(place: _selectedPlace!),
              ],
              const SizedBox(height: 12),
              IosTextField(
                controller: _noteController,
                label: 'Ghi chú',
                placeholder: 'Biển, đồ ăn, nghỉ dưỡng...',
                prefixIcon: CupertinoIcons.text_bubble,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SheetSection(
            title: 'Thời gian',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      title: 'Ngày đi',
                      value: _formatDate(_startDate),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      title: 'Ngày về',
                      value: _formatDate(_endDate),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ModernGlass(
                radius: 20,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock,
                      color: AppTheme.iosGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text('Thời lượng', style: AppTheme.bodySm()),
                    const Spacer(),
                    Text(
                      '$_durationDays ngày',
                      style: AppTheme.titleSm(color: AppTheme.iosGold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SheetSection(
            title: 'Ảnh bìa',
            subtitle: _coverSubtitle,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CoverAction(
                      icon: CupertinoIcons.photo_on_rectangle,
                      label: 'Thư viện',
                      onTap: () => _pickCover(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CoverAction(
                      icon: CupertinoIcons.camera,
                      label: 'Chụp ảnh',
                      onTap: () => _pickCover(ImageSource.camera),
                    ),
                  ),
                ],
              ),
              if (_coverStatus != null || _coverBytes != null) ...[
                const SizedBox(height: 12),
                _CoverStatusRow(
                  isGenerating: _isGeneratingCover,
                  hasUserCover: _coverBytes != null,
                  text: _coverStatus ??
                      (_coverBytes != null
                          ? 'Đang dùng ảnh bạn đã chọn'
                          : 'Ảnh bìa đã sẵn sàng'),
                  onClear: _coverBytes == null ? null : _clearUserCover,
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          IosPrimaryButton(
            label: _isSubmitting ? 'Đang tạo...' : 'Tạo chuyến đi',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn địa điểm để MIANE tự tạo ảnh bìa bằng AI. Nếu bạn tải ảnh lên hoặc chụp ảnh, MIANE sẽ ưu tiên dùng ảnh của bạn.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySm(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ).copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  String get _coverSubtitle {
    if (_coverBytes != null) {
      return 'Ảnh bạn chọn sẽ được dùng làm ảnh bìa chuyến đi.';
    }
    if (_isGeneratingCover) {
      return 'MIANE đang tạo ảnh AI theo địa điểm đã chọn.';
    }
    if ((_aiCoverUrl ?? '').isNotEmpty) {
      return 'Ảnh AI đã sẵn sàng. Bạn vẫn có thể thay bằng ảnh của mình.';
    }
    return 'Chọn một địa điểm để tạo ảnh AI, hoặc tự tải/chụp ảnh.';
  }

  Future<void> _selectPlace(_PlaceSuggestion place) async {
    _destinationController.text = place.displayName;
    _destinationController.selection = TextSelection.collapsed(
      offset: _destinationController.text.length,
    );
    setState(() {
      _selectedPlace = place;
      _showPlaceSuggestions = false;
      _coverStatus = _coverBytes == null
          ? 'Đang tạo ảnh AI cho ${place.displayName}...'
          : 'Đang dùng ảnh bạn đã chọn';
    });

    if (_coverBytes == null) {
      await _generateAiCoverForPlace(place);
    }
  }

  Future<void> _generateAiCoverForPlace(_PlaceSuggestion place) async {
    setState(() {
      _isGeneratingCover = true;
      _coverStatus = 'Đang tạo ảnh AI cho ${place.displayName}...';
    });

    final imageUrl = await _generateAiCoverUrl(place.displayName);
    if (!mounted) return;

    setState(() {
      _aiCoverUrl = imageUrl;
      _isGeneratingCover = false;
      _coverStatus = imageUrl == null
          ? 'Chưa tạo được ảnh AI. Bạn vẫn có thể tạo chuyến đi hoặc tải ảnh lên.'
          : 'Ảnh AI đã sẵn sàng';
    });
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 86,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _coverBytes = bytes;
        _coverStatus = 'Đang dùng ảnh bạn đã chọn';
      });
    } catch (e) {
      if (!mounted) return;
      await showIosMessage(
        context,
        message: 'Không thể chọn ảnh: $e',
        isError: true,
      );
    }
  }

  Future<void> _clearUserCover() async {
    setState(() {
      _coverBytes = null;
      _coverStatus = null;
    });
    final place = _selectedPlace;
    if (place != null && (_aiCoverUrl ?? '').isEmpty) {
      await _generateAiCoverForPlace(place);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    var selected = isStart ? _startDate : _endDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 330,
          color: AppTheme.surfaceDark,
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selected,
                  minimumYear: DateTime.now().year - 1,
                  maximumYear: DateTime.now().year + 5,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
              CupertinoButton(
                child: const Text('Xong'),
                onPressed: () {
                  setState(() {
                    if (isStart) {
                      _startDate = selected;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 1));
                      }
                    } else {
                      _endDate =
                          selected.isBefore(_startDate) ? _startDate : selected;
                    }
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final destination = _destinationController.text.trim();

    if (name.isEmpty || destination.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập tên chuyến đi và điểm đến.',
        isError: true,
      );
      return;
    }

    final place = _selectedPlace ?? _PlaceSuggestion.manual(destination);

    setState(() => _isSubmitting = true);
    try {
      final coverImageUrl = _coverBytes == null
          ? (_aiCoverUrl ?? await _generateAiCoverUrl(place.displayName))
          : null;

      final result = await ref.read(tripsProvider.notifier).createTripDraft(
            TripCreationDraft(
              name: name,
              destinationText: place.displayName,
              description: _noteController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              baseCurrency: 'VND',
              coverImageUrl: coverImageUrl,
              latitude: place.latitude,
              longitude: place.longitude,
            ),
          );

      if (_coverBytes != null) {
        ref
            .read(tripCoverMemoryProvider.notifier)
            .setCover(result.tripId, _coverBytes!);
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

  Future<String?> _generateAiCoverUrl(String destination) async {
    try {
      final response = await http
          .post(
            Uri.parse(_aiImageEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'destination': destination}),
          )
          .timeout(const Duration(seconds: 18));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final imageUrl = body['imageUrl']?.toString();
      return (imageUrl ?? '').isEmpty ? null : imageUrl;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) => '${date.day} thg ${date.month}';
}

class _PlaceSuggestion {
  final String city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool isManual;

  const _PlaceSuggestion({
    required this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.isManual = false,
  });

  factory _PlaceSuggestion.manual(String value) {
    return _PlaceSuggestion(city: value, isManual: true);
  }

  String get displayName => (country ?? '').isEmpty ? city : '$city, $country';

  String get searchText => '$city ${country ?? ''}';
}

const _popularPlaces = [
  _PlaceSuggestion(
    city: 'Đà Nẵng',
    country: 'Việt Nam',
    latitude: 16.0471,
    longitude: 108.2068,
  ),
  _PlaceSuggestion(
    city: 'Hà Nội',
    country: 'Việt Nam',
    latitude: 21.0278,
    longitude: 105.8342,
  ),
  _PlaceSuggestion(
    city: 'TP. Hồ Chí Minh',
    country: 'Việt Nam',
    latitude: 10.8231,
    longitude: 106.6297,
  ),
  _PlaceSuggestion(
    city: 'Đà Lạt',
    country: 'Việt Nam',
    latitude: 11.9404,
    longitude: 108.4583,
  ),
  _PlaceSuggestion(
    city: 'Nha Trang',
    country: 'Việt Nam',
    latitude: 12.2388,
    longitude: 109.1967,
  ),
  _PlaceSuggestion(
    city: 'Phú Quốc',
    country: 'Việt Nam',
    latitude: 10.2899,
    longitude: 103.9840,
  ),
  _PlaceSuggestion(
    city: 'Hội An',
    country: 'Việt Nam',
    latitude: 15.8801,
    longitude: 108.3380,
  ),
  _PlaceSuggestion(
    city: 'Huế',
    country: 'Việt Nam',
    latitude: 16.4637,
    longitude: 107.5909,
  ),
  _PlaceSuggestion(
    city: 'Bangkok',
    country: 'Thái Lan',
    latitude: 13.7563,
    longitude: 100.5018,
  ),
  _PlaceSuggestion(
    city: 'Singapore',
    country: 'Singapore',
    latitude: 1.3521,
    longitude: 103.8198,
  ),
  _PlaceSuggestion(
    city: 'Tokyo',
    country: 'Nhật Bản',
    latitude: 35.6762,
    longitude: 139.6503,
  ),
  _PlaceSuggestion(
    city: 'Seoul',
    country: 'Hàn Quốc',
    latitude: 37.5665,
    longitude: 126.9780,
  ),
  _PlaceSuggestion(
    city: 'Paris',
    country: 'Pháp',
    latitude: 48.8566,
    longitude: 2.3522,
  ),
  _PlaceSuggestion(
    city: 'Bali',
    country: 'Indonesia',
    latitude: -8.3405,
    longitude: 115.0920,
  ),
  _PlaceSuggestion(
    city: 'New York',
    country: 'Hoa Kỳ',
    latitude: 40.7128,
    longitude: -74.0060,
  ),
];

class _CreateTripHero extends StatelessWidget {
  final String name;
  final String destination;
  final String dateLabel;
  final String durationLabel;
  final Uint8List? coverBytes;
  final String? coverUrl;
  final bool isGeneratingCover;

  const _CreateTripHero({
    required this.name,
    required this.destination,
    required this.dateLabel,
    required this.durationLabel,
    required this.coverBytes,
    required this.coverUrl,
    required this.isGeneratingCover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverBytes != null)
              Image.memory(coverBytes!, fit: BoxFit.cover)
            else if ((coverUrl ?? '').isNotEmpty)
              Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CustomPaint(
                    painter: _GeneratedTravelCoverPainter(destination)),
              )
            else
              CustomPaint(painter: _GeneratedTravelCoverPainter(destination)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.black.withValues(alpha: 0.12),
                    CupertinoColors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            if (isGeneratingCover)
              Positioned(
                top: 14,
                right: 14,
                child: ModernGlass(
                  radius: AppTheme.radiusPill,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(radius: 7),
                      const SizedBox(width: 7),
                      Text(
                        'Đang tạo ảnh',
                        style: AppTheme.labelSm(color: CupertinoColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelSm(
                      color: CupertinoColors.white.withValues(alpha: 0.76),
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroPill(
                        icon: CupertinoIcons.calendar,
                        label: dateLabel,
                      ),
                      const SizedBox(width: 8),
                      _HeroPill(
                        icon: CupertinoIcons.clock,
                        label: durationLabel,
                      ),
                    ],
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: AppTheme.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CupertinoColors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.labelSm(color: CupertinoColors.white),
          ),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SheetSection({
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 28,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleSm()),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTheme.bodySm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PlaceSuggestionPanel extends StatelessWidget {
  final List<_PlaceSuggestion> places;
  final ValueChanged<_PlaceSuggestion> onSelected;

  const _PlaceSuggestionPanel({
    required this.places,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < places.length; i++) ...[
            _PlaceSuggestionTile(
              place: places[i],
              onTap: () => onSelected(places[i]),
            ),
            if (i != places.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 52),
                color: CupertinoColors.separator
                    .resolveFrom(context)
                    .withValues(alpha: 0.22),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  final _PlaceSuggestion place;
  final VoidCallback onTap;

  const _PlaceSuggestionTile({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.iosBlue.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                place.isManual
                    ? CupertinoIcons.pencil
                    : CupertinoIcons.location_solid,
                color: AppTheme.iosBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelSm(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.isManual
                        ? 'Sử dụng địa điểm bạn đã nhập'
                        : 'Chọn để tạo ảnh AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelXs(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPlacePill extends StatelessWidget {
  final _PlaceSuggestion place;

  const _SelectedPlacePill({required this.place});

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: AppTheme.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: AppTheme.iosGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đã chọn ${place.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelSm(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.calendar,
              color: AppTheme.iosBlue,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelXs(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: AppTheme.titleSm()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CoverAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ModernGlass(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.iosBlue, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titleSm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverStatusRow extends StatelessWidget {
  final bool isGenerating;
  final bool hasUserCover;
  final String text;
  final VoidCallback? onClear;

  const _CoverStatusRow({
    required this.isGenerating,
    required this.hasUserCover,
    required this.text,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          if (isGenerating)
            const CupertinoActivityIndicator(radius: 8)
          else
            Icon(
              hasUserCover
                  ? CupertinoIcons.photo_fill_on_rectangle_fill
                  : CupertinoIcons.sparkles,
              color: hasUserCover ? AppTheme.iosBlue : AppTheme.iosGold,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySm(),
            ),
          ),
          if (onClear != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(30, 30),
              onPressed: onClear,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: AppTheme.iosGray,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneratedTravelCoverPainter extends CustomPainter {
  final String destination;

  const _GeneratedTravelCoverPainter(this.destination);

  @override
  void paint(Canvas canvas, Size size) {
    final seed = destination.codeUnits.fold<int>(0, (a, b) => a + b);
    final t = seed % 360;

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSVColor.fromAHSV(1, t.toDouble(), 0.58, 0.80).toColor(),
            const Color(0xFF12304B),
            const Color(0xFF080808),
          ],
        ).createShader(rect),
    );

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.iosGold.withValues(alpha: 0.72),
          AppTheme.iosOrange.withValues(alpha: 0.12),
          CupertinoColors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.26),
          radius: size.width * 0.32,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.26),
      size.width * 0.32,
      sunPaint,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = CupertinoColors.white.withValues(alpha: 0.18);

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.56 + i * 0.08);
      final path = Path()..moveTo(-20, y);
      for (var x = -20.0; x <= size.width + 20; x += 24) {
        path.lineTo(x, y + math.sin((x / 32) + i) * 8);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeneratedTravelCoverPainter oldDelegate) =>
      oldDelegate.destination != destination;
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
