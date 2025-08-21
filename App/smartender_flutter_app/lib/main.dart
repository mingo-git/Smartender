// lib/main.dart - MIT HTTP API DEBUGGING

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildschirmrotation deaktivieren
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: '.env');

  final AuthService _authService = AuthService();
  String? token = await _authService.getToken();

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
  late final RecipeService recipeService; // 🔧 Hinzugefügt für Debug-Zugriff

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize WebSocket Service
    webSocketService = WebSocketService();

    // Initialisiere FetchdData
    recipeService = RecipeService(); // 🔧 Als Klassenfeld gespeichert
    final drinkService = DrinkService();
    final slotService = SlotService();

    fetchdData = FetchdData();
    fetchdData.addService(recipeService);
    fetchdData.addService(drinkService);
    fetchdData.addService(slotService);

    // Initialize the app
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup WebSocket and polling
    webSocketService.disconnect();
    fetchdData.stopPolling();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // App wieder in den Vordergrund - WebSocket reconnect und Daten aktualisieren
        _onResume();
        break;
      case AppLifecycleState.paused:
      // App in den Hintergrund - WebSocket kann verbunden bleiben für Background-Updates
        _onPause();
        break;
      case AppLifecycleState.detached:
      // App wird beendet - Cleanup
        _onDetached();
        break;
      case AppLifecycleState.inactive:
      // App inaktiv (z.B. während Telefonat)
        break;
      case AppLifecycleState.hidden:
      // App versteckt
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      print("🚀 Initializing Smartender App...");

      // 🔧 1. DEBUG HTTP APIs FIRST (vor allem anderen!)
      if (widget.isLoggedIn) {
        print("🔍 Starting HTTP API debugging...");
        await recipeService.debugHttpConnection();
        print("🔍 HTTP API debugging completed");
      }

      // 2. Initialize WebSocket Service
      await webSocketService.initialize();
      print("✅ WebSocket Service initialized");

      // 3. Configure adaptive polling
      fetchdData.setWebSocketEnabled(true);
      fetchdData.setAdaptivePolling(true);
      fetchdData.configurePollingIntervals(
        baseInterval: const Duration(seconds: 60),  // Normal polling when WebSocket connected
        fastInterval: const Duration(seconds: 15),  // Fast polling when WebSocket disconnected
      );
      print("✅ Adaptive polling configured");

      // 4. Start polling with intelligent strategy
      fetchdData.startPolling();
      print("✅ Intelligent polling started");

      // 5. If logged in, connect WebSocket and fetch initial data
      if (widget.isLoggedIn) {
        await _connectWebSocketAndFetchData();
      }

      print("🎉 App initialization completed");

    } catch (e) {
      print("❌ Error during app initialization: $e");

      // Fallback: Start basic polling even if WebSocket fails
      fetchdData.startPolling(interval: const Duration(seconds: 30));
    }
  }

  Future<void> _connectWebSocketAndFetchData() async {
    try {
      // 🔧 ERSTMAL NUR HTTP APIs testen (WebSocket auskommentiert)
      print("🔧 Skipping WebSocket for now - testing HTTP APIs only...");

      // Connect WebSocket for real-time updates
      // await webSocketService.connect(); // 🔧 TEMPORÄR AUSKOMMENTIERT
      // print("✅ WebSocket connected for real-time updates");

      // Initial data fetch
      await fetchdData.fetchAllNow();
      print("✅ Initial data fetched");

    } catch (e) {
      print("⚠️ Error during data fetch: $e");

      // Even if WebSocket fails, we can still work with HTTP polling
      await fetchdData.fetchAllNow();
    }
  }

  Future<void> _onResume() async {
    print("📱 App resumed - checking connections...");

    try {
      // Try to reconnect WebSocket if needed
      if (!webSocketService.isConnected) {
        // await webSocketService.connect(); // 🔧 TEMPORÄR AUSKOMMENTIERT
      }

      // Fetch latest data
      await fetchdData.fetchAllNow();

      print("✅ App resume completed");
    } catch (e) {
      print("⚠️ Error during app resume: $e");
    }
  }

  void _onPause() {
    print("📱 App paused - WebSocket remains connected for background updates");
    // WebSocket bleibt verbunden für Background-Updates
    // Polling continues at reduced frequency
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
        // Existing providers
        ChangeNotifierProvider(create: (context) => CocktailCard()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Core services with WebSocket integration
        ChangeNotifierProvider.value(value: recipeService), // 🔧 Verwende die gleiche Instanz
        ChangeNotifierProvider(create: (_) => DrinkService()),
        ChangeNotifierProvider(create: (_) => SlotService()),

        // WebSocket and networking services
        ChangeNotifierProvider.value(value: webSocketService),
        ChangeNotifierProvider.value(value: fetchdData),

        // Utility services
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

            // Global navigation observer for WebSocket management
            navigatorObservers: [
              _SmartenderNavigatorObserver(webSocketService, fetchdData),
            ],
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

    // 🔧 TEMPORÄR AUSKOMMENTIERT - erst HTTP APIs lösen
    // Connect WebSocket when navigating to home (after login)
    /*
    if (routeName == '/home' && !_webSocketService.isConnected) {
      print("🔌 Connecting WebSocket after login...");
      _webSocketService.connect().then((_) {
        // Fetch fresh data after WebSocket connection
        _fetchData.fetchAllNow();
      }).catchError((e) {
        print("⚠️ WebSocket connection failed after login: $e");
        // Continue with HTTP polling
        _fetchData.fetchAllNow();
      });
    }
    */

    // Disconnect WebSocket when logging out
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