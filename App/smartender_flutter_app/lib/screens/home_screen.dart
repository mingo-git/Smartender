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
      backgroundColor: backgroundColor,
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
