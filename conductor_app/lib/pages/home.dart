import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:conductor_app/utils/location.dart';
import 'package:conductor_app/utils/utils.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool connection = true;
  bool _isLoading = false;
  final String baseUrl = dotenv.env['SITE_URL'] ?? '';
  String userName = "User";
  double totalBalance = 0.00;
  int totalTrips = 0;
  List<Map<String, dynamic>> transactionHistory = [];
  String? user_type = 'traveler';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        // User has scrolled to the bottom of the list
        _fetchData();
      }
    });
    _fetchData();
    _checkInternetConnection();
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

  Future<void> _checkInternetConnection() async {
    // Check for network connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        connection = false;
      });
      return;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    print('Fetching data');
    final String detailUrl = '$baseUrl/api/user-details/';
    final String transactionUrl = '$baseUrl/api/transaction-history/';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    setState(() {
      user_type = prefs.getString('user_type');
      print(user_type);
    });

    try {
      final detailResponse = await http.get(
        Uri.parse(detailUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (detailResponse.statusCode == 200) {
        final data = jsonDecode(detailResponse.body);
        setState(() {
          userName = data['name'];
          totalBalance = double.parse(data['balance']);
          totalTrips = data['total_trips'];
        });
      }

      final transactionResponse = await http.get(
        Uri.parse(transactionUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (transactionResponse.statusCode == 200) {
        final List transactions = jsonDecode(transactionResponse.body);
        setState(() {
          transactionHistory = transactions.map<Map<String, dynamic>>((tx) {
            return {
              "status": tx['status'],
              "amount": double.parse(tx['amount']),
              "date": tx['transaction_date'],
              "traveler_name": tx['traveler_name'],
              "conductor_name": tx['conductor_name'],
              "tour_id": tx['tour_id']
            };
          }).toList();
        });
      } else {
        print(transactionResponse.statusCode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load transactions')),
        );
      }
    } catch (error) {
      setState(() {
        connection = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
        'Yatra Mate',
        style: TextStyle(
          fontSize: 30, // Adjust font size as needed
          fontWeight: FontWeight.bold, // Optional: font styling
          color: Colors.black, // Optional: adjust text color
        ),
      ),
        backgroundColor: Color.fromARGB(255, 255, 225, 255),
         actions: [
          IconButton(
            icon: const Icon(Icons.logout,
             color: Colors.white, // Set the icon color to white
    size: 25, // Increase the icon size (adjust as needed)
            ),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
            
           
      body: !connection
          ? const Center(
              child: Text("No Internet Connection", 
              style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $userName',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rs ${totalBalance.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Trips',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$totalTrips',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                child: const Text(
                                  'Load Balance',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                child: const Text(
                                  'Transfer Balance',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Transaction History',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height:
                          300, // Set a fixed height for the transaction history
                      child: ListView.builder(
                        itemCount: transactionHistory.length,
                        itemBuilder: (context, index) {
                          final transaction = transactionHistory[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            leading: Icon(
                              transaction['title'] == 'failed'
                                  ? Icons.circle
                                  : transaction['title'] == 'pending'
                                      ? Icons.circle
                                      : user_type == 'traveler'
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                              color: transaction['title'] == 'failed'
                                  ? Colors.red
                                  : transaction['title'] == 'pending'
                                      ? Colors.yellow
                                      : user_type == 'traveler'
                                          ? Colors.blue
                                          : Colors.green,
                            ),
                            title: Text(
                              user_type == 'traveler'
                                  ? '${transaction['conductor_name']}'
                                  : '${transaction['traveler_name']}',
                            ),
                            subtitle: Text(
                              '${DateTime.parse(transaction['date']).toLocal().toString().split(' ')[0]}  ${DateTime.parse(transaction['date']).toLocal().toString().split(' ')[1].substring(0, 5)}',
                            ),
                            trailing: Text(
                              "${transaction['amount'] > 0 ? '+' : ''}Rs${transaction['amount'].abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                color: user_type == 'traveler'
                                    ? Colors.blue
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
