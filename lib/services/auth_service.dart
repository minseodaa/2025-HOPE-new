import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthService {
  const AuthService();

  Future<SignupResult> signup({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.signupPath()}',
    );
    final Map<String, dynamic> payload = {'email': email, 'password': password};

    try {
      final http.Response response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return SignupResult.success(data);
      }

      String message =
          '회원가입 실패: HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}'
              .trim();
      try {
        final Map<String, dynamic> err = jsonDecode(response.body);
        if (err['message'] is String) message = err['message'];
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = '$message\n${response.body}';
        }
      }
      return SignupResult.failure(message);
    } catch (e) {
      return SignupResult.failure('네트워크 오류: ${e.runtimeType} - $e');
    }
  }
}

class SignupResult {
  final bool ok;
  final String? errorMessage;
  final dynamic data;

  SignupResult._(this.ok, this.errorMessage, this.data);

  factory SignupResult.success(dynamic data) =>
      SignupResult._(true, null, data);
  factory SignupResult.failure(String message) =>
      SignupResult._(false, message, null);
}
