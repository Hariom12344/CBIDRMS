import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/project_repository.dart';
import '../../domain/models/project_model.dart';

class ProjectsState {
  final List<ProjectModel> projects;
  final ProjectModel? selectedProject;
  final bool isLoading;
  final bool isDetailLoading;
  final String? errorMessage;

  ProjectsState({
    this.projects = const [],
    this.selectedProject,
    this.isLoading = false,
    this.isDetailLoading = false,
    this.errorMessage,
  });

  ProjectsState copyWith({
    List<ProjectModel>? projects,
    ProjectModel? selectedProject,
    bool? isLoading,
    bool? isDetailLoading,
    String? errorMessage,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      isLoading: isLoading ?? this.isLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      errorMessage: errorMessage,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectsState> {
  final ProjectRepository _repository = ProjectRepository();

  ProjectNotifier() : super(ProjectsState()) {
    fetchProjects();
  }

  // Fetch all active projects
  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getProjects();
      state = state.copyWith(projects: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Fetch detailed project by ID
  Future<ProjectModel?> fetchProjectDetails(String id) async {
    state = state.copyWith(isDetailLoading: true, errorMessage: null);
    try {
      final project = await _repository.getProject(id);
      state = state.copyWith(selectedProject: project, isDetailLoading: false);
      _updateProjectInList(project);
      return project;
    } catch (e) {
      state = state.copyWith(isDetailLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  // Update status or fields
  Future<bool> updateProjectStatus(String id, String status) async {
    try {
      final updated = await _repository.updateProject(id, {'status': status});
      state = state.copyWith(selectedProject: updated);
      _updateProjectInList(updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Assign team
  Future<bool> assignTeamToProject(String id, List<Map<String, dynamic>> team) async {
    try {
      final updated = await _repository.assignTeam(id, team);
      state = state.copyWith(selectedProject: updated);
      _updateProjectInList(updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Add stage
  Future<bool> addStageToProject(String id, String name, {String? startDate, String? endDate}) async {
    try {
      final updated = await _repository.addStage(id, name, startDate: startDate, endDate: endDate);
      state = state.copyWith(selectedProject: updated);
      _updateProjectInList(updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Update stage status
  Future<bool> updateStageStatus(String id, int stageId, String status) async {
    try {
      final updated = await _repository.updateStageStatus(id, stageId, status);
      state = state.copyWith(selectedProject: updated);
      _updateProjectInList(updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Add a single project locally
  void addProjectToList(ProjectModel newProject) {
    final exists = state.projects.any((p) => p.id == newProject.id);
    if (!exists) {
      state = state.copyWith(
        projects: [newProject, ...state.projects],
      );
    }
  }

  void _updateProjectInList(ProjectModel updated) {
    final newList = state.projects.map((p) => p.id == updated.id ? updated : p).toList();
    state = state.copyWith(projects: newList);
  }
}

final projectNotifierProvider = StateNotifierProvider<ProjectNotifier, ProjectsState>((ref) {
  return ProjectNotifier();
});
