import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/design_model.dart';

class DesignRepository {
  final DioClient _dioClient;

  DesignRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  /// Get list of designs (with optional filtering by projectId, category, search)
  Future<Map<String, dynamic>> getDesigns({
    String? projectId,
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.designs,
        queryParameters: {
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
          if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'] ?? response.data;
      final rawList = data['designs'] as List? ?? [];
      final designs = rawList.map((e) => DesignModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'designs': designs,
        'total': data['total'] ?? designs.length,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single design detail with approval history and revisions
  Future<Map<String, dynamic>> getDesignById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.designs}/$id');
      final data = response.data['data'] ?? response.data;
      final designMap = data['design'] as Map<String, dynamic>? ?? {};
      final design = DesignModel.fromJson(designMap);

      final approvalHistory = (data['approvalHistory'] as List? ?? [])
          .map((e) => DesignApprovalLogModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final revisions = (data['revisions'] as List? ?? [])
          .map((e) => DesignModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'design': design,
        'approvalHistory': approvalHistory,
        'revisions': revisions,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create / Upload initial design (v1.0) with multipart file upload support
  Future<DesignModel> createDesign({
    required String title,
    required String projectId,
    required String category,
    String fileType = 'PDF',
    String fileSize = '1.0 MB',
    String? fileUrl,
    PlatformFile? pickedFile,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      dynamic payload;

      if (pickedFile != null) {
        final formData = FormData();
        formData.fields.add(MapEntry('title', title));
        formData.fields.add(MapEntry('projectId', projectId));
        formData.fields.add(MapEntry('category', category));
        formData.fields.add(MapEntry('fileType', fileType));
        formData.fields.add(MapEntry('fileSize', fileSize));

        if (pickedFile.bytes != null) {
          formData.files.add(MapEntry(
            'file',
            MultipartFile.fromBytes(pickedFile.bytes!, filename: pickedFile.name),
          ));
        } else if (pickedFile.path != null) {
          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(pickedFile.path!, filename: pickedFile.name),
          ));
        }
        payload = formData;
      } else {
        payload = {
          'title': title,
          'projectId': projectId,
          'category': category,
          'fileType': fileType,
          'fileSize': fileSize,
          if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
        };
      }

      final response = await _dioClient.instance.post(
        ApiConstants.designs,
        data: payload,
        onSendProgress: onSendProgress,
      );

      final data = response.data['data'] ?? response.data;
      final docMap = data['design'] as Map<String, dynamic>? ?? data;
      return DesignModel.fromJson(docMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload revision against an existing design (v1.1 or v2.0)
  Future<DesignModel> createRevision({
    required String parentId,
    String? title,
    String? category,
    String? fileType,
    String? fileSize,
    String? fileUrl,
    PlatformFile? pickedFile,
    bool isMajorVersion = false,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      dynamic payload;

      if (pickedFile != null) {
        final formData = FormData();
        if (title != null && title.isNotEmpty) formData.fields.add(MapEntry('title', title));
        if (category != null && category.isNotEmpty) formData.fields.add(MapEntry('category', category));
        formData.fields.add(MapEntry('isMajorVersion', isMajorVersion.toString()));

        if (pickedFile.bytes != null) {
          formData.files.add(MapEntry(
            'file',
            MultipartFile.fromBytes(pickedFile.bytes!, filename: pickedFile.name),
          ));
        } else if (pickedFile.path != null) {
          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(pickedFile.path!, filename: pickedFile.name),
          ));
        }
        payload = formData;
      } else {
        payload = {
          if (title != null && title.isNotEmpty) 'title': title,
          if (category != null && category.isNotEmpty) 'category': category,
          if (fileType != null && fileType.isNotEmpty) 'fileType': fileType,
          if (fileSize != null && fileSize.isNotEmpty) 'fileSize': fileSize,
          if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
          'isMajorVersion': isMajorVersion,
        };
      }

      final response = await _dioClient.instance.post(
        '${ApiConstants.designs}/$parentId/revise',
        data: payload,
        onSendProgress: onSendProgress,
      );

      final data = response.data['data'] ?? response.data;
      final docMap = data['design'] as Map<String, dynamic>? ?? data;
      return DesignModel.fromJson(docMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve or request revision for a design with note
  Future<DesignModel> approveDesign({
    required String id,
    required String action, // APPROVE, REQUEST_REVISION
    String? note,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.designs}/$id/approve',
        data: {
          'action': action,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      final data = response.data['data'] ?? response.data;
      final docMap = data['design'] as Map<String, dynamic>? ?? data;
      return DesignModel.fromJson(docMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Signed Download Link
  Future<Map<String, dynamic>> downloadDesign(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.designs}/$id/download');
      final data = response.data['data'] ?? response.data;
      return {
        'downloadUrl': data['downloadUrl'] ?? '',
        'fileName': data['fileName'] ?? '',
        'expiresAt': data['expiresAt'] ?? '',
      };
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
