class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  ); // Web gateway

  static const String register = '/auth/register';
  static const String sendRegistrationOtp = '/auth/register/send-otp';
  static const String verifyRegistrationOtp = '/auth/register/verify-otp';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String uploadAvatar = '/auth/me/avatar';
  static const String upgradePro = '/auth/upgrade-pro';
  static const String googleLogin = '/auth/google';

  static const String trips = '/trips';
  static const String joinTrip = '/trips/join';
  static String trip(String tripId) => '/trips/$tripId';
  static String leaveTrip(String tripId) => '/trips/$tripId/leave';
  static String tripFiles(String tripId) => '/trips/$tripId/files';
  static String uploadTripFile(String tripId) => '/trips/$tripId/files/upload';
  static String tripNotes(String tripId) => '/trips/$tripId/files/notes';
  static String tripFile(String tripId, String fileId) =>
      '/trips/$tripId/files/$fileId';

  static String tripLegs(String tripId) => '/trips/$tripId/legs';
  static String tripLeg(String tripId, String legId) =>
      '/trips/$tripId/legs/$legId';

  static const String expenses = '/expenses';
  static String tripExpenses(String tripId) => '/expenses/trip/$tripId';
  static String tripBalances(String tripId) =>
      '/expenses/trip/$tripId/balances';
  static const String settleDebt = '/expenses/settle';

  static const String contributeToPool = '/expenses/pool/contribute';
  static String getPool(String tripId) => '/expenses/pool/$tripId';
  static const String vietQrBanks = '/expenses/vietqr/banks';
  static const String generateVietQr = '/expenses/vietqr/generate';
  static String generateDebtVietQr(String debtRecordId) =>
      '/expenses/vietqr/debts/$debtRecordId/generate';
  static String generateFundContributionVietQr(String tripId) =>
      '/expenses/vietqr/trips/$tripId/fund-contribution/generate';
  static const String defaultReceivePaymentMethod =
      '/expenses/payment-methods/default-receive';

  static const String notifications = '/notifications';
  static const String notificationDevices = '/notifications/devices';
  static const String registerNotificationDevice =
      '$notificationDevices/register';
  static String notificationDevice(String token) =>
      '$notificationDevices/${Uri.encodeComponent(token)}';
}
