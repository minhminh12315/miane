import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trips_provider.g.dart';

class TripItem {
  final String tripName;
  final String destination;
  final String budgetText;
  final double budgetProgress;
  final String spentText;
  final String remainingText;
  final String status; // 'active', 'upcoming', 'completed'
  final String timeText;
  final int memberCount;

  TripItem({
    required this.tripName,
    required this.destination,
    required this.budgetText,
    required this.budgetProgress,
    required this.spentText,
    required this.remainingText,
    required this.status,
    required this.timeText,
    required this.memberCount,
  });
}

@riverpod
class Trips extends _$Trips {
  @override
  List<TripItem> build() {
    return [
      TripItem(
        tripName: 'Phượt Đà Lạt bụi - Tháng 6',
        destination: 'Đà Lạt, Lâm Đồng',
        budgetText: '25.000.000 đ',
        budgetProgress: 0.356,
        spentText: '8.900.000 đ',
        remainingText: '16.100.000 đ',
        status: 'active',
        timeText: 'Đang diễn ra • 2 ngày nữa kết thúc',
        memberCount: 4,
      ),
      TripItem(
        tripName: 'Nghỉ dưỡng hè Phú Quốc',
        destination: 'Phú Quốc, Kiên Giang',
        budgetText: '45.000.000 đ',
        budgetProgress: 0.0,
        spentText: '0 đ',
        remainingText: '45.000.000 đ',
        status: 'upcoming',
        timeText: 'Còn 12 ngày • 18/06 - 22/06',
        memberCount: 5,
      ),
    ];
  }

  void addTrip(TripItem trip) {
    state = [...state, trip];
  }
}
