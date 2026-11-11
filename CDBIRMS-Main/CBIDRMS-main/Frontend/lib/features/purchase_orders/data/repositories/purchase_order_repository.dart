import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/purchase_order_model.dart';

class PurchaseOrderRepository {
  final DioClient _dioClient;

  PurchaseOrderRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<PurchaseOrderModel>> getPurchaseOrders({String? status, int? vendorId, String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      if (vendorId != null) {
        queryParams['vendorId'] = vendorId;
      }
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['projectId'] = projectId;
      }

      final response = await _dioClient.instance.get(
        ApiConstants.purchaseOrders,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? {};
      final List list = data['purchaseOrders'] ?? [];
      return list.map((json) => PurchaseOrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseOrderModel> getPurchaseOrderById(String id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.purchaseOrders}/$id');
      final data = response.data['data'] ?? {};
      final poJson = data['purchaseOrder'] as Map<String, dynamic>;
      return PurchaseOrderModel.fromJson(poJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseOrderModel> createPurchaseOrder({
    required int vendorId,
    required String projectId,
    String? boqId,
    String? date,
    required List<PoItemModel> items,
  }) async {
    try {
      final payload = {
        'vendorId': vendorId,
        'projectId': projectId,
        if (boqId != null && boqId.isNotEmpty) 'boqId': boqId,
        if (date != null && date.isNotEmpty) 'date': date,
        'items': items.map((i) => i.toJson()).toList(),
      };

      final response = await _dioClient.instance.post(
        ApiConstants.purchaseOrders,
        data: payload,
      );
      final data = response.data['data'] ?? {};
      final poJson = data['purchaseOrder'] as Map<String, dynamic>;
      return PurchaseOrderModel.fromJson(poJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseOrderModel> updatePurchaseOrderItems({
    required String id,
    required List<PoItemModel> items,
  }) async {
    try {
      final payload = {
        'items': items.map((i) => i.toJson()).toList(),
      };

      final response = await _dioClient.instance.put(
        '${ApiConstants.purchaseOrders}/$id',
        data: payload,
      );
      final data = response.data['data'] ?? {};
      final poJson = data['purchaseOrder'] as Map<String, dynamic>;
      return PurchaseOrderModel.fromJson(poJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseOrderModel> updatePurchaseOrderStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.purchaseOrders}/$id/status',
        data: {'status': status},
      );
      final data = response.data['data'] ?? {};
      final poJson = data['purchaseOrder'] as Map<String, dynamic>;
      return PurchaseOrderModel.fromJson(poJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    try {
      await _dioClient.instance.delete('${ApiConstants.purchaseOrders}/$id');
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
