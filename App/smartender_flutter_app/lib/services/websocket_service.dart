// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Basis-Typ für Channel
import 'package:web_socket_channel/web_socket_channel.dart';
// IO-spezifischer Channel für Header-Support (nur Mobile/Desktop)
import 'package:web_socket_channel/io.dart' as io;

import '../models/websocket/websocket_message.dart';
import '../config/constants.dart';
import 'auth_service.dart';

typedef WebSocketMessageHandler = void Function(WebSocketMessage message);

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketStatusInfo {
  final WebSocketConnectionStatus status;
  final DateTime lastConnected;
  final String? errorMessage;
  final int reconnectAttempts;

  WebSocketStatusInfo({
    required this.status,
    required this.lastConnected,
    this.errorMessage,
    this.reconnectAttempts = 0,
  });

  WebSocketStatusInfo copyWith({
    WebSocketConnectionStatus? status,
    DateTime? lastConnected,
    String? errorMessage,
    int? reconnectAttempts,
  }) {
    return WebSocketStatusInfo(
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      errorMessage: errorMessage,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

class WebSocketConfig {
  final String baseUrl;
  final String wsPath;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  final Duration pingInterval;
  final Duration connectionTimeout;

  WebSocketConfig({
    required this.baseUrl,
    required this.wsPath,
    required this.reconnectDelay,
    required this.maxReconnectAttempts,
    required this.pingInterval,
    required this.connectionTimeout,
  });
}

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  late WebSocketConfig _config;
  final AuthService _authService = AuthService();

  WebSocketStatusInfo _statusInfo = WebSocketStatusInfo(
    status: WebSocketConnectionStatus.disconnected,
    lastConnected: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final Map<WebSocketMessageType, List<WebSocketMessageHandler>> _messageHandlers = {};

  bool _isOnline = true;
  bool _isInitialized = false;

  WebSocketStatusInfo get statusInfo => _statusInfo;
  bool get isConnected => _statusInfo.status == WebSocketConnectionStatus.connected;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _config = WebSocketConfig(
      baseUrl: baseUrl,
      wsPath: '/api/ws',
      reconnectDelay: const Duration(seconds: 5),
      maxReconnectAttempts: 10,
      pingInterval: const Duration(seconds: 30),
      connectionTimeout: const Duration(seconds: 15),
    );

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    _isInitialized = true;
    print("WebSocket Service initialized");
  }

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

  void addMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers.putIfAbsent(type, () => []).add(handler);
    print("Added message handler for type: ${type.value}");
  }

  void removeMessageHandler(WebSocketMessageType type, WebSocketMessageHandler handler) {
    _messageHandlers[type]?.remove(handler);
    if (_messageHandlers[type]?.isEmpty == true) {
      _messageHandlers.remove(type);
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) {
      print("Cannot send message: WebSocket not connected");
      return false;
    }
    try {
      final jsonMessage = json.encode(message);
      _channel?.sink.add(jsonMessage);
      print("Sent WebSocket message: ${message['type'] ?? 'unknown'}");
      return true;
    } catch (e) {
      print("Error sending WebSocket message: $e");
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CONNECT (IO: Headers über IOWebSocketChannel.connect, Web: Query-Params)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _connect() async {
    try {
      _updateStatus(WebSocketConnectionStatus.connecting);

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception("No authentication token available");
      }

      final parsedBase = Uri.parse(_config.baseUrl);
      final isHttps = parsedBase.scheme == 'https';
      final scheme = isHttps ? 'wss' : 'ws';

      int? port;
      if (parsedBase.hasPort) {
        final p = parsedBase.port;
        if (p != 80 && p != 443) {
          port = p; // niemals 0 setzen
        }
      }

      final host = parsedBase.host.isNotEmpty
          ? parsedBase.host
          : _config.baseUrl
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .split('/')[0];

      final qp = <String, String>{
        'token': token,
        // Im Web sind Header nicht möglich → API-Key zusätzlich als Query
        if (kIsWeb) 'X-API-KEY': apiKey,
        if (kIsWeb) 'X_API_KEY': apiKey,
      };

      final uri = Uri(
        scheme: scheme,
        host: host,
        port: port,
        path: _config.wsPath,
        queryParameters: qp,
      );

      print("🔍 === CORRECTED URL CONSTRUCTION (no :0) ===");
      print("🔍 scheme: ${uri.scheme}");
      print("🔍 host: ${uri.host}");
      print("🔍 port(included?): ${uri.hasPort ? uri.port : 'none'}");
      print("🔍 path: ${uri.path}");
      print("🔍 query: ${uri.query}");
      print("🔍 FINAL URI: $uri");
      print("🔍 === END CORRECTED URL CONSTRUCTION ===");

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
      };

      final connectionCompleter = Completer<void>();
      Timer(_config.connectionTimeout, () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(TimeoutException("Connection timeout"));
        }
      });

      // WICHTIG: Nur auf IO (Android/iOS/Desktop) mit Headers verbinden
      if (kIsWeb) {
        // Web: keine Header möglich
        _channel = WebSocketChannel.connect(
          uri,
          protocols: const ['smartender-v1'],
        );
      } else {
        // Mobile/Desktop: Header werden unterstützt
        _channel = io.IOWebSocketChannel.connect(
          uri,
          protocols: const ['smartender-v1'],
          headers: headers,
        );
      }

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
      print("✅ WebSocket connected successfully${kIsWeb ? ' (web, query auth)' : ' with headers!'}");

    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _updateStatus(
        WebSocketConnectionStatus.error,
        errorMessage: e.toString(),
      );
      _scheduleReconnect();
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final String messageString = rawMessage.toString();
      print("Received WebSocket message: ${messageString.length > 200 ? messageString.substring(0, 200) + '…' : messageString}");

      final Map<String, dynamic> messageJson = json.decode(messageString);
      final WebSocketMessage message = WebSocketMessage.fromJson(messageJson);

      final handlers = _messageHandlers[message.type] ?? [];
      for (final handler in handlers) {
        try {
          handler(message);
        } catch (e) {
          print("Error in message handler for ${message.type.value}: $e");
        }
      }

      if (message.type.value == 'ping') {
        _sendPong();
      }
    } catch (e) {
      print("Error parsing WebSocket message: $e");
    }
  }

  void _handleConnectionError(dynamic error) {
    _updateStatus(
      WebSocketConnectionStatus.error,
      errorMessage: error.toString(),
    );
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _handleConnectionClosed() {
    _updateStatus(WebSocketConnectionStatus.disconnected);
    _pingTimer?.cancel();

    if (_isOnline) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_statusInfo.reconnectAttempts >= _config.maxReconnectAttempts) {
      print("Max reconnection attempts reached");
      _updateStatus(
        WebSocketConnectionStatus.error,
        errorMessage: "Max reconnection attempts exceeded",
      );
      return;
    }
    if (_reconnectTimer?.isActive == true) return;

    final nextAttempt = _statusInfo.reconnectAttempts + 1;
    _updateStatus(WebSocketConnectionStatus.reconnecting, reconnectAttempts: nextAttempt);

    final delay = Duration(seconds: _config.reconnectDelay.inSeconds * nextAttempt);
    print("Scheduling reconnect in ${delay.inSeconds} seconds (attempt $nextAttempt)");

    _reconnectTimer = Timer(delay, () async {
      await _connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_config.pingInterval, (_) => _sendPing());
  }

  void _sendPing() {
    sendMessage({
      'type': 'ping',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  void _sendPong() {
    sendMessage({
      'type': 'pong',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    print("Connectivity changed: $result, online: $_isOnline");

    if (_isOnline && !wasOnline) {
      print("Back online, attempting to reconnect...");
      connect();
    } else if (!_isOnline && wasOnline) {
      print("Gone offline, disconnecting...");
      disconnect();
    }
  }

  void _updateStatus(
      WebSocketConnectionStatus status, {
        String? errorMessage,
        int? reconnectAttempts,
      }) {
    final now = DateTime.now();

    _statusInfo = _statusInfo.copyWith(
      status: status,
      errorMessage: errorMessage,
      lastConnected: status == WebSocketConnectionStatus.connected ? now : _statusInfo.lastConnected,
      reconnectAttempts: reconnectAttempts ??
          (status == WebSocketConnectionStatus.connected ? 0 : _statusInfo.reconnectAttempts),
    );

    notifyListeners();
    print("WebSocket status updated: ${status.name}${errorMessage != null ? ' - $errorMessage' : ''}");
  }

  @override
  void dispose() {
    disconnect();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> forceReconnect() async {
    print("Force reconnecting WebSocket...");
    await disconnect();
    _statusInfo = _statusInfo.copyWith(reconnectAttempts: 0);
    await connect();
  }

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
