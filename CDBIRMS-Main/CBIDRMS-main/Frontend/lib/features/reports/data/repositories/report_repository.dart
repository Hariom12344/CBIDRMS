import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/report_model.dart';

class ReportRepository {
  final DioClient _dioClient;

  ReportRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  /// Generate Executive Report for specified type
  Future<ReportModel> generateReport({
    required String type,
    required String from,
    required String to,
    String? projectId,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.reportsGenerate}/${type.toLowerCase()}/generate',
        data: {
          'from': from,
          'to': to,
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        },
      );

      final data = response.data['data'] ?? response.data;
      final reportMap = data['report'] as Map<String, dynamic>? ?? data;
      return ReportModel.fromJson(reportMap);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Report Generation History
  Future<List<ReportModel>> getReportHistory({String? type}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.reportsHistory,
        queryParameters: {
          if (type != null && type.isNotEmpty && type != 'ALL') 'type': type,
        },
      );

      final data = response.data['data'] ?? response.data;
      final rawList = data['reports'] as List? ?? [];
      return rawList.map((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
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
