class ApiConstants {
  // Base URL pointing to the Node.js Express backend
  static const String baseUrl = 'http://localhost:5000/api';
  // Use http://10.0.2.2:5000/api when running on Android Emulator
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
}
