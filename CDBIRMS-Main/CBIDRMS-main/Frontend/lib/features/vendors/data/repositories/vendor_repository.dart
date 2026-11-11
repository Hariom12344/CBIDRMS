import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/vendor_model.dart';

class VendorRepository {
  final DioClient _dioClient;

  VendorRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  /// Get Vendors List (with pagination and search)
  Future<Map<String, dynamic>> getVendors({String? search, int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.instance.get(
        ApiConstants.vendors,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'] ?? response.data;
      final rawList = data['vendors'] as List? ?? [];
      final vendors = rawList.map((e) => VendorModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'vendors': vendors,
        'total': data['total'] ?? vendors.length,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Vendor by ID (returns vendor record + linked purchase orders list)
  Future<Map<String, dynamic>> getVendorById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.vendors}/$id');
      final data = response.data['data'] ?? response.data;
      final vendorMap = data['vendor'] as Map<String, dynamic>? ?? {};
      final vendor = VendorModel.fromJson(vendorMap);
      final purchaseOrders = data['purchaseOrders'] as List? ?? [];

      return {
        'vendor': vendor,
        'purchaseOrders': purchaseOrders,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create Vendor
  Future<VendorModel> createVendor({
    required String companyName,
    required String contactPerson,
    required String email,
    required String phone,
    List<String>? materialsSupplied,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.vendors,
        data: {
          'companyName': companyName,
          'contactPerson': contactPerson,
          'email': email,
          'phone': phone,
          if (materialsSupplied != null) 'materialsSupplied': materialsSupplied,
        },
      );
      final data = response.data['data'] ?? response.data;
      return VendorModel.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update Vendor
  Future<VendorModel> updateVendor(
    String id, {
    required String companyName,
    required String contactPerson,
    required String email,
    required String phone,
    List<String>? materialsSupplied,
  }) async {
    try {
      final response = await _dioClient.instance.put(
        '${ApiConstants.vendors}/$id',
        data: {
          'companyName': companyName,
          'contactPerson': contactPerson,
          'email': email,
          'phone': phone,
          if (materialsSupplied != null) 'materialsSupplied': materialsSupplied,
        },
      );
      final data = response.data['data'] ?? response.data;
      return VendorModel.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['message'] ?? map['error'] ?? 'An error occurred';
    }
    return 'Connection error. Please check your backend.';
  }
}
