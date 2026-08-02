class ApiConstants {
  // Base URL matching your Express backend: app.use("/api/auth", authRoutes)
  static const String baseUrl = 'http://localhost:5000/api';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Feature Endpoints
  static const String projects = '/projects';
  static const String customers = '/customers';
  static const String boq = '/boq';
  static const String vendors = '/vendors';
  static const String financePayments = '/finance/payments';
  static const String financeInvoices = '/finance/invoices';
  static const String financeTransactions = '/finance/transactions';
  static const String documents = '/documents';
}
