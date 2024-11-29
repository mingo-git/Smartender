import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Initialisierung der Variablen aus der .env-Datei
var baseUrl = dotenv.env['BASE_URL'] ?? 'no_base_url_found';
var apiKey = dotenv.env['API_KEY'] ?? 'no_api_key_found';
var googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? 'no_google_client_id_found';

// Feste Definition der Hintergrundfarbe, die aus der .env-Datei entfernt wird
Color backgroundColor = const Color(0xFFF2F2F2);  // Hex-Farbe für F2F2F2 mit voller Deckkraft

const double horizontalPadding = 10.0; // Neue Konstante für das horizontale Padding
final BorderRadius defaultBorderRadius = BorderRadius.circular(24.0); // Einheitlicher Radius für abgerundete Ecken


