import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_model.dart';

class ReportState {
  final List<ReportModel> history;
  final bool isGenerating;
  final bool isLoadingHistory;
  final String? errorMessage;
  final ReportModel? lastGeneratedReport;

  ReportState({
    this.history = const [],
    this.isGenerating = false,
    this.isLoadingHistory = false,
    this.errorMessage,
    this.lastGeneratedReport,
  });

  ReportState copyWith({
    List<ReportModel>? history,
    bool? isGenerating,
    bool? isLoadingHistory,
    String? errorMessage,
    ReportModel? lastGeneratedReport,
  }) {
    return ReportState(
      history: history ?? this.history,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: errorMessage,
      lastGeneratedReport: lastGeneratedReport ?? this.lastGeneratedReport,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;

  ReportNotifier({ReportRepository? repository})
      : _repository = repository ?? ReportRepository(),
        super(ReportState()) {
    fetchReportHistory();
  }

  Future<void> fetchReportHistory({String? type}) async {
    state = state.copyWith(isLoadingHistory: true, errorMessage: null);
    try {
      final reports = await _repository.getReportHistory(type: type);
      state = state.copyWith(history: reports, isLoadingHistory: false);
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, errorMessage: e.toString());
    }
  }

  Future<ReportModel?> generateReport({
    required String type,
    required String from,
    required String to,
    String? projectId,
  }) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);
    try {
      final report = await _repository.generateReport(
        type: type,
        from: from,
        to: to,
        projectId: projectId,
      );

      final updatedHistory = [report, ...state.history];
      state = state.copyWith(
        isGenerating: false,
        lastGeneratedReport: report,
        history: updatedHistory,
      );
      return report;
    } catch (e) {
      state = state.copyWith(isGenerating: false, errorMessage: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier();
});
