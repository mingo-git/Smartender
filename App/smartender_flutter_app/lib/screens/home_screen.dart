import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/components/bottom_nav_bar.dart';
import 'package:smartender_flutter_app/screens/homesceens/searchdrinks_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settings_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/favorites_screen.dart';
import '../provider/theme_provider.dart';
import '../services/slot_service.dart';
import '../services/drink_service.dart';
import '../services/fetch_data_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final FetchdData _fetchDataService = FetchdData();

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

    // Die globale FetchdData-Instanz aus dem Provider holen
    final fetchData = Provider.of<FetchdData>(context, listen: false);

    // Beim Start der App: Direkt einmal Daten vom Backend laden
    fetchData.fetchAllNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Polling stoppen, wenn der HomeScreen verlassen wird
    _fetchDataService.stopPolling();
    super.dispose();
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> navigateBottomBar(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    final fetchData = Provider.of<FetchdData>(context, listen: false);
    await fetchData.fetchAllNow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
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