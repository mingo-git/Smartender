import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/models/cocktail_card.dart';
import 'package:smartender_flutter_app/screens/home_screen.dart';
import 'package:smartender_flutter_app/screens/login_screen.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';


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
    return ChangeNotifierProvider(
      create: (context) => CocktailCard(),
      builder: (context, child) =>
      MaterialApp(
        // Definiere deine Routen
        routes: {
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(),
        },
        // Starte mit der entsprechenden Seite
        initialRoute: isLoggedIn ? '/home' : '/login',
      ),
    );
  }
}
