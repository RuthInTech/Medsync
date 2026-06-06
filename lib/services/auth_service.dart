import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'siyaphila_token';
  static const _roleKey = 'siyaphila_role';
  static const _userIdKey = 'siyaphila_user_id';
  static const _onboardedKey = 'siyaphila_onboarded';

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }
  Future<bool> isOnboarded() async {
    final val = await _storage.read(key: _onboardedKey);
    return val == 'true';
  }

  Future<AuthResult> login(String email, String password) async {
    final api = ApiService();
    final data = await api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _saveAndReturn(data);
  }

  Future<AuthResult> register(
      String email, String password, String name, String role) async {
    final api = ApiService();
    final data = await api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
    return _saveAndReturn(data);
  }

  Future<void> setOnboarded() async {
    await _storage.write(key: _onboardedKey, value: 'true');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<AuthResult> _saveAndReturn(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final role = data['role'] as String;
    final userId = data['user_id'] as int;
    final onboarded = data['is_onboarded'] as bool? ?? false;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _onboardedKey, value: onboarded.toString());

    return AuthResult(token: token, role: role, userId: userId, isOnboarded: onboarded);
  }
}

class AuthResult {
  final String token;
  final String role;
  final int userId;
  final bool isOnboarded;

  const AuthResult({
    required this.token,
    required this.role,
    required this.userId,
    required this.isOnboarded,
  });
}
