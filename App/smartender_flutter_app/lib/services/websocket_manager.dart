// lib/services/websocket_manager.dart - VERBESSERTE WEBSOCKET-VERWALTUNG

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/websocket/websocket_message.dart';
import '../config/constants.dart';
import 'auth_service.dart';

typedef WebSocketMessageHandler = void Function(WebSocketMessage message);

/// 🚀 WebSocket-Status
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
  failed,
}

/// 🎯 Verbesserte WebSocket-Verwaltung
/// - Automatische Reconnection
/// - Message-Routing
/// - Connection-Health-Monitoring
/// - Korrekte URL-Konstruktion
class WebSocketManager extends ChangeNotifier {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _healthCheckTimer;

  // Configuration
  final AuthService _authService = AuthService();

  // Status tracking
  WebSocketStatus _status = WebSocketStatus.disconnected;
  String? _lastError;
  DateTime _lastConnected = DateTime.now();
  DateTime _lastMessageReceived = DateTime.now();
  int _reconnectAttempts = 0;
  int _totalMessagesReceived = 0;
  bool _isOnline = true;

  // Configuration
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  static const Duration _connectionTimeout = Duration(seconds: 15);

  // Message handlers
  final Map<WebSocketMessageType, List<WebSocketMessageHandler>> _messageHandlers = {};

  // Getters
  WebSocketStatus get status => _status;
  bool get isConnected => _status == WebSocketStatus.connected;
  bool get isConnecting => _status == WebSocketStatus.connecting;
  bool get isReconnecting => _status == WebSocketStatus.reconnecting;
  String? get lastError => _lastError;
  DateTime get lastConnected => _lastConnected;
  DateTime get lastMessageReceived => _lastMessageReceived;
  int get reconnectAttempts => _reconnectAttempts;
  int get totalMessagesReceived => _totalMessagesReceived;
  bool get isHealthy => isConnected &&
      DateTime.now().difference(_lastMessageReceived).inMinutes < 5;

  /// 🚀 INITIALISIERUNG
  Future<void> initialize() async {
    print("🔌 WebSocket Manager initializing...");

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    // Start health monitoring
    _startHealthMonitoring();

    print("🔌 WebSocket Manager initialized");
  }

  /// 🚀 VERBINDUNG AUFBAUEN
  Future<void> connect() async {
    if (!_isOnline) {
      print("🔌 Cannot connect: No internet connection");
      _updateStatus(WebSocketStatus.error, "No internet connection");
      return;
    }

    if (isConnected) {
      print("🔌 Already connected");
      return;
    }

    if (isConnecting) {
      print("🔌 Already connecting");
      return;
    }

    await _connectInternal();
  }

