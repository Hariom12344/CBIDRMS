import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/user_model.dart';

class UserRepository {
  final DioClient _dioClient;

  UserRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // List users with pagination and search
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (role.trim().isNotEmpty) {
        queryParams['role'] = role.trim();
      }

      final response = await _dioClient.instance.get(
        ApiConstants.users,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final data = responseData['data'] ?? {};
      final List rawUsers = data['users'] ?? [];
      final users = rawUsers.map((json) => UserModel.fromJson(json)).toList();

      return {
        'users': users,
        'total': data['total'] ?? users.length,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user by ID
  Future<UserModel> getUserById(int id) async {
    try {
      final response = await _dioClient.instance.get('${ApiConstants.users}/$id');
      final data = response.data['data'] ?? {};
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create user
  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.users,
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': role,
        },
      );

      final data = response.data['data'] ?? {};
      final message = response.data['message'] ?? 'User created successfully';
      final createdUser = UserModel.fromJson(data['user'] ?? data);

      return {
        'message': message,
        'user': createdUser,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update user
  Future<UserModel> updateUser(
    int id, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
  }) async {
    try {
      final dataMap = <String, dynamic>{};
      if (fullName != null) dataMap['fullName'] = fullName;
      if (email != null) dataMap['email'] = email;
      if (phone != null) dataMap['phone'] = phone;
      if (role != null) dataMap['role'] = role;

      final response = await _dioClient.instance.put(
        '${ApiConstants.users}/$id',
        data: dataMap,
      );

      final data = response.data['data'] ?? {};
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update user active status
  Future<UserModel> updateUserStatus(int id, bool isActive) async {
    try {
      final response = await _dioClient.instance.patch(
        '${ApiConstants.users}/$id/status',
        data: {'isActive': isActive},
      );

      final data = response.data['data'] ?? {};
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final res = error.response!.data;
      if (res['error'] != null) {
        return '${res['error']}: ${res['message'] ?? "An error occurred"}';
      }
      if (res['message'] != null) {
        return res['message'].toString();
      }
    }
    return error.message ?? 'An unexpected network error occurred';
  }
}
