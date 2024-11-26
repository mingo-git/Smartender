import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/components/my_textfield.dart';
import 'package:smartender_flutter_app/components/my_button.dart';
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

  void signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result['success']) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        errorMessage = result['error'] ?? 'Google sign-in failed.';
      });
    }
  }

  void signInWithApple() async {
    final result = await _authService.signInWithApple();
    if (result['success']) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        errorMessage = result['error'] ?? 'Apple sign-in failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: errorMessage.isNotEmpty
                      ? Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )
                      : const SizedBox(height: 16),
                ),
                const SizedBox(height: 25),
                MyButton(
                  text: 'Sign In',
                  onTap: signUserIn,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.75,
                          color: Colors.grey[600],
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
                          thickness: 0.75,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height:15,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: signInWithGoogle,
                      child: const SquareTile(imagePath: 'lib/images/google.png'),
                    ),
                    const SizedBox(width: 25),
                    GestureDetector(
                      onTap: signInWithApple,
                      child: const SquareTile(imagePath: 'lib/images/apple.png'),
                    ),
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