  /// 🔧 INTERNE VERBINDUNGSMETHODE (URL-Problem gelöst)
  Future<void> _connectInternal() async {
    try {
      _updateStatus(WebSocketStatus.connecting);

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception("No authentication token available");
      }

      // 🔧 KORREKTE URL-KONSTRUKTION (löst das :0 Port Problem)
      print("🔧 === WEBSOCKET URL CONSTRUCTION ===");

      // Schritt 1: Host aus baseUrl extrahieren
      final baseHost = baseUrl
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .split('/')[0]; // Entferne Pfade falls vorhanden

      print("🔧 Original baseUrl: '$baseUrl'");
      print("🔧 Extracted host: '$baseHost'");

      // Schritt 2: WebSocket URL manuell konstruieren
      final wsUrl = 'wss://$baseHost/api/ws';
      print("🔧 WebSocket base URL: '$wsUrl'");

      // Schritt 3: Query Parameter hinzufügen
      final queryParams = {
        'token': token,
        'X-API-KEY': apiKey,
      };

      // Schritt 4: URI mit expliziter Konstruktion (KEIN Uri.parse!)
      final uri = Uri(
        scheme: 'wss',
        host: baseHost,
        path: '/api/ws',
        queryParameters: queryParams,
      );

      print("🔧 Final WebSocket URI: '${uri.toString()}'");
      print("🔧 URI host: '${uri.host}'");
      print("🔧 URI port: ${uri.port}");
      print("🔧 URI scheme: '${uri.scheme}'");
      print("🔧 === END WEBSOCKET URL CONSTRUCTION ===");

      print("🔌 Connecting to WebSocket...");

      // Connection mit Timeout
      final connectionCompleter = Completer<void>();
      Timer(_connectionTimeout, () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(TimeoutException("Connection timeout"));
        }
      });

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['smartender-v1'],
      );

      _messageSubscription = _channel!.stream.listen(
            (message) {
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete();
          }
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print("🔌 WebSocket error: $error");
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(error);
          }
          _handleConnectionError(error);
        },
        onDone: () {
          print("🔌 WebSocket connection closed");
          _handleConnectionClosed();
        },
      );

      // Warte auf erfolgreiche Verbindung
      await connectionCompleter.future;

      _updateStatus(WebSocketStatus.connected);
      _lastConnected = DateTime.now();
      _reconnectAttempts = 0;
      _startPingTimer();

      print("✅ WebSocket connected successfully!");

    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _updateStatus(WebSocketStatus.error, e.toString());
      _scheduleReconnect();
    }
  }

  /// 🚀 VERBINDUNG TRENNEN
  Future<void> disconnect() async {
    print("🔌 Disconnecting WebSocket...");

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _messageSubscription?.cancel();

    try {
      await _channel?.sink.close();
    } catch (e) {
      print("🔌 Error closing WebSocket: $e");
    }

    _channel = null;
    _updateStatus(WebSocketStatus.disconnected);
    print("🔌 WebSocket disconnected");
  }

  /// 📨 MESSAGE HANDLING

  /// Registriere Message Handler
  void addMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers.putIfAbsent(type, () => []).add(handler);
    print("📨 Added message handler for type: ${type.value}");
  }

  /// Entferne Message Handler
  void removeMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers[type]?.remove(handler);
    if (_messageHandlers[type]?.isEmpty == true) {
      _messageHandlers.remove(type);
    }
    print("📨 Removed message handler for type: ${type.value}");
  }

  /// Sende Message
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) {
      print("📨 Cannot send message: Not connected");
      return false;
    }

    try {
      final jsonMessage = json.encode(message);
      _channel?.sink.add(jsonMessage);
      print("📨 Sent: ${message['type'] ?? 'unknown'}");
      return true;
    } catch (e) {
      print("📨 Error sending message: $e");
      return false;
    }
  }

  /// Handle eingehende Nachrichten
  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      _lastMessageReceived = DateTime.now();
      _totalMessagesReceived++;

      final String messageString = rawMessage.toString();
      print("📨 Received: ${messageString.substring(0, 100)}${messageString.length > 100 ? '...' : ''}");

      final Map<String, dynamic> messageJson = json.decode(messageString);
      final WebSocketMessage message = WebSocketMessage.fromJson(messageJson);

      // Route message zu registrierten Handlers
      final handlers = _messageHandlers[message.type] ?? [];
      for (final handler in handlers) {
        try {
          handler(message);
        } catch (e) {
          print("📨 Error in message handler for ${message.type.value}: $e");
        }
      }

      // Handle Ping/Pong
      if (message.type.value == 'ping') {
        _sendPong();
      }

    } catch (e) {
      print("📨 Error parsing message: $e");
    }
  }

  /// 🔄 CONNECTION MANAGEMENT

  /// Handle Connection Error
  void _handleConnectionError(dynamic error) {
    _updateStatus(WebSocketStatus.error, error.toString());
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  /// Handle Connection Closed
  void _handleConnectionClosed() {
    if (_status == WebSocketStatus.connected) {
      _updateStatus(WebSocketStatus.disconnected);
    }
    _pingTimer?.cancel();

    if (_isOnline && _status != WebSocketStatus.error) {
      _scheduleReconnect();
    }
  }

  /// Schedule Reconnect
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print("🔄 Max reconnection attempts reached");
      _updateStatus(WebSocketStatus.failed, "Max reconnection attempts exceeded");
      return;
    }

    if (_reconnectTimer?.isActive == true) {
      return;
    }

    _reconnectAttempts++;
    _updateStatus(WebSocketStatus.reconnecting);

    final delay = Duration(
      seconds: _reconnectDelay.inSeconds * _reconnectAttempts,
    );

    print("🔄 Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)");

    _reconnectTimer = Timer(delay, () async {
      if (_isOnline) {
        await _connectInternal();
      }
    });
  }

  /// Force Reconnect
  Future<void> forceReconnect() async {
    print("🔄 Force reconnecting...");
    await disconnect();
    _reconnectAttempts = 0;
    await connect();
  }

  /// 💓 HEALTH MONITORING

  /// Start Health Monitoring
  void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      _performHealthCheck();
    });
  }

  /// Perform Health Check
  void _performHealthCheck() {
    final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceived);

    print("💓 Health Check - Last message: ${timeSinceLastMessage.inMinutes} minutes ago");

    if (isConnected && timeSinceLastMessage.inMinutes > 5) {
      print("💓 Connection seems unhealthy - forcing reconnect");
      forceReconnect();
    }
  }

  /// Start Ping Timer
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      _sendPing();
    });
  }

  /// Send Ping
  void _sendPing() {
    sendMessage({
      'type': 'ping',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  /// Send Pong
  void _sendPong() {
    sendMessage({
      'type': 'pong',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  /// 🌐 CONNECTIVITY HANDLING

  /// Handle Connectivity Changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    print("🌐 Connectivity changed: $result, online: $_isOnline");

    if (_isOnline && !wasOnline) {
      print("🌐 Back online - reconnecting...");
      connect();
    } else if (!_isOnline && wasOnline) {
      print("🌐 Gone offline - disconnecting...");
      disconnect();
    }
  }

  /// 📊 STATUS MANAGEMENT

  /// Update Status
  void _updateStatus(WebSocketStatus status, [String? error]) {
    _status = status;
    _lastError = error;
    notifyListeners();

    print("🔌 Status: ${status.name}${error != null ? ' - $error' : ''}");
  }

  /// Get Status Text
  String get statusText {
    switch (_status) {
      case WebSocketStatus.connected:
        return "Connected";
      case WebSocketStatus.connecting:
        return "Connecting...";
      case WebSocketStatus.reconnecting:
        return "Reconnecting... (${_reconnectAttempts}/$_maxReconnectAttempts)";
      case WebSocketStatus.disconnected:
        return "Disconnected";
      case WebSocketStatus.error:
        return "Error: ${_lastError ?? 'Unknown error'}";
      case WebSocketStatus.failed:
        return "Failed: ${_lastError ?? 'Connection failed'}";
    }
  }

  /// Get Connection Stats
  Map<String, dynamic> get connectionStats => {
    'status': _status.name,
    'isConnected': isConnected,
    'isHealthy': isHealthy,
    'reconnectAttempts': _reconnectAttempts,
    'totalMessagesReceived': _totalMessagesReceived,
    'lastConnected': _lastConnected.toIso8601String(),
    'lastMessageReceived': _lastMessageReceived.toIso8601String(),
    'minutesSinceLastMessage': DateTime.now().difference(_lastMessageReceived).inMinutes,
    'lastError': _lastError,
  };

  /// 🔧 DEBUGGING

  /// Debug Connection Info
  void debugConnection() {
    print("🔧 === WEBSOCKET DEBUG INFO ===");
    print("🔧 Status: ${_status.name}");
    print("🔧 Connected: $isConnected");
    print("🔧 Healthy: $isHealthy");
    print("🔧 Online: $_isOnline");
    print("🔧 Reconnect attempts: $_reconnectAttempts");
    print("🔧 Total messages: $_totalMessagesReceived");
    print("🔧 Last connected: $_lastConnected");
    print("🔧 Last message: $_lastMessageReceived");
    print("🔧 Last error: $_lastError");
    print("🔧 Message handlers: ${_messageHandlers.length}");
    _messageHandlers.forEach((type, handlers) {
      print("🔧   ${type.value}: ${handlers.length} handlers");
    });
    print("🔧 === END WEBSOCKET DEBUG ===");
  }

  /// 🧹 CLEANUP
  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    disconnect();
    super.dispose();
  }
}