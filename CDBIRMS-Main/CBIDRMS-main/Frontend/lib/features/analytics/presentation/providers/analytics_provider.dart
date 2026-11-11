import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/models/trend_model.dart';

class AnalyticsState {
  final bool isLoading;
  final String fromDate;
  final String toDate;
  final String selectedRangePreset; // 7_DAYS, 30_DAYS, 90_DAYS, CUSTOM
  final List<TrendSeriesModel> seriesList;
  final String? errorMessage;

  AnalyticsState({
    required this.isLoading,
    required this.fromDate,
    required this.toDate,
    required this.selectedRangePreset,
    required this.seriesList,
    this.errorMessage,
  });

  factory AnalyticsState.initial() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final toIso = now.toIso8601String().split('T')[0];
    final fromIso = thirtyDaysAgo.toIso8601String().split('T')[0];

    return AnalyticsState(
      isLoading: false,
      fromDate: fromIso,
      toDate: toIso,
      selectedRangePreset: '30_DAYS',
      seriesList: [],
      errorMessage: null,
    );
  }

  AnalyticsState copyWith({
    bool? isLoading,
    String? fromDate,
    String? toDate,
    String? selectedRangePreset,
    List<TrendSeriesModel>? seriesList,
    String? errorMessage,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      selectedRangePreset: selectedRangePreset ?? this.selectedRangePreset,
      seriesList: seriesList ?? this.seriesList,
      errorMessage: errorMessage,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository(),
        super(AnalyticsState.initial());

  Future<void> fetchTrends() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final series = await _repository.getTrends(
        from: state.fromDate,
        to: state.toDate,
      );
      state = state.copyWith(
        isLoading: false,
        seriesList: series,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        seriesList: [],
        errorMessage: e.toString(),
      );
    }
  }

  void setPreset(String preset) {
    final now = DateTime.now();
    final toIso = now.toIso8601String().split('T')[0];
    String fromIso = state.fromDate;

    if (preset == '7_DAYS') {
      fromIso = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
    } else if (preset == '30_DAYS') {
      fromIso = now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    } else if (preset == '90_DAYS') {
      fromIso = now.subtract(const Duration(days: 90)).toIso8601String().split('T')[0];
    }

    state = state.copyWith(
      fromDate: fromIso,
      toDate: toIso,
      selectedRangePreset: preset,
    );
    fetchTrends();
  }

  void setCustomRange(String from, String to) {
    state = state.copyWith(
      fromDate: from,
      toDate: to,
      selectedRangePreset: 'CUSTOM',
    );
    fetchTrends();
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
