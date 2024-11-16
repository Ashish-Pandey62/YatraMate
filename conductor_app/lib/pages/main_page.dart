import 'package:conductor_app/pages/home.dart';
import 'package:conductor_app/pages/travel.dart';
import 'package:conductor_app/pages/payment_page.dart'; // Import PaymentPage
import 'package:conductor_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conductor_app/pages/map.dart';
import 'package:conductor_app/utils/location.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Default page index
  String userRole = 'traveller'; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_type') ?? 'traveller'; // Load user role
    });
  }

  List<Widget> getPages() {
    return [
      const HomePage(), // Index 0: Home Page
      userRole == 'conductor'
          ? const TravelPage()
          : const PaymentPage(), // Index 1: Travel/Payment based on role
      const MapPage(), // Index 2: Map Page
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Yatra Mate'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: _logout,
      //       tooltip: 'Logout',
      //     ),
      //   ],
      // ),

      body: getPages()[
          _currentIndex], // Render content based on the selected index
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color.fromARGB(255, 153, 112, 225),
        items:[
        Icon(FontAwesomeIcons.house,
        color: Colors.white),

        Icon(FontAwesomeIcons.bus,
        color: Colors.white
        ),

        Icon(FontAwesomeIcons.map,
        color: Colors.white),

      ],
      index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update index to change the page
          });
        },
      ),
    );
  }
}
