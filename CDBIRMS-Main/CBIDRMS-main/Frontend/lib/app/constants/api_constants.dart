import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL dynamically resolved based on platform (10.0.2.2 for Android Emulator, localhost for Web/Desktop)
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Feature Endpoints
  static const String leads = '/leads';
  static const String projects = '/projects';
  static const String customers = '/customers';
  static const String boq = '/boq';
  static const String vendors = '/vendors';
  static const String financeSummary = '/finance/summary';
  static const String financeInvoices = '/finance/invoices';
  static const String financeExpenses = '/finance/expenses';
  static const String financeBudget = '/finance/projects';
  static const String documents = '/documents';
  static const String designs = '/designs';
  static const String users = '/users';
  static const String purchaseOrders = '/purchase-orders';
  static const String siteUpdates = '/site-updates';
  static const String siteTasks = '/site-tasks';
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardActivities = '/dashboard/activities';
  static const String reportsGenerate = '/reports';
  static const String reportsHistory = '/reports/history';
  static const String analyticsTrends = '/analytics/trends';
  static const String quotations = '/quotations';
}
