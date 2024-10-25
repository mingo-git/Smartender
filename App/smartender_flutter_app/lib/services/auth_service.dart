import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/constants.dart';


class AuthService {
  // Singleton Pattern (optional, aber empfohlen)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = baseUrl; // Verwende deine BaseURL aus constants.dart

  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    print(url);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);


        return true;
      } else {
        // Fehlerbehandlung bei ungültigen Anmeldedaten
        return false;
      }
    } catch (e) {
      // Fehlerbehandlung bei Netzwerkfehlern oder Ausnahmen
      return false;
    }
  }


  /// Meldet den Benutzer mit [email] und [password] an.
  /// Gibt `true` zurück, wenn der Login erfolgreich war, sonst `false`.
  Future<bool> signIn(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extrahiere das Access Token (und Refresh Token, falls vorhanden)
        final token = data['token'];


        // Speichere die Tokens sicher
        await saveToken(token);

        return true;
      } else {
        // Fehlerbehandlung bei ungültigen Anmeldedaten
        return false;
      }
    } catch (e) {
      // Fehlerbehandlung bei Netzwerkfehlern oder Ausnahmen
      return false;
    }
  }

  /// Speichert das Access Token sicher.
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  /// Speichert das Refresh Token sicher.
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Ruft das gespeicherte Access Token ab.
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Überprüft, ob das Access Token gültig ist.
  /// Gibt `true` zurück, wenn das Token gültig ist, sonst `false`.
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) {
      return false;
    }
    return !JwtDecoder.isExpired(token);
  }

  /// Meldet den Benutzer ab und löscht gespeicherte Tokens.
  Future<void> signOut() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// Aktualisiert das Access Token mithilfe des Refresh Tokens.
  /// Gibt `true` zurück, wenn die Aktualisierung erfolgreich war, sonst `false`.
  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/refresh');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extrahiere die neuen Tokens
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        // Speichere die neuen Tokens
        await saveToken(newAccessToken);
        if (newRefreshToken != null) {
          await saveRefreshToken(newRefreshToken);
        }

        return true;
      } else {
        // Fehlerbehandlung bei fehlgeschlagener Token-Aktualisierung
        return false;
      }
    } catch (e) {
      // Fehlerbehandlung bei Netzwerkfehlern oder Ausnahmen
      return false;
    }
  }

  /// Führt eine authentifizierte GET-Anfrage an den angegebenen [endpoint] aus.
  /// Gibt die Antwort als `http.Response` zurück.
  Future<http.Response> getRequest(String endpoint) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl$endpoint');

    // Überprüfe die Gültigkeit des Tokens und aktualisiere es bei Bedarf
    if (!await isTokenValid()) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        // Token konnte nicht aktualisiert werden, Benutzer muss sich erneut anmelden
        throw Exception('Token abgelaufen');
      }
    }

    final updatedToken = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $updatedToken',
      },
    );

    return response;
  }

  /// Führt eine authentifizierte POST-Anfrage an den angegebenen [endpoint] mit [body] aus.
  /// Gibt die Antwort als `http.Response` zurück.
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl$endpoint');

    // Überprüfe die Gültigkeit des Tokens und aktualisiere es bei Bedarf
    if (!await isTokenValid()) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw Exception('Token abgelaufen');
      }
    }

    final updatedToken = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $updatedToken',
      },
      body: json.encode(body),
    );

    return response;
  }
}
