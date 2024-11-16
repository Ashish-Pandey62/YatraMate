import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conductor_app/utils/utils.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String _selectedUserType = 'traveler';

  // State variables to toggle password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setString('auth_token', '');
    await prefs.setString('username', '');
    await deletePrivateKey();
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });
    await _logout();
    final String baseUrl = dotenv.env['SITE_URL'] ?? '';
    final String signupUrl = '$baseUrl/api/accounts/signup/';

    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SITE_URL not found in .env')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final data = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password2': _password2Controller.text,
      'name': _nameController.text,
      'user_type': _selectedUserType,
    };

    final response = await http.post(
      Uri.parse(signupUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final String token = responseData['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_type', responseData['user']['user_type']);
      await prefs.setString('username', responseData['user']['username']);
      await prefs.setBool('isLoggedIn', true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign Up successful!'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.pushReplacementNamed(context, '/main_page');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white, // Set AppBar background color to white
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
    ),
    backgroundColor: Colors.white, // Set Scaffold background color to white
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add the large title at the top
          const Center(
            child: Text(
              'Create a New Account',
              style: TextStyle(
                fontSize: 28, // Large font size
                fontWeight: FontWeight.bold, // Bold text
                color: Colors.black87,
              ),
              textAlign: TextAlign.center, // Center the text
            ),
          ),
          const SizedBox(height: 20), // Add space below the title
          
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'traveler',
                  groupValue: _selectedUserType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedUserType = value!;
                    });
                  },
                ),
                const Text('Traveler'),
                Radio<String>(
                  value: 'conductor',
                  groupValue: _selectedUserType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedUserType = value!;
                    });
                  },
                ),
                const Text('Conductor'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration:  const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration:  InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration:  InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
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
          const SizedBox(height: 10),
          TextField(
            controller: _password2Controller,
            obscureText: _obscureConfirmPassword,
            decoration:  InputDecoration(
              labelText: 'Confirm Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

}
