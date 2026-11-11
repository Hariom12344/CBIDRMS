import '../entities/user_entity.dart';

abstract class IUserRepository {
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
  });

  Future<UserEntity> getUserById(int id);

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String role,
  });

  Future<UserEntity> updateUser(
    int id, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
  });

  Future<UserEntity> updateUserStatus(int id, bool isActive);

  Future<void> deleteUser(int id);
}
