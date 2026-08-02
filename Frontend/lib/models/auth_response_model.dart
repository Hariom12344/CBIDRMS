import 'user_model.dart';

class AuthResponseModel {
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  AuthResponseModel({
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return AuthResponseModel(
      message: json['message'] ?? 'Request processed successfully',
      accessToken: data['accessToken'] ?? json['accessToken'],
      refreshToken: data['refreshToken'] ?? json['refreshToken'],
      user: data['user'] != null 
          ? UserModel.fromJson(data['user']) 
          : (json['user'] != null ? UserModel.fromJson(json['user']) : null),
    );
  }
}
