import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:conductor_app/utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
   bool _obscurePassword = true; // State variable to toggle password visibility

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setString('auth_token', '');
    await prefs.setString('username', '');
    await deletePrivateKey();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    await _logout();

    final String baseUrl = dotenv.env['SITE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      _showSnackBar('SITE_URL not found in .env');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final String loginUrl = '$baseUrl/api/accounts/login/';
    final data = {
      'username': _usernameController.text,
      'password': _passwordController.text,
    };

    // Send POST request with the data
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final String token = responseData['token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_type', responseData['user']['user_type']);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', responseData['user']['username']);

      _showSnackBar('Login successful!', isSuccess: true);

      Navigator.pushReplacementNamed(context, '/main_page');
    } else {
      _showSnackBar('Login failed: ${response.body}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      backgroundColor: isSuccess ? const Color.fromARGB(255, 13, 161, 21) : Colors.red,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the keyboard is visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white, // Set background color
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              // Added SingleChildScrollView here
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Displaying the logo image
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 20),

                  // "Welcome Back" text
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // "Log into your account" text
                  const Text(
                    'Log into your account',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Username text field
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter User Name',
                      labelText: 'User Name',
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password text field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Use the state variable
                    decoration: InputDecoration(
                      hintText: 'Enter Password',
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                       suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
                       ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Login button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(33, 150, 243, 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 10),
                  // Conditionally hide "Not Registered !" or "Register Now" when keyboard is visible
                  if (!isKeyboardVisible)
                    Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Not registered? Register now',
                            style: TextStyle(
                                color: Color.fromRGBO(33, 150, 243, 1)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
