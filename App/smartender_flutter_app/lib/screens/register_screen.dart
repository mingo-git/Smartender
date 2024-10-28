import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/services/auth_service.dart';
import '../components/my_textfield.dart';
import '../components/signIn_button.dart';
import '../config/constants.dart';
import 'login_screen.dart'; // Stelle sicher, dass der richtige Pfad zur LoginScreen-Datei hier korrekt ist

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();

  final AuthService _authService = AuthService();

  void registerUser(BuildContext context) async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final passwordAgain = passwordAgainController.text;

    //Termination criteria
    // TODO: Agree on length and adjust to other criteria
    if(password.length < 8){
      return;
    }
    else if (password != passwordAgain){
      return;
    }

    bool success = await _authService.register(username, email, password);

    if (success) {
      // Navigation zur nächsten Seite
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Fehlerbehandlung
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login fehlgeschlagen. Bitte überprüfe deine Eingaben.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      appBar: AppBar(
        backgroundColor: backgroundcolor, // Kannst du anpassen
        elevation: 0, // Keine Schatteneffekte
        leading: IconButton(
          icon: const Icon(
              Icons.close,
              color: Colors.black,
              size: 40,
          ), // Das "X"-Symbol
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()), // Zur LoginScreen navigieren
            );
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 0,
          ),
          const Icon(
            Icons.lock,
            size: 100,
          ),
          const SizedBox(
            height: 50,
          ),
          Text(
            'Welcome back you\'ve been missing',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(
            height: 25,
          ),
          MyTextField(
            controller: usernameController,
            hintText: 'username',
            obscureText: false,
          ),
          const SizedBox(height: 10),
          MyTextField(
            controller: emailController,
            hintText: 'email',
            obscureText: false,
          ),
          const SizedBox(height: 30),
          MyTextField(
            controller: passwordController,
            hintText: 'password',
            obscureText: true,
          ),
          const SizedBox(height: 10),
          MyTextField(
            controller: passwordAgainController,
            hintText: 'password again',
            obscureText: true,
          ),
          const SizedBox(
            height: 35,
          ),
          MyLoginButton(
            text: 'Register',
            onTap: () => registerUser(context),
          ),
          const SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}
