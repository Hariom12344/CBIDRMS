import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/trend_model.dart';

class AnalyticsRepository {
  final DioClient _dioClient;

  AnalyticsRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<TrendSeriesModel>> getTrends({
    required String from,
    required String to,
    List<String>? metrics,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'from': from,
        'to': to,
      };

      if (metrics != null && metrics.isNotEmpty) {
        queryParams['metrics'] = metrics.join(',');
      }

      final response = await _dioClient.instance.get(
        ApiConstants.analyticsTrends,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? response.data;
      final rawSeries = data['series'] as List? ?? [];

      return rawSeries.map((e) => TrendSeriesModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw 'No analytics data available for your role or date range.';
      }
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to fetch analytics trends';
      throw msg;
    } catch (e) {
      throw 'Failed to load analytics trends: $e';
    }
  }
}
