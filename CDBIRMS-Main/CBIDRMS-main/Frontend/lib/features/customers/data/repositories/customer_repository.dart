import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/customer_model.dart';

class CustomerRepository {
  final DioClient _dioClient;

  CustomerRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Get Customers List (with pagination and search)
  Future<Map<String, dynamic>> getCustomers({String? search, int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.customers,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'] ?? response.data;
      final rawList = data['customers'] as List? ?? [];
      final customers = rawList.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'customers': customers,
        'total': data['total'] ?? customers.length,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Customer by ID
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.customers}/$id');
      final data = response.data['data'] ?? response.data;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create Customer
  Future<CustomerModel> createCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? companyName,
    String? gstin,
    String? contactPerson,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.customers,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          if (companyName != null) 'companyName': companyName,
          if (gstin != null) 'gstin': gstin,
          if (contactPerson != null) 'contactPerson': contactPerson,
        },
      );
      final data = response.data['data'] ?? response.data;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Customer
  Future<CustomerModel> updateCustomer(
    String id, {
    required String name,
    required String email,
    required String phone,
    required String address,
    String? companyName,
    String? gstin,
    String? contactPerson,
  }) async {
    try {
      final response = await _dioClient.instance.put(
        '${ApiConstants.customers}/$id',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          if (companyName != null) 'companyName': companyName,
          if (gstin != null) 'gstin': gstin,
          if (contactPerson != null) 'contactPerson': contactPerson,
        },
      );
      final data = response.data['data'] ?? response.data;
      return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['message'] ?? map['error'] ?? 'An error occurred';
    }
    return 'Connection error. Please check backend network connection.';
  }
}
