import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import '../components/my_textfield.dart';
import '../components/signIn_button.dart';
import '../config/constants.dart';
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
      // Navigate to the login screen after successful registration
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Display error message
      setState(() {
        errorMessage = result['error'] ?? 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      appBar: AppBar(
        backgroundColor: backgroundcolor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black,
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 0),
          const Icon(Icons.lock, size: 100),
          const SizedBox(height: 50),
          Text(
            'Welcome back, you\'ve been missed!',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: errorMessage.isNotEmpty
                ? Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
                : const SizedBox(height: 16), // Placeholder with fixed height
          ),
          const SizedBox(height: 35),
          MyLoginButton(
            text: 'Register',
            onTap: () => registerUser(context),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
