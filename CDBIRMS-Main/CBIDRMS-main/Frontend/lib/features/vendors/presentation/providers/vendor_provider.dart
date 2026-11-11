import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../domain/models/vendor_model.dart';

class VendorState {
  final List<VendorModel> vendors;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int total;
  final int page;

  VendorState({
    this.vendors = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.total = 0,
    this.page = 1,
  });

  VendorState copyWith({
    List<VendorModel>? vendors,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? total,
    int? page,
  }) {
    return VendorState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      total: total ?? this.total,
      page: page ?? this.page,
    );
  }
}

class VendorNotifier extends StateNotifier<VendorState> {
  final VendorRepository _repository = VendorRepository();
  Timer? _debounceTimer;

  VendorNotifier() : super(VendorState()) {
    fetchVendors();
  }

  Future<void> fetchVendors({String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final query = search ?? state.searchQuery;
      final result = await _repository.getVendors(search: query);
      state = state.copyWith(
        vendors: result['vendors'] as List<VendorModel>,
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
      fetchVendors(search: query);
    });
  }

  Future<VendorModel?> addVendor(
    BuildContext context, {
    required String companyName,
    required String contactPerson,
    required String email,
    required String phone,
    List<String>? materialsSupplied,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newVendor = await _repository.createVendor(
        companyName: companyName,
        contactPerson: contactPerson,
        email: email,
        phone: phone,
        materialsSupplied: materialsSupplied,
      );
      state = state.copyWith(
        vendors: [newVendor, ...state.vendors],
        total: state.total + 1,
        isLoading: false,
      );
      if (context.mounted) {
        _showSnackBar(context, 'Vendor registered successfully!');
      }
      return newVendor;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return null;
    }
  }

  Future<VendorModel?> updateVendor(
    BuildContext context,
    String id, {
    required String companyName,
    required String contactPerson,
    required String email,
    required String phone,
    List<String>? materialsSupplied,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedVendor = await _repository.updateVendor(
        id,
        companyName: companyName,
        contactPerson: contactPerson,
        email: email,
        phone: phone,
        materialsSupplied: materialsSupplied,
      );

      final updatedList = state.vendors.map((v) => v.id == id ? updatedVendor : v).toList();

      state = state.copyWith(
        vendors: updatedList,
        isLoading: false,
      );

      if (context.mounted) {
        _showSnackBar(context, 'Vendor details updated successfully!');
      }
      return updatedVendor;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchVendorDetails(String id) async {
    try {
      return await _repository.getVendorById(id);
    } catch (e) {
      return null;
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

final vendorNotifierProvider = StateNotifierProvider<VendorNotifier, VendorState>((ref) {
  return VendorNotifier();
});
