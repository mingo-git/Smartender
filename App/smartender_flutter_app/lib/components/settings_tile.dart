import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';

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
          foregroundColor: isLogout ? Colors.white : Colors.black,
          backgroundColor: isLogout ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: isLogout
              ? BorderSide.none
              : const BorderSide(color: Colors.black),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isLogout ? Colors.white : Colors.black),
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
