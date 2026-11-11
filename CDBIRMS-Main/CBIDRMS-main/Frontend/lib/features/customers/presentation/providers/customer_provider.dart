import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/models/customer_model.dart';

class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int total;
  final int page;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.total = 0,
    this.page = 1,
  });

  CustomerState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? total,
    int? page,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      total: total ?? this.total,
      page: page ?? this.page,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repository = CustomerRepository();
  Timer? _debounceTimer;

  CustomerNotifier() : super(CustomerState()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final query = search ?? state.searchQuery;
      final result = await _repository.getCustomers(search: query);
      state = state.copyWith(
        customers: result['customers'] as List<CustomerModel>,
        total: result['total'] as int,
        page: result['page'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchCustomers(search: query);
    });
  }

  Future<bool> addCustomer(
    BuildContext context, {
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newCustomer = await _repository.createCustomer(
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      state = state.copyWith(
        customers: [newCustomer, ...state.customers],
        total: state.total + 1,
        isLoading: false,
      );
      if (context.mounted) {
        _showSnackBar(context, 'Customer added successfully!');
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  Future<bool> updateCustomer(
    BuildContext context,
    String id, {
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedCustomer = await _repository.updateCustomer(
        id,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );

      final updatedList = state.customers.map((c) => c.id == id ? updatedCustomer : c).toList();

      state = state.copyWith(
        customers: updatedList,
        isLoading: false,
      );

      if (context.mounted) {
        _showSnackBar(context, 'Customer updated successfully!');
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier();
});
