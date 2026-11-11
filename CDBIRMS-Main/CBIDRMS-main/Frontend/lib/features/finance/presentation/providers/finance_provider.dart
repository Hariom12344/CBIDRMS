import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/models/finance_model.dart';

class FinanceState {
  final double received;
  final double pending;
  final double overdue;
  final List<InvoiceModel> invoices;
  final List<ExpenseModel> expenses;
  final Map<String, ProjectBudgetModel> projectBudgets;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedProjectId;
  final String selectedInvoiceStatus; // ALL, PENDING, PAID, OVERDUE

  FinanceState({
    this.received = 0.0,
    this.pending = 0.0,
    this.overdue = 0.0,
    this.invoices = const [],
    this.expenses = const [],
    this.projectBudgets = const {},
    this.isLoading = false,
    this.errorMessage,
    this.selectedProjectId,
    this.selectedInvoiceStatus = 'ALL',
  });

  FinanceState copyWith({
    double? received,
    double? pending,
    double? overdue,
    List<InvoiceModel>? invoices,
    List<ExpenseModel>? expenses,
    Map<String, ProjectBudgetModel>? projectBudgets,
    bool? isLoading,
    String? errorMessage,
    String? selectedProjectId,
    String? selectedInvoiceStatus,
  }) {
    return FinanceState(
      received: received ?? this.received,
      pending: pending ?? this.pending,
      overdue: overdue ?? this.overdue,
      invoices: invoices ?? this.invoices,
      expenses: expenses ?? this.expenses,
      projectBudgets: projectBudgets ?? this.projectBudgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedInvoiceStatus: selectedInvoiceStatus ?? this.selectedInvoiceStatus,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;

  FinanceNotifier({FinanceRepository? repository})
      : _repository = repository ?? FinanceRepository(),
        super(FinanceState()) {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await _repository.getFinanceSummary();
      final invoices = await _repository.getInvoices(
        projectId: state.selectedProjectId,
        status: state.selectedInvoiceStatus,
      );
      final expenses = await _repository.getExpenses(projectId: state.selectedProjectId);

      state = state.copyWith(
        received: summary['received'] ?? 0.0,
        pending: summary['pending'] ?? 0.0,
        overdue: summary['overdue'] ?? 0.0,
        invoices: invoices,
        expenses: expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setProjectId(String? projectId) {
    state = state.copyWith(selectedProjectId: projectId);
    fetchAllData();
  }

  void setInvoiceStatus(String status) {
    state = state.copyWith(selectedInvoiceStatus: status);
    fetchAllData();
  }

  Future<ProjectBudgetModel?> fetchProjectBudget(String projectId) async {
    try {
      final budget = await _repository.getProjectBudget(projectId);
      final updatedMap = Map<String, ProjectBudgetModel>.from(state.projectBudgets);
      updatedMap[projectId] = budget;
      state = state.copyWith(projectBudgets: updatedMap);
      return budget;
    } catch (e) {
      return null;
    }
  }

  Future<bool> generateInvoice({
    required String projectId,
    required String clientName,
    required double amount,
    required String dueDate,
  }) async {
    try {
      await _repository.createInvoice(
        projectId: projectId,
        clientName: clientName,
        amount: amount,
        dueDate: dueDate,
      );
      await fetchAllData();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> recordPayment(
    String invoiceId, {
    required double amount,
    String? date,
    String? method,
    String? note,
  }) async {
    try {
      await _repository.recordPayment(
        invoiceId,
        amount: amount,
        date: date,
        method: method,
        note: note,
      );
      await fetchAllData();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> recordExpense({
    required String projectId,
    required String category,
    required double amount,
    String? date,
    String? note,
  }) async {
    try {
      await _repository.createExpense(
        projectId: projectId,
        category: category,
        amount: amount,
        date: date,
        note: note,
      );
      await fetchAllData();
      await fetchProjectBudget(projectId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> setProjectBudget({
    required String projectId,
    required double budget,
  }) async {
    try {
      final updatedBudget = await _repository.setProjectBudget(projectId, budget);
      final updatedMap = Map<String, ProjectBudgetModel>.from(state.projectBudgets);
      updatedMap[projectId] = updatedBudget;
      state = state.copyWith(projectBudgets: updatedMap);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final financeNotifierProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
