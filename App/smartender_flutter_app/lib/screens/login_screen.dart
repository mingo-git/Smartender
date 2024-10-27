import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/components/my_textfield.dart';
import 'package:smartender_flutter_app/components/signIn_button.dart';
import 'package:smartender_flutter_app/components/square_tile.dart';
import 'package:smartender_flutter_app/screens/register_screen.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';

import '../config/constants.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameOrEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Error messages
  String errorMessage = '';

  void signUserIn() async {
    setState(() {
      // Reset error message
      errorMessage = '';
    });

    final usernameOrEmail = usernameOrEmailController.text.trim();
    final password = passwordController.text;

    if (usernameOrEmail.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email or username.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your password.';
      });
      return;
    }

    final result = await _authService.signIn(usernameOrEmail, password);

    if (result['success']) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        errorMessage = result['error'] ?? 'Login failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      resizeToAvoidBottomInset: true, // Anpassung bei eingeblendeter Tastatur
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 50),
                Text(
                  'Welcome back, you\'ve been missed!',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: usernameOrEmailController,
                  hintText: 'Email or username',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                // Error message or placeholder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: errorMessage.isNotEmpty
                      ? Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )
                      : const SizedBox(height: 16), // Placeholder with fixed height
                ),
                const SizedBox(height: 25),
                MyLoginButton(
                  text: 'Sign In',
                  onTap: signUserIn,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(imagePath: 'lib/images/google.png'),
                    SizedBox(width: 25),
                    SquareTile(imagePath: 'lib/images/apple.png'),
                  ],
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Register now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
