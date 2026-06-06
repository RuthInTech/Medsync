import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://siyaphila-api.onrender.com';

  // ignore: prefer_initializing_formals
  final String? _token;

  const ApiService({String? token}) : _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException.fromResponse(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw ApiException.fromMap(response.statusCode, body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  factory ApiException.fromResponse(http.Response r) {
    try {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      return ApiException.fromMap(r.statusCode, body);
    } catch (_) {
      return ApiException(r.statusCode, r.reasonPhrase ?? 'Unknown error');
    }
  }

  factory ApiException.fromMap(int code, Map<String, dynamic> body) {
    final detail = body['detail'];
    final message = detail is String ? detail : detail?.toString() ?? 'Unknown error';
    return ApiException(code, message);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
