import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AuthService {
  // Singleton pattern (optional but recommended)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = baseUrl; // Use your base URL from constants.dart
  final String _serviceUrl = '/auth';

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl$_serviceUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: json.encode({'username': username, 'password': password, 'email': email}),
      );
      print(response.statusCode);

      if (response.statusCode == 201) {
        // Registration successful
        return {'success': true};
      } else if (response.statusCode == 400) {
        // Handle specific error if registration data is invalid
        return {'success': false, 'error': 'Invalid registration data. Please check the entered information.'};
      } else if (response.statusCode == 409) {
        // Conflict error, e.g., username or email already taken
        return {'success': false, 'error': 'Username or email already exists. Please use a different one.'};
      } else {
        // Handle other server-related errors
        return {'success': false, 'error': 'Server error during registration. Please try again later.'};
      }
    } catch (e) {
      // Handle network or exception errors
      print(e);
      return {'success': false, 'error': 'Network error occurred. Please check your connection.'};
    }
  }

  /// Signs in the user with [emailOrUsername] and [password].
  /// Returns a map with `success` and an optional `error` message.
  Future<Map<String, dynamic>> signIn(String emailOrUsername, String password) async {
    final url = Uri.parse('$_baseUrl$_serviceUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: json.encode({'username': emailOrUsername, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract and store the access token
        final token = data['token'];
        await saveToken(token);
        return {'success': true};
      } else if (response.statusCode == 401) {
        // Invalid login credentials
        return {'success': false, 'error': 'Invalid username or password.'};
      } else if (response.statusCode == 500) {
        // Server error during login
        return {'success': false, 'error': 'Server error. Please try again later.'};
      } else {
        // Handle other unexpected errors
        return {'success': false, 'error': 'Unexpected error occurred.'};
      }
    } catch (e) {
      // Network or exception error
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  /// Securely saves the access token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  /// Retrieves the stored access token.
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Signs out the user and clears stored tokens.
  Future<void> signOut() async {
    await _storage.delete(key: 'jwt_token');
  }
}
