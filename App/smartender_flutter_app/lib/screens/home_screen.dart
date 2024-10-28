import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/components/bottom_nav_bar.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/screens/homesceens/searchdrinks_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settings_screen.dart';
import '../services/auth_service.dart';
import 'homesceens/favorites_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkToken();
    }
  }

  void _checkToken() async {
    final isValid = await _authService.isTokenValid();
    if (!isValid) {
      // Token ist abgelaufen oder nicht vorhanden, leite zur Login-Seite weiter
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  int _selectedIndex = 0;
  void navigateBottomBar(int index){
    setState(() {
      _selectedIndex = index;
    });

  }

  final List<Widget> _pages = [
    SearchdrinksScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Dein UI-Code hier
    return Scaffold(
      backgroundColor: backgroundcolor,
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
