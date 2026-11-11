import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/quotation_model.dart';

class QuotationRepository {
  final DioClient _dioClient;

  QuotationRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<QuotationModel>> fetchQuotations({String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final response = await _dioClient.instance.get(
        ApiConstants.quotations,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? response.data;
      final list = data is List ? data : (data['quotations'] as List? ?? []);

      return list.map((item) => QuotationModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to fetch quotations';
      throw msg;
    } catch (e) {
      throw 'Failed to fetch quotations: $e';
    }
  }

  Future<QuotationModel> fetchQuotationById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.quotations}/$id');
      final data = response.data['data'] ?? response.data;
      final revisionsRaw = data['revisions'] as List<dynamic>?;
      return QuotationModel.fromJson(data as Map<String, dynamic>, revisionsRaw);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to fetch quotation details';
      throw msg;
    } catch (e) {
      throw 'Failed to fetch quotation details: $e';
    }
  }

  Future<QuotationModel> createQuotation(Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.quotations,
        data: payload,
      );
      final data = response.data['data'] ?? response.data;
      return QuotationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to create quotation';
      throw msg;
    } catch (e) {
      throw 'Failed to create quotation: $e';
    }
  }

  Future<QuotationModel> updateQuotation(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.instance.put(
        '${ApiConstants.quotations}/$id',
        data: payload,
      );
      final data = response.data['data'] ?? response.data;
      return QuotationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to update quotation';
      throw msg;
    } catch (e) {
      throw 'Failed to update quotation: $e';
    }
  }

  Future<QuotationModel> createRevision(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.quotations}/$id/revise',
        data: payload,
      );
      final data = response.data['data'] ?? response.data;
      return QuotationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to create revision';
      throw msg;
    } catch (e) {
      throw 'Failed to create revision: $e';
    }
  }

  Future<QuotationModel> duplicateQuotation(String id) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.quotations}/$id/duplicate',
      );
      final data = response.data['data'] ?? response.data;
      return QuotationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to duplicate quotation';
      throw msg;
    } catch (e) {
      throw 'Failed to duplicate quotation: $e';
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      await _dioClient.instance.delete('${ApiConstants.quotations}/$id');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to delete quotation';
      throw msg;
    } catch (e) {
      throw 'Failed to delete quotation: $e';
    }
  }

  Future<Map<String, dynamic>> shareQuotation(String id, String channel) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.quotations}/$id/share',
        data: {'channel': channel},
      );
      final data = response.data['data'] ?? response.data;
      return {
        'shareUrl': data['shareUrl'] ?? '',
        'quotation': QuotationModel.fromJson(data['quotation'] as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to share quotation';
      throw msg;
    } catch (e) {
      throw 'Failed to share quotation: $e';
    }
  }

  Future<Map<String, dynamic>> convertToProject(String id) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.quotations}/$id/convert',
      );
      final data = response.data['data'] ?? response.data;
      return {
        'project': data['project'],
        'quotation': QuotationModel.fromJson(data['quotation'] as Map<String, dynamic>),
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw 'This quotation has already been converted into a project';
      }
      final msg = e.response?.data?['message'] ?? e.message ?? 'Failed to convert quotation to project';
      throw msg;
    } catch (e) {
      throw 'Failed to convert quotation to project: $e';
    }
  }
}
