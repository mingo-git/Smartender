// lib/main.dart

import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final AuthService _authService = AuthService();
  String? token = await _authService.getToken();

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialisierung aller Services
    final recipeService = RecipeService();
    final drinkService = DrinkService();
    final slotService = SlotService();


    // Singleton-Instanz von FetchdData
    final fetchdData = FetchdData();
    fetchdData.addService(recipeService);
    fetchdData.addService(drinkService);
    fetchdData.addService(slotService);
    // Fügen Sie weitere Services hinzu, falls vorhanden

    // Starten des Pollings mit einem zentralen Intervall
    fetchdData.startPolling(interval: const Duration(seconds: 60));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CocktailCard()),
        ChangeNotifierProvider(create: (_) => RecipeService()), // Falls benötigt
        ChangeNotifierProvider(create: (_) => DrinkService()), // Falls benötigt
        ChangeNotifierProvider(create: (_) => SlotService()), // Falls benötigt
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: fetchdData), // FetchdData als Provider hinzufügen
        Provider(create: (_) => OrderDrinkService()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          // Sie können hier weitere Initialisierungen durchführen, falls erforderlich

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              /*fontFamily: 'Roboto',*/
              scaffoldBackgroundColor: themeProvider.currentTheme.backgroundColor,
              primaryColor: themeProvider.currentTheme.primaryColor,
            ),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => LoginScreen(),
            },
            initialRoute: isLoggedIn ? '/home' : '/login',
          );
        },
      ),
    );
  }
}
