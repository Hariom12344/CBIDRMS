import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/document_model.dart';

class DocumentRepository {
  final DioClient _dioClient;

  DocumentRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  /// Get Documents List (with optional filtering by projectId, search, category)
  Future<Map<String, dynamic>> getDocuments({
    String? projectId,
    String? search,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.documents,
        queryParameters: {
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'] ?? response.data;
      final rawList = data['documents'] as List? ?? [];
      final documents = rawList.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'documents': documents,
        'total': data['total'] ?? documents.length,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create / Upload Document (supports device file upload or metadata)
  Future<DocumentModel> createDocument({
    required String title,
    required String projectId,
    required String category,
    required String fileType,
    required String fileSize,
    String? fileUrl,
    PlatformFile? pickedFile,
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
        ApiConstants.documents,
        data: payload,
      );

      final data = response.data['data'] ?? response.data;
      final docMap = data['document'] as Map<String, dynamic>? ?? data;
      return DocumentModel.fromJson(docMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Signed Download Link
  Future<Map<String, dynamic>> downloadDocument(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.documents}/$id/download');
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

  /// Delete Document
  Future<void> deleteDocument(String id) async {
    try {
      await _dioClient.instance.delete('${ApiConstants.documents}/$id');
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
