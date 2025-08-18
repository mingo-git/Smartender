import 'dart:async';
import 'package:flutter/foundation.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';
import '../models/websocket/websocket_message.dart';

class FetchdData extends ChangeNotifier {
  // Singleton-Implementierung
  static final FetchdData _instance = FetchdData._internal();

  factory FetchdData() {
    return _instance;
  }

  FetchdData._internal() {
    _initializeWebSocketIntegration();
  }

  final List<FetchableService> _services = [];
  final WebSocketService _webSocketService = WebSocketService();

  Timer? _pollingTimer;
  bool _isFetching = false; // Flag, um doppelte Abrufe zu verhindern

  // WebSocket-aware polling configuration
  Duration _basePollingInterval = const Duration(seconds: 60);
  Duration _fastPollingInterval = const Duration(seconds: 15);
  Duration _currentPollingInterval = const Duration(seconds: 60);

  // Connection status tracking
  WebSocketConnectionStatus _lastWebSocketStatus = WebSocketConnectionStatus.disconnected;
  DateTime _lastWebSocketUpdate = DateTime.now();
  DateTime _lastHttpFetch = DateTime.now();

  // Polling strategy flags
  bool _isWebSocketEnabled = false;
  bool _useAdaptivePolling = true;

  /// Initialize WebSocket integration
  void _initializeWebSocketIntegration() {
    // Listen to WebSocket status changes
    _webSocketService.addListener(_onWebSocketStatusChanged);
    print("FetchdData: WebSocket integration initialized");
  }

  /// Handle WebSocket status changes
  void _onWebSocketStatusChanged() {
    final currentStatus = _webSocketService.statusInfo.status;

    if (currentStatus != _lastWebSocketStatus) {
      print("FetchdData: WebSocket status changed from ${_lastWebSocketStatus.name} to ${currentStatus.name}");
      _lastWebSocketStatus = currentStatus;

      if (_useAdaptivePolling) {
        _adjustPollingStrategy();
      }

      // If WebSocket just connected, do a quick sync
      if (currentStatus == WebSocketConnectionStatus.connected) {
        _onWebSocketConnected();
      }

      // If WebSocket disconnected, increase polling frequency
      if (currentStatus == WebSocketConnectionStatus.disconnected ||
          currentStatus == WebSocketConnectionStatus.error) {
        _onWebSocketDisconnected();
      }
    }
  }

  /// Handle WebSocket connection established
  void _onWebSocketConnected() async {
    print("FetchdData: WebSocket connected - performing initial sync");
    _lastWebSocketUpdate = DateTime.now();

    // Do a quick fetch to ensure we're in sync
    await fetchAllNow();
  }

  /// Handle WebSocket disconnection
  void _onWebSocketDisconnected() {
    print("FetchdData: WebSocket disconnected - increasing polling frequency");

    // Increase polling frequency to compensate for missing real-time updates
    if (_useAdaptivePolling) {
      _adjustPollingStrategy();
    }
  }

  /// Adjust polling strategy based on WebSocket status
  void _adjustPollingStrategy() {
    Duration newInterval;

    switch (_lastWebSocketStatus) {
      case WebSocketConnectionStatus.connected:
      // WebSocket is working - reduce polling frequency
        newInterval = _basePollingInterval;
        break;

      case WebSocketConnectionStatus.disconnected:
      case WebSocketConnectionStatus.error:
      // WebSocket is down - increase polling frequency
        newInterval = _fastPollingInterval;
        break;

      case WebSocketConnectionStatus.connecting:
      case WebSocketConnectionStatus.reconnecting:
      // WebSocket is trying to connect - moderate polling
        newInterval = Duration(seconds: (_basePollingInterval.inSeconds * 0.5).round());
        break;
    }

    if (newInterval != _currentPollingInterval) {
      _currentPollingInterval = newInterval;
      print("FetchdData: Adjusted polling interval to ${_currentPollingInterval.inSeconds} seconds");

      // Restart polling with new interval
      if (_pollingTimer?.isActive == true) {
        startPolling(interval: _currentPollingInterval);
      }
    }
  }

  /// Füge einen neuen Service hinzu, der regelmäßig abgefragt werden soll
  void addService(FetchableService service) {
    if (!_services.any((s) => s.runtimeType == service.runtimeType)) {
      _services.add(service);
      print("Service hinzugefügt: ${service.runtimeType}");
    } else {
      print("Service bereits registriert: ${service.runtimeType}");
    }
  }

  /// Starte das regelmäßige Abrufen der Daten
  void startPolling({Duration? interval}) {
    stopPolling(); // Beende eventuell laufendes Polling

    final pollingInterval = interval ?? _currentPollingInterval;
    _currentPollingInterval = pollingInterval;

    _pollingTimer = Timer.periodic(pollingInterval, (timer) {
      _performScheduledFetch();
    });

    print("Polling gestartet mit Intervall: ${pollingInterval.inSeconds} Sekunden");
    print("WebSocket Status: ${_webSocketService.connectionStatusText}");
  }

