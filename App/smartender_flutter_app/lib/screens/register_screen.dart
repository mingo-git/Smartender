import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import '../components/my_textfield.dart';
import '../components/my_button.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
import 'login_screen.dart'; // Ensure this path is correct for your project

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();
  final AuthService _authService = AuthService();

  String errorMessage = '';

  void registerUser(BuildContext context) async {
    setState(() {
      errorMessage = '';
    });

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final passwordAgain = passwordAgainController.text;

    // Validation
    if (username.isEmpty || email.isEmpty || password.isEmpty || passwordAgain.isEmpty) {
      setState(() {
        errorMessage = 'All fields are required.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        errorMessage = 'Password must be at least 8 characters long.';
      });
      return;
    }

    if (password.length > 72) {
      setState(() {
        errorMessage = 'Password must not exceed 72 characters.';
      });
      return;
    }

    if (password != passwordAgain) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }

    final result = await _authService.register(username, email, password);

    if (result['success']) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: defaultBorderRadius,
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 100,
              child: Center(
                child: const Text(
                  'Registration successful.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: MyButton(
                  text: 'Go to Login',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        errorMessage = result['error'] ?? 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: theme.tertiaryColor,
            size: 40,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Icon(Icons.lock, size: 100, color: theme.tertiaryColor,),
              const SizedBox(height: 50),
              Text(
                'Create an account',
                style: TextStyle(color: theme.tertiaryColor, fontSize: 16,),
              ),
              const SizedBox(height: 25),
              MyTextField(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 30),
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: passwordAgainController,
                hintText: 'Password again',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: errorMessage.isNotEmpty
                    ? Text(
                  errorMessage,
                  style: TextStyle(color: theme.falseColor, fontSize: 12),
                )
                    : const SizedBox(height: 16),
              ),
              const SizedBox(height: 35),
              MyButton(
                text: 'Register',
                onTap: () => registerUser(context),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
