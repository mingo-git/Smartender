import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smartender_flutter_app/services/fetch_data_service.dart';
import '../config/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
    );
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = baseUrl; // Use your base URL from constants.dart
  final String _serviceUrl = '/auth';
  late GoogleSignIn _googleSignIn; // Definiert als 'late', da sie im Konstruktor initialisiert wird

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
        return {'success': true};
      } else if (response.statusCode == 400) {
        return {'success': false, 'error': 'Invalid registration data. Please check the entered information.'};
      } else if (response.statusCode == 409) {
        return {'success': false, 'error': 'Username or email already exists. Please use a different one.'};
      } else {
        return {'success': false, 'error': 'Server error during registration. Please try again later.'};
      }
    } catch (e) {
      print(e);
      return {'success': false, 'error': 'Network error occurred. Please check your connection.'};
    }
  }

  Future<Map<String, dynamic>> signIn(String emailOrUsername, String password) async {
    final fetchData = FetchdData();
    final url = Uri.parse('$_baseUrl$_serviceUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: json.encode({'username': emailOrUsername, 'password': password}),
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        await saveToken(token);
        await fetchData.fetchAllNow();
        return {'success': true};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Invalid username or password.'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'error': 'Server error. Please try again later.'};
      } else {
        return {'success': false, 'error': 'Unexpected error occurred.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'jwt_token');
  }


  Future<Map<String, dynamic>> signInWithGoogle() async {
    final fetchData = FetchdData();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in aborted by user.'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final url = Uri.parse('$_baseUrl$_serviceUrl/google-login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: json.encode({'token': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        await saveToken(token);
        await fetchData.fetchAllNow();
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed. Please try again.'};
    }
  }

  //TODO: Don´t work - Actually not nessasary!!!
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final url = Uri.parse('$_baseUrl$_serviceUrl/apple-login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: json.encode({'token': appleCredential.identityToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        await saveToken(token);
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Apple sign-in failed. Please try again.'};
    }
  }
}