  /// Perform scheduled fetch with WebSocket awareness
  Future<void> _performScheduledFetch() async {
    // Skip fetch if WebSocket is providing real-time updates and we recently received updates
    if (_shouldSkipPolling()) {
      print("FetchdData: Skipping scheduled fetch - WebSocket is providing real-time updates");
      return;
    }

    await _fetchAllServices();
  }

  /// Determine if we should skip polling based on WebSocket status
  bool _shouldSkipPolling() {
    // Always fetch if WebSocket is not connected
    if (!_webSocketService.isConnected) {
      return false;
    }

    // Always fetch if it's been too long since last HTTP fetch (safety mechanism)
    final timeSinceLastHttpFetch = DateTime.now().difference(_lastHttpFetch);
    if (timeSinceLastHttpFetch > Duration(minutes: 5)) {
      print("FetchdData: Safety fetch - too long since last HTTP fetch");
      return false;
    }

    // Skip if WebSocket is connected and recently active
    final timeSinceLastWebSocketUpdate = DateTime.now().difference(_lastWebSocketUpdate);
    if (_webSocketService.isConnected && timeSinceLastWebSocketUpdate < Duration(seconds: 30)) {
      return true;
    }

    return false;
  }

  /// Stoppe das regelmäßige Abrufen
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("Polling gestoppt.");
  }

  /// Hole die Daten von allen registrierten Services
  Future<void> _fetchAllServices() async {
    if (_isFetching) {
      print("Abruf übersprungen: Ein Abruf läuft bereits.");
      return; // Kein Abruf starten, wenn einer bereits läuft
    }

    _isFetching = true; // Setze das Flag auf "läuft"
    _lastHttpFetch = DateTime.now();

    final fetchReason = _webSocketService.isConnected ? "Scheduled fetch (WebSocket connected)" : "HTTP fallback fetch";
    print("Datenabruf gestartet: $fetchReason");

    final servicesCopy = List<FetchableService>.from(_services);

    for (var service in servicesCopy) {
      try {
        await service.fetchAndSaveData();
        print("Daten von ${service.runtimeType} aktualisiert.");
      } catch (e) {
        print("Fehler beim Abrufen der Daten für ${service.runtimeType}: $e");
      }
    }

    _isFetching = false; // Abruf abgeschlossen
    notifyListeners(); // Optional: Benachrichtige Listener über Aktualisierungen
    print("Datenabruf abgeschlossen.");
  }

  /// Manuelles Abrufen aller Services (sofort)
  Future<void> fetchAllNow() async {
    print("FetchdData: Manual fetch requested");
    await _fetchAllServices();
  }

  /// Enable/Disable WebSocket integration
  void setWebSocketEnabled(bool enabled) {
    _isWebSocketEnabled = enabled;
    print("FetchdData: WebSocket integration ${enabled ? 'enabled' : 'disabled'}");

    if (enabled) {
      _webSocketService.connect();
    } else {
      _webSocketService.disconnect();
    }
  }

  /// Enable/Disable adaptive polling
  void setAdaptivePolling(bool enabled) {
    _useAdaptivePolling = enabled;
    print("FetchdData: Adaptive polling ${enabled ? 'enabled' : 'disabled'}");

    if (enabled) {
      _adjustPollingStrategy();
    }
  }

  /// Configure polling intervals
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

    if (_useAdaptivePolling) {
      _adjustPollingStrategy();
    }
  }

  /// Get current system status
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
    };
  }

  /// Force a refresh regardless of WebSocket status
  Future<void> forceRefresh() async {
    print("FetchdData: Force refresh requested - ignoring WebSocket status");
    _isFetching = false; // Reset flag
    await _fetchAllServices();
  }

  /// Update last WebSocket activity timestamp (called by services when they receive WebSocket updates)
  void notifyWebSocketActivity() {
    _lastWebSocketUpdate = DateTime.now();
  }

  /// Get polling efficiency stats
  Map<String, dynamic> getPollingStats() {
    final now = DateTime.now();
    final timeSinceLastHttp = now.difference(_lastHttpFetch);
    final timeSinceLastWebSocket = now.difference(_lastWebSocketUpdate);

    return {
      'minutes_since_last_http_fetch': timeSinceLastHttp.inMinutes,
      'seconds_since_last_websocket_update': timeSinceLastWebSocket.inSeconds,
      'polling_efficiency': _webSocketService.isConnected ? 'high' : 'standard',
      'data_freshness': timeSinceLastWebSocket.inSeconds < 60 ? 'fresh' : 'stale',
    };
  }

  /// Debugging: Liste aller registrierten Services anzeigen
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
    _webSocketService.removeListener(_onWebSocketStatusChanged);
    super.dispose();
  }
}