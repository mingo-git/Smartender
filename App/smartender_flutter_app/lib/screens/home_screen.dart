import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/components/bottom_nav_bar.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/screens/homesceens/searchdrinks_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settings_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/favorites_screen.dart';
import '../services/auth_service.dart';
import '../services/drink_service.dart';
import '../services/fetch_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final FetchData _fetchData = FetchData();

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SearchdrinksScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialisiere DrinkService und füge es zu FetchData hinzu
    final drinkService = DrinkService(baseUrl: baseUrl);
    _fetchData.addService(drinkService);

    // Starte das regelmäßige Abrufen
    _fetchData.startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Stoppe das Polling, wenn der Screen zerstört wird
    _fetchData.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData.startPolling();
    } else if (state == AppLifecycleState.paused) {
      _fetchData.stopPolling();
    }
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false, // Verhindert das Verschieben der NavBar bei Tastatureinblendung
      body: Stack(
        children: [
          // Hauptinhalt des Bodys
          _pages[_selectedIndex],

          // BottomNavBar über dem Body-Inhalt
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MyBottomNavBar(
              onTabChange: (index) => navigateBottomBar(index),
            ),
          ),
        ],
      ),
    );
  }
}
