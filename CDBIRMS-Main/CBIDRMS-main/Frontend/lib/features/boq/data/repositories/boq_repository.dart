import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/boq_model.dart';

class BoqRepository {
  final DioClient _dioClient;

  BoqRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<BoqModel>> getBoqs({String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['projectId'] = projectId;
      }

      final response = await _dioClient.instance.get(
        ApiConstants.boq,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? {};
      final List list = data['boqs'] ?? [];
      return list.map((json) => BoqModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BoqModel> getBoqById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.boq}/$id');
      final data = response.data['data'] ?? {};
      final boqJson = data['boq'] as Map<String, dynamic>;
      return BoqModel.fromJson(boqJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BoqModel> createBoq({
    required String projectId,
    required List<BoqItemModel> items,
  }) async {
    try {
      final payload = {
        'projectId': projectId,
        'items': items.map((i) => i.toJson()).toList(),
      };
      final response = await _dioClient.instance.post(
        ApiConstants.boq,
        data: payload,
      );
      final data = response.data['data'] ?? {};
      final boqJson = data['boq'] as Map<String, dynamic>;
      return BoqModel.fromJson(boqJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BoqModel> updateBoq({
    required String id,
    required List<BoqItemModel> items,
  }) async {
    try {
      final payload = {
        'items': items.map((i) => i.toJson()).toList(),
      };
      final response = await _dioClient.instance.put(
        '${ApiConstants.boq}/$id',
        data: payload,
      );
      final data = response.data['data'] ?? {};
      final boqJson = data['boq'] as Map<String, dynamic>;
      return BoqModel.fromJson(boqJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBoq(String id) async {
    try {
      await _dioClient.instance.delete('${ApiConstants.boq}/$id');
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
