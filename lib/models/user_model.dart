class LoginResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? name;
  final bool isOldPass;

  LoginResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.name,
    this.isOldPass = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['access_token'],
      name: json['name'],
      isOldPass: json['is_old_pass'] == true || json['is_old_pass'] == 1,
    );
  }
}