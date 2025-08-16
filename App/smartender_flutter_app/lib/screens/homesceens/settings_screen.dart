import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/components/settings_tile.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/account_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/bottle_slot_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/create_drink_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/manage_drinks_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/manage_ingredients_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/manage_roles_screen.dart';
import 'package:smartender_flutter_app/screens/homesceens/settingsscreens/theme_screen.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../../provider/theme_provider.dart';

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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;


    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 30,),
/*            SettingsTile(
              title: "Account",
              icon: Icons.person,
              onTap: () => _navigateToScreen(context, const AccountScreen()),
            ),*/
            SettingsTile(
              title: "Bottle Slots",
              icon: Icons.local_drink,
              onTap: () => _navigateToScreen(context, const BottleSlotsScreen()),
            ),
/*            SettingsTile(
              title: "Manage Roles",
              icon: Icons.admin_panel_settings,
              onTap: () => _navigateToScreen(context, const ManageRolesScreen()),
            ),*/
            SettingsTile(
              title: "Manage Drinks",
              icon: Icons.local_bar,
              onTap: () => _navigateToScreen(context, const ManageDrinksScreen()),
            ),
            SettingsTile(
              title: "Manage Ingredients",
              icon: Icons.liquor,
              onTap: () => _navigateToScreen(context, const ManageIngredientsScreen()),
            ),
            SettingsTile(
              title: "Theme",
              icon: Icons.color_lens,
              onTap: () => _navigateToScreen(context, const ThemeScreen()),
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
