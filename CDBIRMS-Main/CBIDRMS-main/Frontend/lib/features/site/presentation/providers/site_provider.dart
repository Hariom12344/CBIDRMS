import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/site_repository.dart';
import '../../domain/models/site_update_model.dart';
import '../../domain/models/site_task_model.dart';

class SiteState {
  final bool isUpdatesLoading;
  final bool isTasksLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<SiteUpdateModel> siteUpdates;
  final List<SiteTaskModel> siteTasks;
  final String? selectedProjectId;

  SiteState({
    this.isUpdatesLoading = false,
    this.isTasksLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.siteUpdates = const [],
    this.siteTasks = const [],
    this.selectedProjectId,
  });

  SiteState copyWith({
    bool? isUpdatesLoading,
    bool? isTasksLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<SiteUpdateModel>? siteUpdates,
    List<SiteTaskModel>? siteTasks,
    String? selectedProjectId,
  }) {
    return SiteState(
      isUpdatesLoading: isUpdatesLoading ?? this.isUpdatesLoading,
      isTasksLoading: isTasksLoading ?? this.isTasksLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      siteUpdates: siteUpdates ?? this.siteUpdates,
      siteTasks: siteTasks ?? this.siteTasks,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class SiteNotifier extends StateNotifier<SiteState> {
  final SiteRepository _repository;

  SiteNotifier(this._repository) : super(SiteState());

  Future<void> fetchSiteUpdates({String? projectId}) async {
    state = state.copyWith(isUpdatesLoading: true, errorMessage: null);
    try {
      final updates = await _repository.getSiteUpdates(projectId: projectId ?? state.selectedProjectId);
      state = state.copyWith(isUpdatesLoading: false, siteUpdates: updates);
    } catch (e) {
      state = state.copyWith(isUpdatesLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> postSiteUpdate({
    required String projectId,
    required String description,
    String? issueReported,
    String? issueSeverity,
    List<String>? photoUrls,
    List<PlatformFile>? pickedFiles,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final newUpdate = await _repository.postSiteUpdate(
        projectId: projectId,
        description: description,
        issueReported: issueReported,
        issueSeverity: issueSeverity,
        photoUrls: photoUrls,
        pickedFiles: pickedFiles,
      );
      state = state.copyWith(
        isSubmitting: false,
        siteUpdates: [newUpdate, ...state.siteUpdates],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> fetchSiteTasks({String? projectId}) async {
    state = state.copyWith(isTasksLoading: true, errorMessage: null);
    try {
      final tasks = await _repository.getSiteTasks(projectId: projectId ?? state.selectedProjectId);
      state = state.copyWith(isTasksLoading: false, siteTasks: tasks);
    } catch (e) {
      state = state.copyWith(isTasksLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> postSiteTask({
    required String projectId,
    required String title,
    dynamic assignedTo,
    String? dueDate,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final newTask = await _repository.postSiteTask(
        projectId: projectId,
        title: title,
        assignedTo: assignedTo,
        dueDate: dueDate,
      );
      state = state.copyWith(
        isSubmitting: false,
        siteTasks: [newTask, ...state.siteTasks],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required String newStatus,
    String? linkedSiteUpdateId,
  }) async {
    // Optimistic update
    final originalTasks = [...state.siteTasks];
    final updatedTasks = state.siteTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(status: newStatus, linkedSiteUpdateId: linkedSiteUpdateId);
      }
      return t;
    }).toList();

    state = state.copyWith(siteTasks: updatedTasks);

    try {
      final updatedTask = await _repository.updateTaskStatus(
        id: taskId,
        status: newStatus,
        linkedSiteUpdateId: linkedSiteUpdateId,
      );
      
      final finalTasks = state.siteTasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(siteTasks: finalTasks);
      return true;
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(siteTasks: originalTasks, errorMessage: e.toString());
      return false;
    }
  }

  void setSelectedProject(String? projectId) {
    state = state.copyWith(selectedProjectId: projectId);
    fetchSiteUpdates(projectId: projectId);
    fetchSiteTasks(projectId: projectId);
  }
}

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  return SiteRepository();
});

final siteNotifierProvider = StateNotifierProvider<SiteNotifier, SiteState>((ref) {
  return SiteNotifier(ref.watch(siteRepositoryProvider));
});
