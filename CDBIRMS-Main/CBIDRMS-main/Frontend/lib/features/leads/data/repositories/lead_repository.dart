import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/lead_model.dart';
import '../../../projects/domain/models/project_model.dart';

import '../../../customers/domain/models/customer_model.dart';

class LeadRepository {
  final DioClient _dioClient;

  LeadRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Get all leads (with optional status filter)
  Future<List<LeadModel>> getLeads({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      final response = await _dioClient.instance.get(
        ApiConstants.leads,
        queryParameters: queryParams,
      );
      final data = response.data['data'] ?? {};
      final List leadsJson = data['leads'] ?? [];
      return leadsJson.map((json) => LeadModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get single lead details
  Future<LeadModel> getLead(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.leads}/$id');
      final data = response.data['data'];
      return LeadModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create new lead
  Future<LeadModel> createLead({
    required String clientName,
    String? email,
    String? phone,
    String? propertyType,
    double? estimatedBudget,
    String? assignedTo,
  }) async {
    try {
      final payload = {
        'clientName': clientName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (propertyType != null && propertyType.isNotEmpty) 'propertyType': propertyType,
        if (estimatedBudget != null) 'estimatedBudget': estimatedBudget,
        if (assignedTo != null && assignedTo.isNotEmpty) 'assignedTo': assignedTo,
      };

      final response = await _dioClient.instance.post(
        ApiConstants.leads,
        data: payload,
      );
      final data = response.data['data'];
      return LeadModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update existing lead
  Future<LeadModel> updateLead(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.leads}/$id',
        data: updateData,
      );
      final data = response.data['data'];
      return LeadModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Convert lead to active Project
  Future<Map<String, dynamic>> convertToProject(String id) async {
    try {
      final response = await _dioClient.instance.post(
        '${ApiConstants.leads}/$id/convert',
      );
      final data = response.data['data'];
      return {
        'lead': LeadModel.fromJson(data['lead']),
        'project': ProjectModel.fromJson(data['project']),
        if (data['customer'] != null) 'customer': CustomerModel.fromJson(data['customer']),
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete lead
  Future<void> deleteLead(String id) async {
    try {
      await _dioClient.instance.delete('${ApiConstants.leads}/$id');
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
