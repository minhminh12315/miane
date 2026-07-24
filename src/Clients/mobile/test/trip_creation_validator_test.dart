import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/domain/services/trip_creation_validator.dart';

void main() {
  final today = DateTime(2026, 7, 24);

  TripCreationValidation validate({
    String name = 'Đà Lạt',
    String? destination = 'Đà Lạt',
    DateTime? start,
    DateTime? end,
  }) {
    return TripCreationValidator.validate(
      name: name,
      destination: destination,
      startDate: start ?? DateTime(2026, 8, 1),
      endDate: end ?? DateTime(2026, 8, 3),
      now: today,
    );
  }

  test('accepts a normal future trip without confirmation', () {
    final result = validate();

    expect(result.isValid, isTrue);
    expect(result.needsConfirmation, isFalse);
    expect(result.durationDays, 3);
  });

  test('rejects missing and oversized required values', () {
    expect(validate(name: '   ').errorMessage, 'Vui lòng nhập tên chuyến đi.');
    expect(validate(destination: null).errorMessage,
        'Vui lòng chọn địa điểm cho chuyến đi.');
    expect(
      validate(name: 'a' * 201).errorMessage,
      'Tên chuyến đi không được vượt quá 200 ký tự.',
    );
    expect(
      validate(destination: 'a' * 241).errorMessage,
      'Điểm đến không được vượt quá 240 ký tự.',
    );
  });

  test('rejects an inverted date range', () {
    final result = validate(
      start: DateTime(2026, 8, 4),
      end: DateTime(2026, 8, 3),
    );

    expect(result.isValid, isFalse);
    expect(result.errorMessage, 'Ngày kết thúc không được trước ngày bắt đầu.');
  });

  test('requires confirmation when the trip already ended', () {
    final result = validate(
      start: DateTime(2026, 7, 10),
      end: DateTime(2026, 7, 12),
    );

    expect(result.isValid, isTrue);
    expect(result.warnings, contains(TripCreationWarning.alreadyEnded));
  });

  test('requires confirmation when the trip already started', () {
    final result = validate(
      start: DateTime(2026, 7, 20),
      end: DateTime(2026, 7, 28),
    );

    expect(result.warnings, contains(TripCreationWarning.alreadyStarted));
    expect(result.warnings, isNot(contains(TripCreationWarning.alreadyEnded)));
  });

  test('requires confirmation for an unusually long trip', () {
    final result = validate(
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 11, 1),
    );

    expect(result.durationDays, 93);
    expect(result.warnings, contains(TripCreationWarning.unusuallyLong));
  });
}
