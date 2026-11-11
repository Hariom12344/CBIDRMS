import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';

class DashboardState {
  final Map<String, dynamic> summary;
  final List<ActivityItemModel> activities;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.summary = const {},
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    Map<String, dynamic>? summary,
    List<ActivityItemModel>? activities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository = DashboardRepository();

  DashboardNotifier() : super(DashboardState()) {
    fetchDashboardData();
  }

  // Fetch summary and activities in parallel
  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.getSummary(),
        _repository.getActivities(limit: 10),
      ]);

      final summaryData = results[0] as Map<String, dynamic>;
      final activitiesData = results[1] as List<ActivityItemModel>;

      state = state.copyWith(
        summary: summaryData,
        activities: activitiesData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
