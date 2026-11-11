import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../../data/repositories/user_repository_impl.dart';

class UserState {
  final List<UserEntity> users;
  final bool isLoading;
  final bool isSearching;
  final bool isSubmitting;
  final int? updatingUserId;
  final String searchQuery;
  final String roleFilter;
  final int page;
  final int total;
  final int limit;
  final String? errorMessage;
  final UserEntity? selectedUser;

  UserState({
    this.users = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isSubmitting = false,
    this.updatingUserId,
    this.searchQuery = '',
    this.roleFilter = '',
    this.page = 1,
    this.total = 0,
    this.limit = 20,
    this.errorMessage,
    this.selectedUser,
  });

  UserState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    bool? isSearching,
    bool? isSubmitting,
    int? updatingUserId,
    String? searchQuery,
    String? roleFilter,
    int? page,
    int? total,
    int? limit,
    String? errorMessage,
    UserEntity? selectedUser,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      updatingUserId: updatingUserId,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      page: page ?? this.page,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      errorMessage: errorMessage,
      selectedUser: selectedUser ?? this.selectedUser,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final IUserRepository _repository;

  UserNotifier({IUserRepository? repository})
      : _repository = repository ?? UserRepositoryImpl(),
        super(UserState()) {
    fetchUsers();
  }

  Future<void> fetchUsers({int? page, String? search, String? role, bool isInitialLoad = false}) async {
    if (isInitialLoad || state.users.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isSearching: true, errorMessage: null);
    }

    final pageNum = page ?? state.page;
    final searchVal = search ?? state.searchQuery;
    final roleVal = role ?? state.roleFilter;

    try {
      final res = await _repository.getUsers(
        page: pageNum,
        limit: state.limit,
        search: searchVal,
        role: roleVal,
      );

      state = state.copyWith(
        users: res['users'] as List<UserEntity>,
        total: res['total'] as int,
        page: pageNum,
        searchQuery: searchVal,
        roleFilter: roleVal,
        isLoading: false,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSearching: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setSearch(String query) async {
    await fetchUsers(page: 1, search: query);
  }

  Future<void> setRoleFilter(String role) async {
    await fetchUsers(page: 1, role: role);
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final res = await _repository.createUser(
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
      );

      state = state.copyWith(isSubmitting: false);
      await fetchUsers(isInitialLoad: true);
      return {'success': true, 'message': res['message'], 'user': res['user']};
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    int id, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final updatedUser = await _repository.updateUser(
        id,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
      );

      final updatedList = state.users.map((u) => u.id == id ? updatedUser : u).toList();
      state = state.copyWith(
        users: updatedList,
        selectedUser: updatedUser,
        isSubmitting: false,
      );
      return {'success': true, 'user': updatedUser};
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(int id, bool isActive) async {
    state = state.copyWith(updatingUserId: id, errorMessage: null);

    try {
      final updatedUser = await _repository.updateUserStatus(id, isActive);
      final updatedList = state.users.map((u) => u.id == id ? updatedUser : u).toList();
      state = state.copyWith(
        users: updatedList,
        selectedUser: state.selectedUser?.id == id ? updatedUser : state.selectedUser,
        updatingUserId: null,
      );
      return {'success': true, 'user': updatedUser};
    } catch (e) {
      state = state.copyWith(updatingUserId: null, errorMessage: e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    state = state.copyWith(updatingUserId: id, errorMessage: null);

    try {
      await _repository.deleteUser(id);
      final updatedList = state.users.where((u) => u.id != id).toList();
      state = state.copyWith(
        users: updatedList,
        selectedUser: state.selectedUser?.id == id ? null : state.selectedUser,
        updatingUserId: null,
        total: state.total - 1,
      );
      return {'success': true};
    } catch (e) {
      state = state.copyWith(updatingUserId: null, errorMessage: e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  void selectUser(UserEntity user) {
    state = state.copyWith(selectedUser: user);
  }
}

final userRepositoryProvider = Provider<IUserRepository>((ref) => UserRepositoryImpl());

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserNotifier(repository: repo);
});
