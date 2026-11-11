import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements IUserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl({UserRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? UserRemoteDataSource();

  @override
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
  }) {
    return _remoteDataSource.getUsers(
      page: page,
      limit: limit,
      search: search,
      role: role,
    );
  }

  @override
  Future<UserEntity> getUserById(int id) {
    return _remoteDataSource.getUserById(id);
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) {
    return _remoteDataSource.createUser(
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
    );
  }

  @override
  Future<UserEntity> updateUser(
    int id, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
  }) {
    return _remoteDataSource.updateUser(
      id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
    );
  }

  @override
  Future<UserEntity> updateUserStatus(int id, bool isActive) {
    return _remoteDataSource.updateUserStatus(id, isActive);
  }

  @override
  Future<void> deleteUser(int id) {
    return _remoteDataSource.deleteUser(id);
  }
}
