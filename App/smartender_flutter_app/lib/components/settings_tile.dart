import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';

import '../provider/theme_provider.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final bool isLogout;
  final IconData icon;
  final VoidCallback? onTap;

  const SettingsTile({
    Key? key,
    required this.title,
    required this.icon,
    this.isLogout = false,
    this.onTap,
  }) : super(key: key);

  void _handleLogout(BuildContext context) {
    final AuthService authService = AuthService();
    authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          if (isLogout) {
            _handleLogout(context);
          } else {
            onTap?.call();
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isLogout ? theme.primaryColor : theme.tertiaryColor,
          backgroundColor: isLogout ? theme.tertiaryColor : theme.primaryColor,
          minimumSize: const Size(double.infinity, 70),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: isLogout
              ? BorderSide.none
              : BorderSide(color: theme.tertiaryColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isLogout ? theme.primaryColor : theme.tertiaryColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
