import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/components/settings_tile.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/account_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/bottle_slot_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/language_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/manage_roles_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/theme_screen.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SettingsTile(
              title: "Account",
              icon: Icons.person,
              onTap: () => _navigateToScreen(context, const AccountScreen()),
            ),
            SettingsTile(
              title: "Bottle Slots",
              icon: Icons.local_drink,
              onTap: () => _navigateToScreen(context, const BottleSlotsScreen()),
            ),
            SettingsTile(
              title: "Manage Roles",
              icon: Icons.admin_panel_settings,
              onTap: () => _navigateToScreen(context, const ManageRolesScreen()),
            ),
            SettingsTile(
              title: "Theme",
              icon: Icons.color_lens,
              onTap: () => _navigateToScreen(context, const ThemeScreen()),
            ),
            SettingsTile(
              title: "Language",
              icon: Icons.language,
              onTap: () => _navigateToScreen(context, const LanguageScreen()),
            ),
            SettingsTile(
              title: "Sign out",
              icon: Icons.logout,
              isLogout: true,
              onTap: () {
                AuthService().signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
