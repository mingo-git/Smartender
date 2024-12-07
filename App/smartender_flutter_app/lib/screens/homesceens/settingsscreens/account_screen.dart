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

  TextEditingController usernameController = TextEditingController(text: "Beispielname");
  TextEditingController emailController = TextEditingController(text: "beispiel@gmail.com");
  TextEditingController passwordController = TextEditingController(text: "******");

  // Controllers for password fields
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // Original values for change detection
  String originalUsername = "Beispielname";
  String originalEmail = "beispiel@gmail.com";
  String originalPassword = "******";

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
          passwordController.text != originalPassword);
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
    // TODO: Implement account update logic here
    setState(() {
      hasUnsavedChanges = false;
      originalUsername = usernameController.text;
      originalEmail = emailController.text;
      originalPassword = passwordController.text;
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const Spacer(),
              if (hasUnsavedChanges)
                ElevatedButton(
                  onPressed: updateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 45, // Fixed height to prevent shifting
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                  controller: controller,
                  obscureText: isPassword,
                  onChanged: (_) => _checkForChanges(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 20),
                )
                    : Text(
                  controller.text,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField("Old Password", oldPasswordController),
        const SizedBox(height: 10),
        _buildPasswordField("New Password", newPasswordController),
        const SizedBox(height: 10),
        _buildPasswordField("Confirm New Password", confirmPasswordController),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: true,
          onChanged: (_) => _checkForChanges(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          style: const TextStyle(fontSize: 20),
        ),
      ],
    );
  }
}
