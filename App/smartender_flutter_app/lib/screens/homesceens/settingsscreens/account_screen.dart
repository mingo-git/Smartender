import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isEditingUsername = false;
  bool isEditingEmail = false;
  bool isEditingPassword = false;
  bool hasUnsavedChanges = false;

  bool showNewPassword = false;
  bool showConfirmPassword = false;

  TextEditingController usernameController = TextEditingController(text: "Beispielname");
  TextEditingController emailController = TextEditingController(text: "beispiel@gmail.com");
  TextEditingController passwordController = TextEditingController(text: "******");

  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  String originalUsername = "Beispielname";
  String originalEmail = "beispiel@gmail.com";
  String originalPassword = "******";

  String errorMessage = '';

  void _handleEditToggle(VoidCallback onEdit) {
    setState(() {
      onEdit();
      _checkForChanges();
    });
  }

  void _checkForChanges() {
    setState(() {
      hasUnsavedChanges = (usernameController.text != originalUsername ||
          emailController.text != originalEmail ||
          passwordController.text != originalPassword ||
          newPasswordController.text.isNotEmpty);
    });
  }

  void _cancelPasswordEditing() {
    setState(() {
      isEditingPassword = false;
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      errorMessage = '';
    });
  }

  Future<void> _showDiscardChangesDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard changes?"),
        content: const Text("You have unsaved changes. Are you sure you want to go back without saving?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    if (result == true) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (hasUnsavedChanges) {
      await _showDiscardChangesDialog();
      return false;
    }
    return true;
  }

  void updateAccount() {
    setState(() {
      errorMessage = '';

      final newPassword = newPasswordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
        if (newPassword.length < 8) {
          errorMessage = 'Password must be at least 8 characters long.';
        } else if (newPassword.length > 72) {
          errorMessage = 'Password must not exceed 72 characters.';
        } else if (newPassword != confirmPassword) {
          errorMessage = 'Passwords do not match.';
        }
      }

      if (errorMessage.isEmpty) {
        hasUnsavedChanges = false;
        originalUsername = usernameController.text;
        originalEmail = emailController.text;
        originalPassword = passwordController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 35),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            "Account",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildEditableField(
                "Username",
                isEditingUsername,
                usernameController,
                    () => _handleEditToggle(() => isEditingUsername = !isEditingUsername),
              ),
              const SizedBox(height: 30),
              _buildEditableField(
                "E-Mail",
                isEditingEmail,
                emailController,
                    () => _handleEditToggle(() => isEditingEmail = !isEditingEmail),
              ),
              const SizedBox(height: 30),
              if (isEditingPassword)
                _buildPasswordFields()
              else
                _buildEditableField(
                  "Password",
                  isEditingPassword,
                  passwordController,
                      () => _handleEditToggle(() => isEditingPassword = !isEditingPassword),
                  isPassword: true,
                ),
              const SizedBox(height: 10),

              // Platzhalter für Fehlermeldungen
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: errorMessage.isNotEmpty
                    ? Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                )
                    : const SizedBox(height: 16),
              ),

              const SizedBox(height: 20),
              if (hasUnsavedChanges)
                ElevatedButton(
                  onPressed: updateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: defaultBorderRadius,
                    ),
                  ),
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, bool isEditing, TextEditingController controller, VoidCallback onEdit, {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEditing ? Colors.white : Colors.transparent, // Hintergrund nur bei Bearbeitung weiß
                      border: isEditing ? Border.all(color: Colors.grey) : null,
                      borderRadius: defaultBorderRadius,
                    ),
                    child: isEditing
                        ? TextField(
                      controller: controller,
                      obscureText: isPassword,
                      onChanged: (_) => _checkForChanges(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      style: const TextStyle(fontSize: 20),
                    )
                        : Text(
                      controller.text,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField("Old Password", oldPasswordController, isCancelButton: true),
        const SizedBox(height: 10),
        _buildPasswordField("New Password", newPasswordController, isToggleable: true, showPassword: showNewPassword),
        const SizedBox(height: 10),
        _buildPasswordField("Confirm New Password", confirmPasswordController, isToggleable: true, showPassword: showConfirmPassword),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {bool isCancelButton = false, bool isToggleable = false, bool showPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: defaultBorderRadius,
                    ),
                    child: TextField(
                      controller: controller,
                      obscureText: !showPassword,
                      onChanged: (_) => _checkForChanges(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                if (isCancelButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelPasswordEditing,
                  ),
                if (isToggleable)
                  IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        if (label == "New Password") {
                          showNewPassword = !showNewPassword;
                        } else if (label == "Confirm New Password") {
                          showConfirmPassword = !showConfirmPassword;
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
