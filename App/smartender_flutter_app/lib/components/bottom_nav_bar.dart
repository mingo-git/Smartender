import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import '../provider/theme_provider.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;

  MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.fadeOutBackground1,
                  theme.fadeOutBackground0,
                  theme.backgroundColor,
                  theme.backgroundColor,
                  theme.backgroundColor,
                ],
              ),
            ),
            padding: const EdgeInsets.only(
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
                color: theme.primaryColor, // Gradientfarbe für nicht ausgewählte Icons
                mainAxisAlignment: MainAxisAlignment.center,
                tabBorderRadius: defaultBorderRadius.topLeft.x,
                tabBackgroundColor: theme.primaryColor, // Hintergrund des aktiven Tabs
                activeColor: theme.tertiaryColor, // Farbe des aktiven Tab-Icons
                tabs: [
                  GButton(
                    icon: Icons.search_outlined,
                    text: 'Search',
                    iconColor: theme.uncertainColor, // Nicht ausgewählte Icons
                    iconActiveColor: theme.tertiaryColor, // Aktives Icon
                  ),
                  GButton(
                    icon: Icons.favorite,
                    text: ' Favorites',
                    iconColor: theme.uncertainColor, // Nicht ausgewählte Icons
                    iconActiveColor: theme.tertiaryColor, // Aktives Icon
                  ),
                  GButton(
                    icon: Icons.settings,
                    text: ' Settings',
                    iconColor: theme.uncertainColor, // Nicht ausgewählte Icons
                    iconActiveColor: theme.tertiaryColor, // Aktives Icon
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
