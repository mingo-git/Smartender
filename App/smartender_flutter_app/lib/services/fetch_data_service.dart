// lib/services/fetch_data_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart' as wssvc;
import '../models/websocket/websocket_message.dart' as wsmsg;

/// Hinweis zur Architektur:
/// - WebSocket-First: Echtzeitdaten kommen über WS und werden von den Services lokal gespeichert.
/// - HTTP-Fallback: Läuft NUR, wenn WS ausfällt oder zu lange keine Updates kamen.
/// - Polling ist bewusst weniger aggressiv.
class FetchdData extends ChangeNotifier {
  // Singleton-Implementierung
  static final FetchdData _instance = FetchdData._internal();
  factory FetchdData() => _instance;

  FetchdData._internal() {
    _initializeWebSocketIntegration();
  }

  // Registrierbare Services (Legacy, für Abwärtskompatibilität beibehalten)
  final List<FetchableService> _services = [];

  // Infrastruktur
  final wssvc.WebSocketService _webSocketService = wssvc.WebSocketService();
  final AuthService _auth = AuthService();

  Timer? _pollingTimer;
  bool _isFetching = false; // Flag, um doppelte Abrufe zu verhindern

  // Polling-Konfiguration (weniger aggressiv)
  Duration _basePollingInterval = const Duration(minutes: 2); // vorher 60s
  Duration _fastPollingInterval = const Duration(seconds: 30); // vorher 15s
  Duration _currentPollingInterval = const Duration(minutes: 2);

  // "Stale"-Schwelle für WS (wenn länger keine Messages -> Fallback)
  static const Duration _staleWebSocketThreshold = Duration(minutes: 3);

  // "Safety"-Schwelle für HTTP-Fetch bei dauerhaft WS-Connect ohne Events
  static const Duration _safetyHttpThreshold = Duration(minutes: 10);

  // Connection status tracking
  wssvc.WebSocketConnectionStatus _lastWebSocketStatus =
      wssvc.WebSocketConnectionStatus.disconnected;
  DateTime _lastWebSocketUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastHttpFetch = DateTime.fromMillisecondsSinceEpoch(0);

  // Polling strategy flags
  bool _isWebSocketEnabled = false;
  bool _useAdaptivePolling = true;

  // ────────────────────────────────────────────────────────────────────────────
  // WebSocket-Integration
  // ────────────────────────────────────────────────────────────────────────────

  void _initializeWebSocketIntegration() {
    // Lausche auf Statusänderungen der WS-Verbindung
    _webSocketService.addListener(_onWebSocketStatusChanged);

    // Zusätzlich: Jede relevante WS-Message als Aktivität werten
    _webSocketService.addMessageHandler(wsmsg.WebSocketMessageType.recipeUpdate, _onAnyWebSocketMessage);
    _webSocketService.addMessageHandler(wsmsg.WebSocketMessageType.drinkUpdate, _onAnyWebSocketMessage);
    _webSocketService.addMessageHandler(wsmsg.WebSocketMessageType.slotUpdate, _onAnyWebSocketMessage);
    _webSocketService.addMessageHandler(wsmsg.WebSocketMessageType.favoriteUpdate, _onAnyWebSocketMessage);

    print("FetchdData: WebSocket integration initialized");
  }

  void _onAnyWebSocketMessage(wsmsg.WebSocketMessage _) {
    _lastWebSocketUpdate = DateTime.now();
  }

  void _onWebSocketStatusChanged() {
    final currentStatus = _webSocketService.statusInfo.status;

    if (currentStatus != _lastWebSocketStatus) {
      print(
          "FetchdData: WebSocket status changed from ${_lastWebSocketStatus.name} to ${currentStatus.name}");
      _lastWebSocketStatus = currentStatus;

      if (_useAdaptivePolling) {
        _adjustPollingStrategy();
      }

      if (currentStatus == wssvc.WebSocketConnectionStatus.connected) {
        _onWebSocketConnected();
      }

      if (currentStatus == wssvc.WebSocketConnectionStatus.disconnected ||
          currentStatus == wssvc.WebSocketConnectionStatus.error) {
        _onWebSocketDisconnected();
      }
    }
  }

