import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/site_update_model.dart';
import '../../domain/models/site_task_model.dart';

class SiteRepository {
  final DioClient _dioClient;

  SiteRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Fetch site updates feed
  Future<List<SiteUpdateModel>> getSiteUpdates({String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['projectId'] = projectId;
      }

      final response = await _dioClient.instance.get(
        ApiConstants.siteUpdates,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? {};
      final List updatesJson = data['updates'] ?? [];
      return updatesJson.map((json) => SiteUpdateModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Post a site update (supports photo URLs and/or device file uploads)
  Future<SiteUpdateModel> postSiteUpdate({
    required String projectId,
    required String description,
    String? issueReported,
    String? issueSeverity,
    List<String>? photoUrls,
    List<PlatformFile>? pickedFiles,
  }) async {
    try {
      dynamic payload;
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final formData = FormData();
        formData.fields.add(MapEntry('projectId', projectId));
        formData.fields.add(MapEntry('description', description));
        if (issueReported != null && issueReported.trim().isNotEmpty) {
          formData.fields.add(MapEntry('issueReported', issueReported.trim()));
        }
        if (issueSeverity != null && issueSeverity.isNotEmpty) {
          formData.fields.add(MapEntry('issueSeverity', issueSeverity));
        }
        if (photoUrls != null && photoUrls.isNotEmpty) {
          formData.fields.add(MapEntry('photoUrls', jsonEncode(photoUrls)));
        }

        for (var file in pickedFiles) {
          if (file.bytes != null) {
            formData.files.add(MapEntry(
              'photos',
              MultipartFile.fromBytes(file.bytes!, filename: file.name),
            ));
          } else if (file.path != null) {
            formData.files.add(MapEntry(
              'photos',
              await MultipartFile.fromFile(file.path!, filename: file.name),
            ));
          }
        }
        payload = formData;
      } else {
        payload = {
          'projectId': projectId,
          'description': description,
          if (issueReported != null && issueReported.trim().isNotEmpty) 'issueReported': issueReported.trim(),
          if (issueSeverity != null && issueSeverity.isNotEmpty) 'issueSeverity': issueSeverity,
          if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        };
      }

      final response = await _dioClient.instance.post(
        ApiConstants.siteUpdates,
        data: payload,
      );

      final data = response.data['data']?['update'] ?? response.data['data'];
      return SiteUpdateModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch site tasks
  Future<List<SiteTaskModel>> getSiteTasks({String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['projectId'] = projectId;
      }

      final response = await _dioClient.instance.get(
        ApiConstants.siteTasks,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? {};
      final List tasksJson = data['tasks'] ?? [];
      return tasksJson.map((json) => SiteTaskModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create a new site task
  Future<SiteTaskModel> postSiteTask({
    required String projectId,
    required String title,
    dynamic assignedTo,
    String? dueDate,
  }) async {
    try {
      final payload = {
        'projectId': projectId,
        'title': title,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (dueDate != null && dueDate.isNotEmpty) 'dueDate': dueDate,
      };

      final response = await _dioClient.instance.post(
        ApiConstants.siteTasks,
        data: payload,
      );

      final data = response.data['data']?['task'] ?? response.data['data'];
      return SiteTaskModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update task status
  Future<SiteTaskModel> updateTaskStatus({
    required String id,
    required String status,
    String? linkedSiteUpdateId,
  }) async {
    try {
      final payload = {
        'status': status,
        if (linkedSiteUpdateId != null && linkedSiteUpdateId.isNotEmpty) 'linkedSiteUpdateId': linkedSiteUpdateId,
      };

      final response = await _dioClient.instance.patch(
        '${ApiConstants.siteTasks}/$id/status',
        data: payload,
      );

      final data = response.data['data']?['task'] ?? response.data['data'];
      return SiteTaskModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['error'] ?? map['message'] ?? 'An error occurred';
    }
    return 'Connection error. Please check your backend connection.';
  }
}
