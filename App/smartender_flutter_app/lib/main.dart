import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/models/cocktail_card.dart';
import 'package:smartender_flutter_app/screens/home_screen.dart';
import 'package:smartender_flutter_app/screens/login_screen.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import 'package:smartender_flutter_app/services/drink_service.dart';
import 'package:smartender_flutter_app/services/slot_service.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
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
        Provider<DrinkService>(create: (_) => DrinkService()),
        Provider<SlotService>(create: (_) => SlotService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