  void _onWebSocketConnected() {
    print("FetchdData: WebSocket connected – WS-first aktiv, kein HTTP-Initial-Fetch.");
    _lastWebSocketUpdate = DateTime.now();
    // Kein fetchAllNow() mehr – HTTP nur bei Ausfall/Staleness.
  }

  void _onWebSocketDisconnected() {
    print("FetchdData: WebSocket disconnected – erhöhe Polling-Frequenz (HTTP-Fallback aktivierbar).");
    if (_useAdaptivePolling) {
      _adjustPollingStrategy();
    }
  }

  void _adjustPollingStrategy() {
    // Fix: initialisieren, um "must be assigned" zu vermeiden
    Duration newInterval = _currentPollingInterval;

    switch (_lastWebSocketStatus) {
      case wssvc.WebSocketConnectionStatus.connected:
      // WS läuft -> langsames Polling (nur Safety/Staleness)
        newInterval = _basePollingInterval;
        break;

      case wssvc.WebSocketConnectionStatus.disconnected:
      case wssvc.WebSocketConnectionStatus.error:
      // WS down -> schnelleres Polling als Fallback
        newInterval = _fastPollingInterval;
        break;

      case wssvc.WebSocketConnectionStatus.connecting:
      case wssvc.WebSocketConnectionStatus.reconnecting:
      // Moderate Polling während Verbindungsaufbau
        newInterval = Duration(seconds: (_basePollingInterval.inSeconds * 0.5).round());
        break;
    }

    if (newInterval != _currentPollingInterval) {
      _currentPollingInterval = newInterval;
      print("FetchdData: Adjusted polling interval to ${_currentPollingInterval.inSeconds} seconds");

      if (_pollingTimer?.isActive == true) {
        startPolling(interval: _currentPollingInterval);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Service-Registrierung (beibehalten für Kompatibilität)
  // ────────────────────────────────────────────────────────────────────────────

  void addService(FetchableService service) {
    if (!_services.any((s) => s.runtimeType == service.runtimeType)) {
      _services.add(service);
      print("Service hinzugefügt: ${service.runtimeType}");
    } else {
      print("Service bereits registriert: ${service.runtimeType}");
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Polling / Scheduling
  // ────────────────────────────────────────────────────────────────────────────

  void startPolling({Duration? interval}) {
    stopPolling(); // Beende eventuell laufendes Polling

    final pollingInterval = interval ?? _currentPollingInterval;
    _currentPollingInterval = pollingInterval;

    _pollingTimer = Timer.periodic(pollingInterval, (_) => _performScheduledFetch());

    print("Polling gestartet mit Intervall: ${pollingInterval.inSeconds} Sekunden");
    print("WebSocket Status: ${_webSocketService.connectionStatusText}");
  }

  Future<void> _performScheduledFetch() async {
    // Wenn WS verbunden & frisch -> kein HTTP-Polling
    if (_shouldSkipPollingCompletely()) {
      print("FetchdData: Skipping scheduled fetch – WebSocket liefert Echtzeit & ist frisch.");
      return;
    }

    // Ansonsten HTTP-Fallback (bei Ausfall oder zu lange keine WS-Events)
    await _httpFallbackFetchAll();
  }

  bool _shouldSkipPollingCompletely() {
    if (!_webSocketService.isConnected) return false;

    final now = DateTime.now();
    final sinceWs = now.difference(_lastWebSocketUpdate);

    // Frisch genug? -> kein Polling
    if (sinceWs <= _staleWebSocketThreshold) {
      return true;
    }

    // Safety-Fetch bei sehr langer Durststrecke trotz WS-Connect
    final sinceHttp = now.difference(_lastHttpFetch);
    if (sinceHttp > _safetyHttpThreshold) {
      print("FetchdData: Safety HTTP fetch nötig (WS connected, aber lange keine HTTP-Synchronisierung).");
      return false;
    }

    // Wenn nicht frisch genug, aber Safety noch nicht erreicht -> trotzdem Fallback zulassen
    return false;
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("Polling gestoppt.");
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HTTP-Fallback (Initial-Load / bei WS-Ausfall/Staleness)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _httpFallbackFetchAll() async {
    if (_isFetching) {
      print("Abruf übersprungen: Ein Abruf läuft bereits.");
      return;
    }

    _isFetching = true;
    final reason = _webSocketService.isConnected ? "Fallback (stale WS)" : "Fallback (WS down)";
    print("HTTP-Fallback gestartet: $reason");

    try {
      // 1) Slots zuerst (wichtig für 'missing'-Berechnung bei Rezepten)
      await _fallbackFetchSlots();

      // 2) Drinks (nur für UI-Auflistungen)
      await _fallbackFetchDrinks();

      // 3) Recipes + Favorites (inkl. Ingredients & 'missing'-Flags)
      await _fallbackFetchRecipes();
    } catch (e) {
      print("HTTP-Fallback-Fehler: $e");
    } finally {
      _isFetching = false;
      _lastHttpFetch = DateTime.now();
      notifyListeners();
      print("HTTP-Fallback abgeschlossen.");
    }
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await _auth.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fallbackFetchSlots() async {
    final headers = await _authHeaders();
    if (headers == null) {
      print("Slots-Fallback übersprungen: kein Token.");
      return;
    }

    // Fix 404: /api-Präfix ergänzen
    final url = Uri.parse("$baseUrl/api/user/hardware/2/slots");
    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final body = res.body.trim();
        final List<dynamic> slots = body.isEmpty
            ? <dynamic>[]
            : json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('slots', json.encode(slots));
        print("Fallback: SLOTS gespeichert (${slots.length}).");
      } else {
        print("Fallback: Slots-GET fehlgeschlagen: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("Fallback: Slots-GET Fehler: $e");
    }
  }

  Future<void> _fallbackFetchDrinks() async {
    final headers = await _authHeaders();
    if (headers == null) {
      print("Drinks-Fallback übersprungen: kein Token.");
      return;
    }

    // Fix 404: /api-Präfix ergänzen
    final url = Uri.parse("$baseUrl/api/user/hardware/2/drinks");
    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final body = res.body.trim();
        final List<dynamic> drinks = body.isEmpty
            ? <dynamic>[]
            : json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('drinks', json.encode(drinks));
        print("Fallback: DRINKS gespeichert (${drinks.length}).");
      } else {
        print("Fallback: Drinks-GET fehlgeschlagen: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("Fallback: Drinks-GET Fehler: $e");
    }
  }

  Future<void> _fallbackFetchRecipes() async {
    final headers = await _authHeaders();
    if (headers == null) {
      print("Recipes-Fallback übersprungen: kein Token.");
      return;
    }

    // Fix 404: /api-Präfix ergänzen
    final recipesUrl = Uri.parse("$baseUrl/api/user/hardware/2/recipes");
    final favoritesUrl = Uri.parse("$baseUrl/api/user/hardware/2/favorites");

    Map<String, dynamic> decoded = {'available': <dynamic>[], 'unavailable': <dynamic>[]};
    List<int> favoriteIds = [];

    try {
      // Favorites zuerst
      try {
        final favRes = await http.get(favoritesUrl, headers: headers);
        if (favRes.statusCode == 200) {
          final favBody = favRes.body.trim();
          favoriteIds = favBody.isEmpty
              ? <int>[]
              : List<int>.from(json.decode(utf8.decode(favRes.bodyBytes)));
        } else {
          print("Fallback: Favorites-GET fehlgeschlagen: ${favRes.statusCode} ${favRes.body}");
        }
      } catch (e) {
        print("Fallback: Favorites-GET Fehler: $e");
      }

      // Recipes
      final recRes = await http.get(recipesUrl, headers: headers);
      if (recRes.statusCode == 200) {
        final body = recRes.body.trim();
        if (body.isNotEmpty) {
          try {
            final data = json.decode(utf8.decode(recRes.bodyBytes));
            if (data is Map<String, dynamic>) {
              decoded = data;
            }
          } catch (e) {
            print("Fallback: Recipes-Decode Fehler: $e");
          }
        }
      } else {
        print("Fallback: Recipes-GET fehlgeschlagen: ${recRes.statusCode} ${recRes.body}");
        return;
      }

      // Slots aus Local Cache laden, um 'missing' zu berechnen
      final prefs = await SharedPreferences.getInstance();
      final slotsJson = prefs.getString('slots');
      final Set<int> slotDrinkIds = {};
      if (slotsJson != null) {
        try {
          final List<dynamic> slotList = json.decode(slotsJson);
          for (var slot in slotList) {
            if (slot is Map &&
                slot['drink'] != null &&
                slot['drink']['drink_id'] != null) {
              slotDrinkIds.add(slot['drink']['drink_id'] as int);
            }
          }
        } catch (e) {
          print("Fallback: Slots-Decode Fehler: $e");
        }
      }

      Map<String, dynamic> _transformBucket(List<dynamic>? bucket) {
        final list = (bucket ?? <dynamic>[])
            .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r as Map))
            .toList();

        for (final recipe in list) {
          final recipeId = recipe['recipe_id'] is int
              ? recipe['recipe_id']
              : int.tryParse('${recipe['recipe_id']}') ?? -1;

          recipe['is_favorite'] = favoriteIds.contains(recipeId);

          final ingredientsResponse = recipe['ingredientsResponse'] as List<dynamic>?;
          final existingIngredients = recipe['ingredients'] as List<dynamic>?;

          if (ingredientsResponse != null) {
            recipe['ingredients'] = ingredientsResponse.map((ing) {
              final int drinkId = ing['drink']?['drink_id'] ?? -1;
              final String drinkName = ing['drink']?['drink_name'] ?? "Unknown";
              final int quantityMl = ing['quantity_ml'] ?? 0;
              final bool isMissing = !slotDrinkIds.contains(drinkId);
              return {
                'drink_id': drinkId,
                'name': drinkName,
                'quantity_ml': quantityMl,
                'missing': isMissing,
              };
            }).toList();
          } else if (existingIngredients != null) {
            recipe['ingredients'] = existingIngredients.map((ing) {
              final int drinkId =
                  ing['drink_id'] ?? ing['drink']?['drink_id'] ?? -1;
              final String drinkName =
                  ing['name'] ?? ing['drink']?['drink_name'] ?? "Unknown";
              final int quantityMl =
                  ing['quantity_ml'] ?? ing['quantity'] ?? 0;
              final bool isMissing = !slotDrinkIds.contains(drinkId);
              return {
                'drink_id': drinkId,
                'name': drinkName,
                'quantity_ml': quantityMl,
                'missing': isMissing,
              };
            }).toList();
          } else {
            recipe['ingredients'] = <Map<String, dynamic>>[];
          }
        }

        return {'list': list};
      }

      final availableTransformed =
      _transformBucket(decoded['available'] as List<dynamic>?);
      final unavailableTransformed =
      _transformBucket(decoded['unavailable'] as List<dynamic>?);

      final finalMap = {
        'available': availableTransformed['list'],
        'unavailable': unavailableTransformed['list'],
      };

      await prefs.setString('recipes', json.encode(finalMap));
      print("Fallback: RECIPES gespeichert. "
          "Available: ${(finalMap['available'] as List).length}, "
          "Unavailable: ${(finalMap['unavailable'] as List).length}");
    } catch (e) {
      print("Fallback: Recipes-GET Fehler: $e");
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Legacy-/Kompatibilitätsmethoden (beibehalten)
  // ────────────────────────────────────────────────────────────────────────────

  /// Manuelles Abrufen aller Services (jetzt: HTTP-Fallback-Logik)
  Future<void> fetchAllNow() async {
    print("FetchdData: Manual fetch requested (HTTP Fallback).");
    await _httpFallbackFetchAll();
  }

  /// Früher: über alle registrierten Services iterieren.
  /// Jetzt: delegiert auf HTTP-Fallback, da die Services WebSocket-first sind.
  Future<void> _fetchAllServices() async {
    await _httpFallbackFetchAll();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Steuerung & Status
  // ────────────────────────────────────────────────────────────────────────────

  void setWebSocketEnabled(bool enabled) {
    _isWebSocketEnabled = enabled;
    print("FetchdData: WebSocket integration ${enabled ? 'enabled' : 'disabled'}");

    if (enabled) {
      _webSocketService.connect();
    } else {
      _webSocketService.disconnect();
    }
  }

  void setAdaptivePolling(bool enabled) {
    _useAdaptivePolling = enabled;
    print("FetchdData: Adaptive polling ${enabled ? 'enabled' : 'disabled'}");
    if (enabled) _adjustPollingStrategy();
  }

  void configurePollingIntervals({
    Duration? baseInterval,
    Duration? fastInterval,
  }) {
    if (baseInterval != null) {
      _basePollingInterval = baseInterval;
      print("FetchdData: Base polling interval set to ${baseInterval.inSeconds} seconds");
    }
    if (fastInterval != null) {
      _fastPollingInterval = fastInterval;
      print("FetchdData: Fast polling interval set to ${fastInterval.inSeconds} seconds");
    }
    if (_useAdaptivePolling) _adjustPollingStrategy();
  }

  Map<String, dynamic> getSystemStatus() {
    return {
      'websocket_status': _webSocketService.connectionStatusText,
      'websocket_connected': _webSocketService.isConnected,
      'polling_active': _pollingTimer?.isActive ?? false,
      'current_polling_interval_seconds': _currentPollingInterval.inSeconds,
      'base_polling_interval_seconds': _basePollingInterval.inSeconds,
      'fast_polling_interval_seconds': _fastPollingInterval.inSeconds,
      'adaptive_polling_enabled': _useAdaptivePolling,
      'websocket_enabled': _isWebSocketEnabled,
      'last_http_fetch': _lastHttpFetch.toIso8601String(),
      'last_websocket_update': _lastWebSocketUpdate.toIso8601String(),
      'currently_fetching': _isFetching,
      'registered_services': _services.length,
      'services': _services.map((s) => s.runtimeType.toString()).toList(),
      'stale_ws_threshold_seconds': _staleWebSocketThreshold.inSeconds,
      'safety_http_threshold_minutes': _safetyHttpThreshold.inMinutes,
    };
  }

  Future<void> forceRefresh() async {
    print("FetchdData: Force refresh requested – HTTP-Fallback wird ausgeführt.");
    _isFetching = false; // Reset
    await _httpFallbackFetchAll();
  }

  /// Kann von Services aufgerufen werden, wenn sie WS-Events verarbeitet haben.
  void notifyWebSocketActivity() {
    _lastWebSocketUpdate = DateTime.now();
  }

  Map<String, dynamic> getPollingStats() {
    final now = DateTime.now();
    final timeSinceLastHttp = now.difference(_lastHttpFetch);
    final timeSinceLastWebSocket = now.difference(_lastWebSocketUpdate);

    return {
      'minutes_since_last_http_fetch': timeSinceLastHttp.inMinutes,
      'seconds_since_last_websocket_update': timeSinceLastWebSocket.inSeconds,
      'polling_efficiency': _webSocketService.isConnected ? 'high' : 'standard',
      'data_freshness': timeSinceLastWebSocket <= _staleWebSocketThreshold ? 'fresh' : 'stale',
    };
  }

  void debugServices() {
    print("Registrierte Services:");
    for (var service in _services) {
      print("- ${service.runtimeType}");
    }

    print("\nSystem Status:");
    final status = getSystemStatus();
    status.forEach((key, value) {
      print("- $key: $value");
    });
  }

  @override
  void dispose() {
    stopPolling();

    // Listener entfernen
    _webSocketService.removeListener(_onWebSocketStatusChanged);
    _webSocketService.removeMessageHandler(wsmsg.WebSocketMessageType.recipeUpdate, _onAnyWebSocketMessage);
    _webSocketService.removeMessageHandler(wsmsg.WebSocketMessageType.drinkUpdate, _onAnyWebSocketMessage);
    _webSocketService.removeMessageHandler(wsmsg.WebSocketMessageType.slotUpdate, _onAnyWebSocketMessage);
    _webSocketService.removeMessageHandler(wsmsg.WebSocketMessageType.favoriteUpdate, _onAnyWebSocketMessage);

    super.dispose();
  }
}
