import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;

  MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xF2F2F2),
            Color(0xE5F2F2F2),
            backgroundColor,
            backgroundColor,
          ],
        ),
      ),
      padding: const EdgeInsets.only(left: 25, right: 25, top: 100, bottom: 15),
      child: GNav(
        onTabChange: (value) => onTabChange!(value),
        color: Colors.grey[400],
        mainAxisAlignment: MainAxisAlignment.center,
        activeColor: Colors.grey[700],
        tabBackgroundColor: Colors.grey.shade300,
        tabBorderRadius: 24,
        tabActiveBorder: Border.all(color: Colors.white),
        tabs: const [
          GButton(icon: Icons.search_outlined, text: 'Search'),
          GButton(icon: Icons.favorite, text: 'Favorites'),
          GButton(icon: Icons.settings, text: 'Settings'),
        ],
      ),
    );
  }
}
