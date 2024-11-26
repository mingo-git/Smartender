import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;

  MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x00f2f2f2),
                  const Color(0xE5F2F2F2),
                  backgroundColor,
                  backgroundColor,
                ],
              ),
            ),
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: 130,
              bottom: 30, // Erhöhe den Abstand für eine Verschiebung um 15 nach oben
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0), // Hebt die Navbar um 15 nach oben
              child: GNav(
                onTabChange: (value) => onTabChange!(value),
                color: Colors.grey[400],
                mainAxisAlignment: MainAxisAlignment.center,
                activeColor: Colors.grey[700],
                tabBackgroundColor: Colors.grey.shade300,
                tabBorderRadius: defaultBorderRadius.topLeft.x,
                tabActiveBorder: Border.all(color: Colors.white),
                tabs: const [
                  GButton(icon: Icons.search_outlined, text: 'Search'),
                  GButton(icon: Icons.favorite, text: 'Favorites'),
                  GButton(icon: Icons.settings, text: 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
