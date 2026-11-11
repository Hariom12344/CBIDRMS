import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/purchase_order_repository.dart';
import '../../domain/models/purchase_order_model.dart';

class PurchaseOrderState {
  final List<PurchaseOrderModel> purchaseOrders;
  final bool isLoading;
  final String? errorMessage;
  final String selectedStatusFilter;

  PurchaseOrderState({
    this.purchaseOrders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatusFilter = 'All',
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrderModel>? purchaseOrders,
    bool? isLoading,
    String? errorMessage,
    String? selectedStatusFilter,
  }) {
    return PurchaseOrderState(
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
    );
  }
}

class PurchaseOrderNotifier extends StateNotifier<PurchaseOrderState> {
  final PurchaseOrderRepository _repository;

  PurchaseOrderNotifier(this._repository) : super(PurchaseOrderState()) {
    fetchPurchaseOrders();
  }

  Future<void> fetchPurchaseOrders({String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final activeFilter = status ?? state.selectedStatusFilter;
      final orders = await _repository.getPurchaseOrders(status: activeFilter);
      state = state.copyWith(
        purchaseOrders: orders,
        isLoading: false,
        selectedStatusFilter: activeFilter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<PurchaseOrderModel> getPurchaseOrderById(String id) async {
    return await _repository.getPurchaseOrderById(id);
  }

  Future<bool> createPurchaseOrder({
    required int vendorId,
    required String projectId,
    String? boqId,
    String? date,
    required List<PoItemModel> items,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createPurchaseOrder(
        vendorId: vendorId,
        projectId: projectId,
        boqId: boqId,
        date: date,
        items: items,
      );
      await fetchPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updatePurchaseOrderStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _repository.updatePurchaseOrderStatus(id: id, status: status);
      await fetchPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  void setFilter(String filter) {
    fetchPurchaseOrders(status: filter);
  }
}

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((ref) {
  return PurchaseOrderRepository();
});

final purchaseOrderNotifierProvider = StateNotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>((ref) {
  final repo = ref.watch(purchaseOrderRepositoryProvider);
  return PurchaseOrderNotifier(repo);
});
