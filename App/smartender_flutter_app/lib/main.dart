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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CocktailCard()),
        ChangeNotifierProvider(create: (_) => RecipeService()), // Ändere zu ChangeNotifierProvider
        Provider<DrinkService>(create: (_) => DrinkService()),
        Provider<SlotService>(create: (_) => SlotService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          final recipeService = Provider.of<RecipeService>(context, listen: false);
          final drinkService = Provider.of<DrinkService>(context, listen: false);

          // Initialisiere FetchdData nur einmal
          final fetchdData = FetchdData();
          fetchdData.addService(drinkService);
          fetchdData.addService(recipeService);
          fetchdData.startPolling(interval: const Duration(seconds: 10));

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: themeProvider.currentTheme.backgroundColor,
              primaryColor: themeProvider.currentTheme.primaryColor,
            ),
            routes: {
              '/home': (context) => HomeScreen(),
              '/login': (context) => LoginScreen(),
            },
            initialRoute: isLoggedIn ? '/home' : '/login',
          );
        },
      ),
    );
  }
}
