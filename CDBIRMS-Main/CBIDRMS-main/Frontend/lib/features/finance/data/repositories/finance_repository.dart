import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/finance_model.dart';

class FinanceRepository {
  final DioClient _dioClient;

  FinanceRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  /// Get Dashboard Finance Summary (Received, Pending, Overdue)
  Future<Map<String, double>> getFinanceSummary() async {
    try {
      final response = await _dioClient.instance.get(ApiConstants.financeSummary);
      final data = response.data['data'] ?? response.data;
      return {
        'received': (data['received'] ?? 0.0).toDouble(),
        'pending': (data['pending'] ?? 0.0).toDouble(),
        'overdue': (data['overdue'] ?? 0.0).toDouble(),
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get List of Invoices
  Future<List<InvoiceModel>> getInvoices({String? projectId, String? status}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.financeInvoices,
        queryParameters: {
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
          if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        },
      );
      final data = response.data['data'] ?? response.data;
      final rawList = data['invoices'] as List? ?? [];
      return rawList.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate / Create Invoice
  Future<InvoiceModel> createInvoice({
    required String projectId,
    required String clientName,
    required double amount,
    required String dueDate,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.financeInvoices,
        data: {
          'projectId': projectId,
          'clientName': clientName,
          'amount': amount,
          'dueDate': dueDate,
        },
      );
      final data = response.data['data'] ?? response.data;
      final invMap = data['invoice'] as Map<String, dynamic>? ?? data;
      return InvoiceModel.fromJson(invMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Record Payment against Invoice
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    String? date,
    String? method,
    String? note,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.financeInvoices}/$invoiceId/payments',
        data: {
          'amount': amount,
          if (date != null && date.isNotEmpty) 'date': date,
          if (method != null && method.isNotEmpty) 'method': method,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = response.data['data'] ?? response.data;
      return {
        'payment': PaymentModel.fromJson(data['payment'] as Map<String, dynamic>),
        'invoice': InvoiceModel.fromJson(data['invoice'] as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get List of Expenses
  Future<List<ExpenseModel>> getExpenses({String? projectId, String? category}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.financeExpenses,
        queryParameters: {
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
          if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
        },
      );
      final data = response.data['data'] ?? response.data;
      final rawList = data['expenses'] as List? ?? [];
      return rawList.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create / Record Expense
  Future<ExpenseModel> createExpense({
    required String projectId,
    required String category,
    required double amount,
    String? date,
    String? note,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.financeExpenses,
        data: {
          'projectId': projectId,
          'category': category,
          'amount': amount,
          if (date != null && date.isNotEmpty) 'date': date,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = response.data['data'] ?? response.data;
      final expMap = data['expense'] as Map<String, dynamic>? ?? data;
      return ExpenseModel.fromJson(expMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Project Budget Summary
  Future<ProjectBudgetModel> getProjectBudget(String projectId) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.financeBudget}/$projectId/budget');
      final data = response.data['data'] ?? response.data;
      return ProjectBudgetModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set or Update Project Budget
  Future<ProjectBudgetModel> setProjectBudget(String projectId, double budget) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.financeBudget}/$projectId/budget',
        data: {'budget': budget},
      );
      final data = response.data['data'] ?? response.data;
      return ProjectBudgetModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final message = error.response?.data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    return error.message ?? 'An unexpected network error occurred';
  }
}
