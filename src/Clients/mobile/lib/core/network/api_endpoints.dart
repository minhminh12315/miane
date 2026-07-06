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
  static const String upgradePro = '/auth/upgrade-pro';
  
  static const String trips = '/trips';
  static const String joinTrip = '/trips/join';
  static String leaveTrip(String tripId) => '/trips/$tripId/leave';
  
  static const String expenses = '/expenses';
  static String tripExpenses(String tripId) => '/expenses/trip/$tripId';
  static String tripBalances(String tripId) => '/expenses/trip/$tripId/balances';
  static const String settleDebt = '/expenses/settle';
  
  static const String contributeToPool = '/expenses/pool/contribute';
  static String getPool(String tripId) => '/expenses/pool/$tripId';
  
  static const String notifications = '/notifications';
}
