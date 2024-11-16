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

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int myIndex = 0; // Default page index
  String userRole = 'traveller'; // Default role
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;


  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3)
        .chain(CurveTween(curve: Curves.bounceOut))
        .animate(_animationController);
  }

  Future<void> _loadUserRole() async {
    myIndex =1;
    initializeService(); // Initialize background service
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_type') ?? 'traveller'; // Load user role
    });
  }

  List<Widget> getWidgetList() {
    return [
      
      userRole == 'conductor' ? const TravelPage() : const PaymentPage(),
       const HomePage(),
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
          if (index != myIndex) {
            setState(() {
              myIndex = index;
            });
            _animationController
                ..reset()
                ..forward(); // Trigger the bounce effect
            }
        },
        currentIndex: myIndex,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.scale(
                scale: myIndex == 0 ? _bounceAnimation.value : 1.0,
                child: const Icon(FontAwesomeIcons.bus),
              ),
            ),
            label: 'Travel',
          ),
          BottomNavigationBarItem(
            icon: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.scale(
                scale: myIndex == 1 ? _bounceAnimation.value : 1.0,
                child: const Icon(FontAwesomeIcons.house),
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.scale(
                scale: myIndex == 2 ? _bounceAnimation.value : 1.0,
                child: const Icon(FontAwesomeIcons.map),
              ),
            ),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
        


