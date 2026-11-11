import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/project_model.dart';

class ProjectRepository {
  final DioClient _dioClient;

  ProjectRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Fetch all projects
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _dioClient.instance.get(ApiConstants.projects);
      final data = response.data['data'] ?? {};
      final List projectsJson = data['projects'] ?? [];
      return projectsJson.map((json) => ProjectModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get project by ID (authoritative record with team & stages)
  Future<ProjectModel> getProject(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.projects}/$id');
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create new project manually
  Future<ProjectModel> createProject({
    required String name,
    required String clientName,
    String? designerName,
    String? startDate,
    String? endDate,
    double? budget,
    String? status,
    double? progress,
  }) async {
    try {
      final payload = {
        'name': name,
        'clientName': clientName,
        if (designerName != null) 'designerName': designerName,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (budget != null) 'budget': budget,
        if (status != null) 'status': status,
        if (progress != null) 'progress': progress,
      };

      final response = await _dioClient.instance.post(
        ApiConstants.projects,
        data: payload,
      );
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update project fields or status
  Future<ProjectModel> updateProject(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.projects}/$id',
        data: updateData,
      );
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign team to project
  Future<ProjectModel> assignTeam(String id, List<Map<String, dynamic>> team) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.projects}/$id/team',
        data: {'assignedTeam': team},
      );
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add stage to project
  Future<ProjectModel> addStage(String id, String name, {String? startDate, String? endDate}) async {
    try {
      final payload = {
        'name': name,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      };

      final response = await _dioClient.instance.post(
        '${ApiConstants.projects}/$id/stages',
        data: payload,
      );
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update stage status
  Future<ProjectModel> updateStageStatus(String id, int stageId, String status) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.projects}/$id/stages/$stageId',
        data: {'status': status},
      );
      final data = response.data['data'];
      return ProjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['error'] ?? map['message'] ?? 'An error occurred';
    }
    return 'Connection error. Please check your backend at http://localhost:5000/api';
  }
}
