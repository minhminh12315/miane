/// A single leg/segment of a multi-stop trip (e.g. Hà Nội → Đà Nẵng → Sài Gòn).
class TripLegModel {
  final String id;
  final int order;
  final String name;
  final String? destinationCity;
  final String? destinationCountry;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  const TripLegModel({
    required this.id,
    required this.order,
    required this.name,
    this.destinationCity,
    this.destinationCountry,
    this.startDate,
    this.endDate,
    this.notes,
  });

  String get destinationLabel {
    final parts = [destinationCity, destinationCountry]
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>();
    return parts.isEmpty ? name : parts.join(', ');
  }

  factory TripLegModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return TripLegModel(
      id: (json['id'] ?? '').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      destinationCity: json['destinationCity'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      notes: json['notes'] as String?,
    );
  }
}
