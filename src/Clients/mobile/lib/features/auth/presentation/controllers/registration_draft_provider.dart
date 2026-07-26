import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory registration draft so the password is not passed via route args.
class RegistrationDraft {
  final String email;
  final String password;
  final String fullName;

  const RegistrationDraft({
    required this.email,
    required this.password,
    required this.fullName,
  });
}

final registrationDraftProvider =
    StateProvider<RegistrationDraft?>((ref) => null);
