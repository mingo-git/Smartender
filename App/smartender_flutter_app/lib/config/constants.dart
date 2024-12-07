import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Stelle sicher, dass dotenv initialisiert ist, bevor du auf die Werte zugreifst
var baseUrl = dotenv.env['BASE_URL'] ?? 'no_base_url_found';
var apiKey = dotenv.env['API_KEY'] ?? 'no_api_key_found';
var googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? 'no_google_client_id_found';

// Farbe aus .env laden und in Color umwandeln
Color backgroundColor = Color(
  int.parse(dotenv.env['BACKGROUND_COLOR'] ?? '0xFFF2F2F2'), // Verwende '0xFF' für Deckkraft
);
