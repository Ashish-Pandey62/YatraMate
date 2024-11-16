import 'package:conductor_app/pages/home.dart';
import 'package:conductor_app/pages/travel.dart';
import 'package:conductor_app/pages/payment_page.dart'; // Import PaymentPage
import 'package:conductor_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conductor_app/pages/map.dart';
import 'package:conductor_app/utils/location.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int myIndex = 0;
  String userRole = 'traveller'; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    initializeService(); // Initialize background service
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_type') ?? 'traveller'; // Load user role
    });
  }

  List<Widget> getWidgetList() {
    return [
      const HomePage(),
      userRole == 'conductor' ? const TravelPage() : const PaymentPage(),
      const MapPage(),
    ];
  }

  // Function to handle logout and navigate to login page
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Set login status to false
    await prefs.setString('auth_token', ''); // Clear auth token
    await prefs.setString('username', ''); // Clear username
    await deletePrivateKey(); // Delete private key
    stopBackgroundService(); // Stop background service
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatra Mate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight,
          child: getWidgetList()[myIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        currentIndex: myIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.bus),
            label: 'Travel',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
