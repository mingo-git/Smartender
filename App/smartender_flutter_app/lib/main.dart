// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/models/cocktail_card.dart';
import 'package:smartender_flutter_app/screens/home_screen.dart';
import 'package:smartender_flutter_app/screens/login_screen.dart';

import 'package:smartender_flutter_app/services/auth_service.dart';
import 'package:smartender_flutter_app/services/drink_service.dart';
import 'package:smartender_flutter_app/services/fetch_data_service.dart';
import 'package:smartender_flutter_app/services/order_drink_service.dart';
import 'package:smartender_flutter_app/services/recipe_service.dart';
import 'package:smartender_flutter_app/services/slot_service.dart';
import 'package:smartender_flutter_app/services/websocket_service.dart';
import 'package:smartender_flutter_app/services/maintenance_service.dart';
import 'components/connection_dot.dart';
import 'components/connection_badge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildschirmrotation deaktivieren
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: '.env');

  final AuthService authService = AuthService();
  final String? token = await authService.getToken();

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final FetchdData fetchdData;
  late final WebSocketService webSocketService;
  late final RecipeService recipeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Core services
    webSocketService = WebSocketService();
    recipeService = RecipeService();
    final drinkService = DrinkService();
    final slotService = SlotService();

    // Fetch/HTTP-Fallback Manager
    fetchdData = FetchdData();
    fetchdData.addService(recipeService);
    fetchdData.addService(drinkService);
    fetchdData.addService(slotService);

    // App-Init
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup
    webSocketService.disconnect();
    fetchdData.stopPolling();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResume();
        break;
      case AppLifecycleState.paused:
        _onPause();
        break;
      case AppLifecycleState.detached:
        _onDetached();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      print("🚀 Initializing Smartender App...");

      // 1) WebSocket vorbereiten
      await webSocketService.initialize();
      print("✅ WebSocket Service initialized");

      // 2) Adaptive Polling konfigurieren (WebSocket-First, weniger aggressiv)
      fetchdData.setWebSocketEnabled(true);
      fetchdData.setAdaptivePolling(true);
      fetchdData.configurePollingIntervals(
        baseInterval: const Duration(minutes: 2), // wenn WS connected
        fastInterval: const Duration(seconds: 30), // wenn WS down
      );
      print("✅ Adaptive polling configured");

      // 3) Polling starten (übernimmt Safety-/Fallback-HTTP bei Bedarf)
      fetchdData.startPolling();
      print("✅ Intelligent polling started");

      // 4) Wenn eingeloggt: WebSocket verbinden (Primary), HTTP nur als Fallback
      if (widget.isLoggedIn) {
        await _connectWebSocketPrimary();
      }

      print("🎉 App initialization completed");
    } catch (e) {
      print("❌ Error during app initialization: $e");
      // Fallback: Starte moderates Polling
      fetchdData.startPolling(interval: const Duration(seconds: 30));
    }
  }

  Future<void> _connectWebSocketPrimary() async {
    try {
      await webSocketService.connect();
      print("✅ WebSocket connected for real-time updates");

      // Kein sofortiger HTTP-Fetch: WS-first. FetchdData kümmert sich um Safety/Fallback.
    } catch (e) {
      print("⚠️ WebSocket connection failed, switching to HTTP fallback: $e");
      await fetchdData.fetchAllNow(); // einmaliger Fallback-Initial-Load
    }
  }

  Future<void> _onResume() async {
    print("📱 App resumed - checking connections...");
    try {
      if (!webSocketService.isConnected) {
        await webSocketService.connect();
      }
      // Kein erzwungener HTTP-Fetch hier; FetchdData entscheidet via Safety/Fallback.
      print("✅ App resume completed");
    } catch (e) {
      print("⚠️ Error during app resume: $e");
    }
  }

  void _onPause() {
    print("📱 App paused - WebSocket remains connected for background updates");
  }

  void _onDetached() {
    print("📱 App detached - cleaning up connections...");
    webSocketService.disconnect();
    fetchdData.stopPolling();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // UI/Theme
        ChangeNotifierProvider(create: (_) => CocktailCard()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Domain Services
        ChangeNotifierProvider.value(value: recipeService),
        ChangeNotifierProvider(create: (_) => DrinkService()),
        ChangeNotifierProvider(create: (_) => SlotService()),

        // Infra Services
        ChangeNotifierProvider.value(value: webSocketService),
        ChangeNotifierProvider.value(value: fetchdData),

        // Action Services (HTTP-only)
        Provider(create: (_) => OrderDrinkService()),
        ChangeNotifierProvider(create: (_) => MaintenanceService()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: themeProvider.currentTheme.backgroundColor,
              primaryColor: themeProvider.currentTheme.primaryColor,
            ),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => LoginScreen(),
            },
            initialRoute: widget.isLoggedIn ? '/home' : '/login',
            navigatorObservers: [
              _SmartenderNavigatorObserver(webSocketService, fetchdData),
            ],
            builder: (context, child) {
              // Global status badges (top-right): Server (S) and Hardware (H)
              return Stack(
                children: [
                  if (child != null) child,
                  Positioned(
                    // Vertikal an die "Smartender"-Schrift (30px) ausrichten:
                    // Oberkante = Safe-Area + 5px Padding + (30 - KreisDurchmesser)/2
                    top: () {
                      const double titleFontSize = 30.0;
                      const double circle = 16.8; // Größe der ConnectionBadge (siehe component)
                      final safeTop = MediaQuery.of(context).padding.top;
                      return safeTop + 5.0 + ((titleFontSize - circle) / 2.0);
                    }(),
                    right: 8,
                    child: Consumer<WebSocketService>(
                      builder: (ctx, ws, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConnectionBadge(label: 'S', ok: ws.isConnected),
                            const SizedBox(width: 8),
                            ConnectionBadge(label: 'H', ok: ws.hardwareConnected),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Custom NavigatorObserver to manage WebSocket connections during navigation
class _SmartenderNavigatorObserver extends NavigatorObserver {
  final WebSocketService _webSocketService;
  final FetchdData _fetchData;

  _SmartenderNavigatorObserver(this._webSocketService, this._fetchData);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    final routeName = route.settings.name;
    print("📍 Navigated to: $routeName");

    // Nach Login sicherstellen, dass WS verbunden ist
    if (routeName == '/home' && !_webSocketService.isConnected) {
      print("🔌 Connecting WebSocket after login...");
      _webSocketService.connect().then((_) {
        // Kein zwingender HTTP-Fetch – FetchdData übernimmt Safety/Fallback.
      }).catchError((e) async {
        print("⚠️ WebSocket connection failed after login: $e");
        await _fetchData.fetchAllNow(); // Fallback, falls WS nicht geht
      });
    }

    // Bei Logout WS trennen
    if (routeName == '/login') {
      print("🔌 Disconnecting WebSocket after logout...");
      _webSocketService.disconnect();
    }
  }
}

/// Extension to provide easy access to system status throughout the app
extension SmartenderAppContext on BuildContext {
  /// Get current WebSocket connection status
  String get webSocketStatus => read<WebSocketService>().connectionStatusText;

  /// Check if real-time updates are available
  bool get isRealTimeEnabled => read<WebSocketService>().isConnected;

  /// Get system status for debugging
  Map<String, dynamic> get systemStatus => read<FetchdData>().getSystemStatus();

  /// Force refresh all data
  Future<void> forceRefreshData() => read<FetchdData>().forceRefresh();

  /// Force reconnect WebSocket
  Future<void> reconnectWebSocket() => read<WebSocketService>().forceReconnect();
}

// Small wrapper to provide a subtle tap-target spacing if needed later
class _ConnectionDotPadded extends StatelessWidget {
  const _ConnectionDotPadded();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(2.0),
      child: SizedBox(
        width: 14,
        height: 14,
        child: Center(child: _ConnectionDotInternal()),
      ),
    );
  }
}

class _ConnectionDotInternal extends StatelessWidget {
  const _ConnectionDotInternal();

  @override
  Widget build(BuildContext context) {
    // Use the shared component; keep an internal alias for minimal deps in main.dart
    // ignore: prefer_const_constructors
    return ConnectionDot();
  }
}
