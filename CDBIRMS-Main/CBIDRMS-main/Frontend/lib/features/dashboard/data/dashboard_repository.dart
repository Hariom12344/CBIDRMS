import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class ActivityItemModel {
  final int id;
  final String type;
  final String message;
  final String actorName;
  final String createdAt;

  ActivityItemModel({
    required this.id,
    required this.type,
    required this.message,
    required this.actorName,
    required this.createdAt,
  });

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'SYSTEM_EVENT',
      message: json['message']?.toString() ?? 'Activity recorded',
      actorName: json['actorName']?.toString() ?? 'System',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Fetch role-aware aggregate summary metrics
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _dioClient.instance.get(ApiConstants.dashboardSummary);
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch recent activity feed items
  Future<List<ActivityItemModel>> getActivities({int limit = 10}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.dashboardActivities,
        queryParameters: {'limit': limit},
      );
      final data = response.data['data'] ?? {};
      final List list = data['activities'] ?? [];
      return list.map((json) => ActivityItemModel.fromJson(json as Map<String, dynamic>)).toList();
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
