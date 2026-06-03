import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/controllers/trips_provider.dart';
import '../../../home/presentation/screens/trip_workspace_screen.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySuggestion(String text) {
    _searchController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);
    final filteredTrips = trips.where((trip) {
      if (_query.isEmpty) return true;
      return trip.tripName.toLowerCase().contains(_query) ||
             trip.destination.toLowerCase().contains(_query);
    }).toList();

    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;
    const Color kGray = AppTheme.iosGray;

    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0), // space for floating bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tìm kiếm',
                style: AppTheme.displayLg(color: kLight),
              ),
              const SizedBox(height: 16),

              // Glassmorphic Search Input
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kNavy.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: AppTheme.thinBorder,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMd(color: kLight),
                      decoration: InputDecoration(
                        hintText: 'Tìm chuyến đi, điểm đến...',
                        hintStyle: AppTheme.bodyMd(color: kLight.withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search_rounded, color: kAzure, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: kGray, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Suggestions
              if (_query.isEmpty) ...[
                Text(
                  'Gợi ý phổ biến',
                  style: AppTheme.titleSm(color: kLight),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSuggestionChip('Đà Lạt', kNavy, kLight, kAzure),
                    _buildSuggestionChip('Phú Quốc', kNavy, kLight, kAzure),
                    _buildSuggestionChip('Sapa', kNavy, kLight, kAzure),
                    _buildSuggestionChip('Hà Giang', kNavy, kLight, kAzure),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Results Header
              Text(
                _query.isEmpty ? 'Tất cả chuyến đi' : 'Kết quả tìm kiếm (${filteredTrips.length})',
                style: AppTheme.titleSm(color: kLight),
              ),
              const SizedBox(height: 16),

              // Trips List
              if (filteredTrips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, color: kGray.withValues(alpha: 0.5), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy chuyến đi nào',
                          style: AppTheme.bodyMd(color: kLight.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) {
                    final trip = filteredTrips[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TripWorkspaceScreen(
                              tripName: trip.tripName,
                              destination: trip.destination,
                              budgetText: trip.budgetText,
                              budgetProgress: trip.budgetProgress,
                              spentText: trip.spentText,
                              remainingText: trip.remainingText,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: kNavy,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: AppTheme.thinBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    trip.tripName,
                                    style: AppTheme.titleSm(color: kLight),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: trip.status == 'active'
                                        ? AppTheme.iosGreen.withValues(alpha: 0.15)
                                        : kAzure.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    trip.status == 'active' ? 'Đang đi' : 'Sắp đi',
                                    style: AppTheme.labelXs(
                                      color: trip.status == 'active'
                                          ? AppTheme.iosGreen
                                          : kAzure,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: kGray, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  trip.destination,
                                  style: AppTheme.bodySm(color: kLight.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: kLight.withValues(alpha: 0.08), height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ngân sách',
                                      style: AppTheme.labelSm(color: kLight.withValues(alpha: 0.4)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      trip.budgetText,
                                      style: AppTheme.bodySm(color: kLight),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Thành viên',
                                      style: AppTheme.labelSm(color: kLight.withValues(alpha: 0.4)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${trip.memberCount} người',
                                      style: AppTheme.bodySm(color: kLight),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, Color bg, Color textCol, Color activeCol) {
    return GestureDetector(
      onTap: () => _applySuggestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppTheme.iosBorderDark, width: 0.5),
        ),
        child: Text(
          text,
          style: AppTheme.bodySm(color: textCol.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}
