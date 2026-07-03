import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ios_ui.dart';
import '../../../home/presentation/controllers/trips_provider.dart';
import '../../../home/presentation/screens/trip_workspace_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final trips = tripsState.valueOrNull ?? [];
    final filteredTrips = trips.where((trip) {
      if (_query.isEmpty) return true;
      return trip.name.toLowerCase().contains(_query) ||
          (trip.description?.toLowerCase().contains(_query) ?? false);
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Tìm kiếm')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Tìm chuyến đi, điểm đến...',
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
              ),
            ),
          ),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: IosSection(
                header: 'Gợi ý phổ biến',
                children: ['Đà Lạt', 'Phú Quốc', 'Sapa', 'Hà Giang']
                    .map(
                      (text) => IosListTile(
                        icon: CupertinoIcons.location,
                        title: text,
                        onTap: () {
                          _searchController.text = text;
                          setState(() => _query = text.toLowerCase());
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          tripsState.when(
            loading: () => const SliverFillRemaining(child: IosLoading()),
            error: (err, stack) => SliverFillRemaining(
              child: IosEmptyState(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Không thể tìm kiếm',
                message: err.toString(),
              ),
            ),
            data: (_) {
              if (filteredTrips.isEmpty) {
                return const SliverFillRemaining(
                  child: IosEmptyState(
                    icon: CupertinoIcons.search,
                    title: 'Không tìm thấy',
                    message: 'Thử tìm bằng tên chuyến đi hoặc điểm đến khác.',
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: IosSection(
                  header: _query.isEmpty
                      ? 'Tất cả chuyến đi'
                      : 'Kết quả (${filteredTrips.length})',
                  children: filteredTrips.map((trip) {
                    return IosListTile(
                      icon: CupertinoIcons.map,
                      title: trip.name,
                      subtitle: trip.description ?? 'Không có mô tả',
                      value: '${trip.memberCount} người',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => TripWorkspaceScreen(
                              tripId: trip.id,
                              tripName: trip.name,
                              destination: trip.description ?? 'Không có mô tả',
                              baseCurrency: trip.baseCurrency,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 132)),
        ],
      ),
    );
  }
}
