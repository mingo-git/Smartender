// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/websocket/websocket_message.dart';
import '../config/constants.dart';
import 'auth_service.dart';

typedef WebSocketMessageHandler = void Function(WebSocketMessage message);

class WebSocketService extends ChangeNotifier {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Configuration
  late WebSocketConfig _config;
  final AuthService _authService = AuthService();

  // Connection status
  WebSocketStatusInfo _statusInfo = WebSocketStatusInfo(
    status: WebSocketConnectionStatus.disconnected,
    lastConnected: DateTime.now(),
  );

  // Message handlers
  final Map<WebSocketMessageType, List<WebSocketMessageHandler>> _messageHandlers = {};

  // Connectivity
  bool _isOnline = true;
  bool _isInitialized = false;

  // Getters
  WebSocketStatusInfo get statusInfo => _statusInfo;
  bool get isConnected => _statusInfo.status == WebSocketConnectionStatus.connected;
  bool get isOnline => _isOnline;

  /// Initialize WebSocket Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _config = WebSocketConfig(
      baseUrl: baseUrl,
      wsPath: '/api/ws',
      reconnectDelay: const Duration(seconds: 5),
      maxReconnectAttempts: 10,
      pingInterval: const Duration(seconds: 30),
      connectionTimeout: const Duration(seconds: 10),
    );

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    _isInitialized = true;
    print("WebSocket Service initialized");
  }

  /// Start WebSocket connection
  Future<void> connect() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isOnline) {
      print("Cannot connect to WebSocket: No internet connection");
      return;
    }

    if (isConnected) {
      print("WebSocket already connected");
      return;
    }

    await _connect();
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    print("Disconnecting WebSocket...");

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _messageSubscription?.cancel();

    try {
      await _channel?.sink.close();
    } catch (e) {
      print("Error closing WebSocket: $e");
    }

    _channel = null;
    _updateStatus(WebSocketConnectionStatus.disconnected);
    print("WebSocket disconnected");
  }

  /// Register message handler for specific message type
  void addMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers.putIfAbsent(type, () => []).add(handler);
    print("Added message handler for type: ${type.value}");
  }

  /// Remove message handler
  void removeMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers[type]?.remove(handler);
    if (_messageHandlers[type]?.isEmpty == true) {
      _messageHandlers.remove(type);
    }
  }

  /// Send message via WebSocket
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) {
      print("Cannot send message: WebSocket not connected");
      return false;
    }

    try {
      final jsonMessage = json.encode(message);
      _channel?.sink.add(jsonMessage);
      print("Sent WebSocket message: $jsonMessage");
      return true;
    } catch (e) {
      print("Error sending WebSocket message: $e");
      return false;
    }
  }

  /// 🔧 KORRIGIERTE VERBINDUNGSMETHODE - Jetzt mit API-Key
  Future<void> _connect() async {
    try {
      _updateStatus(WebSocketConnectionStatus.connecting);

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception("No authentication token available");
      }

      print("🔍 === CORRECTED URL CONSTRUCTION ===");

      // Schritt 1: Basis WebSocket URL konstruieren
      final baseWsUrl = _config.wsUrl;
      print("🔍 Step 1 - Base WebSocket URL: '$baseWsUrl'");

      // Schritt 2: URL-Parameter hinzufügen (Token UND API-Key)
      final uri = Uri.parse(baseWsUrl).replace(queryParameters: {
        'token': token,
        'X_API_KEY': apiKey,  // 🔧 API-Key hinzugefügt!
      });

      print("🔍 Step 2 - Complete WebSocket URL: '${uri.toString()}'");
      print("🔍 Step 3 - URI scheme: '${uri.scheme}'");
      print("🔍 Step 4 - URI host: '${uri.host}'");
      print("🔍 Step 5 - URI port: ${uri.port}");
      print("🔍 Step 6 - URI query: '${uri.query}'");
      print("🔍 === END CORRECTED URL CONSTRUCTION ===");

      print("Connecting to WebSocket: ${uri.toString()}");

      _channel = WebSocketChannel.connect(
        uri,  // 🔧 Vollständige URI mit Token UND API-Key
        protocols: ['smartender-v1'],
      );

      // Connection timeout handling
      final connectionCompleter = Completer<void>();
      Timer(_config.connectionTimeout, () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(TimeoutException("Connection timeout"));
        }
      });

      _messageSubscription = _channel!.stream.listen(
            (message) {
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete();
          }
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print("WebSocket error: $error");
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(error);
          }
          _handleConnectionError(error);
        },
        onDone: () {
          print("WebSocket connection closed");
          _handleConnectionClosed();
        },
      );

      await connectionCompleter.future;
      _updateStatus(WebSocketConnectionStatus.connected);
      _startPingTimer();
      print("✅ WebSocket connected successfully with API key!");

    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _updateStatus(
        WebSocketConnectionStatus.error,
        errorMessage: e.toString(),
      );
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final String messageString = rawMessage.toString();
      print("Received WebSocket message: $messageString");

      final Map<String, dynamic> messageJson = json.decode(messageString);
      final WebSocketMessage message = WebSocketMessage.fromJson(messageJson);

      // Route message to registered handlers
      final handlers = _messageHandlers[message.type] ?? [];
      for (final handler in handlers) {
        try {
          handler(message);
        } catch (e) {
          print("Error in message handler for ${message.type.value}: $e");
        }
      }

      // Special handling for ping/pong
      if (message.type.value == 'ping') {
        _sendPong();
      }

    } catch (e) {
      print("Error parsing WebSocket message: $e");
    }
  }

  /// Handle connection errors
  void _handleConnectionError(dynamic error) {
    _updateStatus(
      WebSocketConnectionStatus.error,
      errorMessage: error.toString(),
    );

    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    _updateStatus(WebSocketConnectionStatus.disconnected);
    _pingTimer?.cancel();

    if (_isOnline) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_statusInfo.reconnectAttempts >= _config.maxReconnectAttempts) {
      print("Max reconnection attempts reached");
      _updateStatus(
        WebSocketConnectionStatus.error,
        errorMessage: "Max reconnection attempts exceeded",
      );
      return;
    }

    if (_reconnectTimer?.isActive == true) {
      return;
    }

    _updateStatus(WebSocketConnectionStatus.reconnecting);

    final delay = Duration(
      seconds: _config.reconnectDelay.inSeconds * (_statusInfo.reconnectAttempts + 1),
    );

    print("Scheduling reconnect in ${delay.inSeconds} seconds (attempt ${_statusInfo.reconnectAttempts + 1})");

    _reconnectTimer = Timer(delay, () async {
      _updateStatus(
        WebSocketConnectionStatus.reconnecting,
        reconnectAttempts: _statusInfo.reconnectAttempts + 1,
      );
      await _connect();
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_config.pingInterval, (timer) {
      _sendPing();
    });
  }

  /// Send ping message
  void _sendPing() {
    sendMessage({
      'type': 'ping',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  /// Send pong response
  void _sendPong() {
    sendMessage({
      'type': 'pong',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    print("Connectivity changed: $result, online: $_isOnline");

    if (_isOnline && !wasOnline) {
      // Back online - try to reconnect
      print("Back online, attempting to reconnect...");
      connect();
    } else if (!_isOnline && wasOnline) {
      // Gone offline - disconnect gracefully
      print("Gone offline, disconnecting...");
      disconnect();
    }
  }

  /// Update connection status
  void _updateStatus(
      WebSocketConnectionStatus status, {
        String? errorMessage,
        int? reconnectAttempts,
      }) {
    final now = DateTime.now();

    _statusInfo = _statusInfo.copyWith(
      status: status,
      errorMessage: errorMessage,
      lastConnected: status == WebSocketConnectionStatus.connected ? now : null,
      reconnectAttempts: reconnectAttempts ?? (
          status == WebSocketConnectionStatus.connected ? 0 : _statusInfo.reconnectAttempts
      ),
    );

    notifyListeners();
    print("WebSocket status updated: ${status.name}");
  }

  /// Dispose service
  @override
  void dispose() {
    disconnect();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Force reconnect (useful for manual retry)
  Future<void> forceReconnect() async {
    print("Force reconnecting WebSocket...");
    await disconnect();
    _statusInfo = _statusInfo.copyWith(reconnectAttempts: 0);
    await connect();
  }

  /// Get connection status as readable string
  String get connectionStatusText {
    switch (_statusInfo.status) {
      case WebSocketConnectionStatus.connected:
        return "Connected";
      case WebSocketConnectionStatus.connecting:
        return "Connecting...";
      case WebSocketConnectionStatus.reconnecting:
        return "Reconnecting... (${_statusInfo.reconnectAttempts}/${_config.maxReconnectAttempts})";
      case WebSocketConnectionStatus.disconnected:
        return "Disconnected";
      case WebSocketConnectionStatus.error:
        return "Error: ${_statusInfo.errorMessage ?? 'Unknown error'}";
    }
  }
}