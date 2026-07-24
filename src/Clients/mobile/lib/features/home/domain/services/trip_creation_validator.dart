enum TripCreationWarning {
  alreadyEnded,
  alreadyStarted,
  unusuallyLong,
}

class TripCreationValidation {
  final String? errorMessage;
  final List<TripCreationWarning> warnings;
  final int durationDays;

  const TripCreationValidation({
    required this.errorMessage,
    required this.warnings,
    required this.durationDays,
  });

  bool get isValid => errorMessage == null;
  bool get needsConfirmation => warnings.isNotEmpty;
}

class TripCreationValidator {
  static const int maxNameLength = 200;
  static const int maxDestinationLength = 240;
  static const int unusuallyLongTripDays = 90;

  const TripCreationValidator._();

  static TripCreationValidation validate({
    required String name,
    required String? destination,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? now,
  }) {
    final normalizedName = name.trim();
    final normalizedDestination = destination?.trim() ?? '';
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final today = _dateOnly(now ?? DateTime.now());
    final durationDays = end.difference(start).inDays + 1;

    String? errorMessage;
    if (normalizedName.isEmpty) {
      errorMessage = 'Vui lòng nhập tên chuyến đi.';
    } else if (normalizedName.length > maxNameLength) {
      errorMessage = 'Tên chuyến đi không được vượt quá $maxNameLength ký tự.';
    } else if (normalizedDestination.isEmpty) {
      errorMessage = 'Vui lòng chọn địa điểm cho chuyến đi.';
    } else if (normalizedDestination.length > maxDestinationLength) {
      errorMessage =
          'Điểm đến không được vượt quá $maxDestinationLength ký tự.';
    } else if (end.isBefore(start)) {
      errorMessage = 'Ngày kết thúc không được trước ngày bắt đầu.';
    }

    final warnings = <TripCreationWarning>[];
    if (errorMessage == null) {
      if (end.isBefore(today)) {
        warnings.add(TripCreationWarning.alreadyEnded);
      } else if (start.isBefore(today)) {
        warnings.add(TripCreationWarning.alreadyStarted);
      }

      if (durationDays > unusuallyLongTripDays) {
        warnings.add(TripCreationWarning.unusuallyLong);
      }
    }

    return TripCreationValidation(
      errorMessage: errorMessage,
      warnings: List.unmodifiable(warnings),
      durationDays: durationDays,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
