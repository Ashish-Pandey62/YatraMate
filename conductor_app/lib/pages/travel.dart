import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:jwt_decode/jwt_decode.dart'; // Import the JWT decode package
import 'dart:async'; // For the delay
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:conductor_app/utils/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_ignorebatteryoptimization/flutter_ignorebatteryoptimization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:conductor_app/utils/map_adjust.dart';

// Global variable to store current tour info
Map<String, dynamic>? currentTour; // Null means no tour is active

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  _TravelPageState createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  QRViewController? _controller;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  late String baseUrl;
  late String qrValidateUrl;
  late String tourCreateUrl;
  late String endTourUrl;
  late String? token;
  late String? userType;
  late String activeTourUrl;
  TextEditingController sourceController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController transit1Controller = TextEditingController();
  TextEditingController transit2Controller = TextEditingController();

  // Function to show the Map Adjuster for source or destination coordinates
  Future<void> _openMapAdjuster(TextEditingController controller) async {
    // Get the initial coordinates (or default to a location if empty)
    String text = controller.text;
    double lat = 27.7172; // Default latitude (Kathmandu)
    double lng = 85.3240; // Default longitude (Kathmandu)

    if (text.isNotEmpty) {
      // You can use an API to get coordinates from the text (e.g., OpenRouteService)
      // For simplicity, let's assume the coordinates are predefined here.
      // You can replace this with a real lookup or validation logic.
      // Fetch coordinates for the location (you can use your existing API logic here)
      lat = 27.7172; // Replace with actual lat from user input
      lng = 85.3240; // Replace with actual lng from user input
    }

    final newLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapAdjusterScreen(
          initialPosition: LatLng(lat, lng),
        ),
      ),
    );

    if (newLocation != null && newLocation is LatLng) {
      // Update the text field with the new coordinates
      controller.text = '${newLocation.latitude}, ${newLocation.longitude}';
    }
  }

  //remove battery optimization
  final _flutterIgnorebatteryoptimizationPlugin =
  FlutterIgnorebatteryoptimization();
  Future<void> openIgnorebatteryoptimizationPlugin() async {
    String ignoreBatteryOptimization;
    try {
      ignoreBatteryOptimization = await _flutterIgnorebatteryoptimizationPlugin
          .showIgnoreBatteryOptimizationSettings() ??
          'Unknown ignoreBatteryOptimization';
    } on PlatformException {
      ignoreBatteryOptimization = 'Failed to show ignoreBatteryOptimization.';
    }
    if (!mounted) return;
  }

  Future<void> openIsBatteryOptimizationDisabledPlugin() async {
    String? isBatteryOptimizationDisabled;
    //print("isBatteryOptimizationDisabled: $isBatteryOptimizationDisabled");
    try {
      isBatteryOptimizationDisabled =
      await _flutterIgnorebatteryoptimizationPlugin
          .isBatteryOptimizationDisabled() ==
          true
          ? "Disabled"
          : "Enabled";
      print("isBatteryOptimizationDisabled: $isBatteryOptimizationDisabled");

      // Disabled ==> means you have set no restrictions
      // Enabled ==> means you have not set no restrictions
    } on PlatformException {
      isBatteryOptimizationDisabled =
      'Failed to show ignoreBatteryOptimization.';
    }
    if (!mounted) return;
  }

  Future<void> openLocationSettings() async {
    SettingsOpener.openLocationSettings();
  }

  @override
  void initState() {
    super.initState();
    _initializeVariables();
  }

  Future<void> _initializeVariables() async {
    startBackgroundService();
    baseUrl = dotenv.env['SITE_URL'] ?? '';
    qrValidateUrl = '$baseUrl/api/validate-qr/';
    tourCreateUrl = '$baseUrl/api/activate-tour/';
    endTourUrl = '$baseUrl/api/end-tour/';
    activeTourUrl = '$baseUrl/api/active-tour/';
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    userType = prefs.getString('user_type');
    // Check if there's an active tour
    final response = await http.get(
      Uri.parse(activeTourUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['is_active'] == true) {
        setState(() {
          currentTour = data['tour_data'];
        });
      } else {
        setState(() {
          currentTour = null;
        });
      }
    } else {
      print('Error fetching active tour: ${response.body}');
    }
  }

  Future<void> _endTour() async {
    if (currentTour == null) return;

    final response = await http.post(
      Uri.parse(endTourUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tour_id': currentTour!['id'],
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        currentTour = null;
        // Stop the background service when the tour ends
        stopBackgroundService();
      });
    } else {
      print('Error ending tour: ${response.body}');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'APP Permission -> location -> Allow all the time \n Battery Saver -> No Restrictions'),
          actions: <Widget>[
            // Deny button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Deny'),
            ),
            // OK button (open settings)
            TextButton(
              onPressed: () {
                openAppSettings(); // Open app settings
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void locationService(BuildContext context) async {
    // Initialize the background service
    LocationPermission permission;
    bool serviceEnabled;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      //snackbar showing location service is disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled.'),
        ),
      );
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('Location permissions are denied.'),
    //       ),
    //     );
    //     return Future.error('Location permissions are denied.');
    //   }
    // }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Location permissions are permanently denied, we cannot request permissions.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openLocationSettings();
            },
          ),
        ),
      );
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.denied) {
      showPermissionDialog(context);
      return Future.error(
          'Location permissions are set to "While in Use". Please enable "Always".');
    }

    if (mounted) {
      AlarmPermissionChecker checker = AlarmPermissionChecker();
      if (Platform.isAndroid) {
        bool hasPermission = await checker.checkScheduleExactAlarmPermission();
        if (!hasPermission) {
          PermissionHelper.requestScheduleExactAlarmPermission();
        }
      }

      // Start the background service
      startBackgroundService();
    }
  }

  // Function to handle QR scan result
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
      controller.scannedDataStream.listen((scanData) async {
        if (scanData.code != null) {
          final jwtToken = scanData.code.toString();
          print('Scanned JWT Token: $jwtToken');

          // Decode the JWT token to extract information
          try {
            final decodedToken = Jwt.parseJwt(jwtToken);
            final username = decodedToken['sub'] as String;
            final price =
                double.tryParse(decodedToken['price'].toString()) ?? 0;

            final iat = int.tryParse(decodedToken['iat'].toString()) ?? 0;
            final exp = int.tryParse(decodedToken['exp'].toString()) ?? 0;

            // Convert timestamp to DateTime
            final timeCreated = DateTime.fromMillisecondsSinceEpoch(iat);
            // Update transaction with decoded information and "Pending" status

            setState(() {
              currentTour!['transactions'].add({
                "traveler_name": username.toString(),
                "timeCreated": timeCreated.toString(),
                "amount": price.toString(),
                "status": "Pending",
              });
            });
            _controller?.dispose();
            Navigator.pop(context); // Close the scanner UI

            // Validate the JWT token on the server
            final response = await http.post(
              Uri.parse(qrValidateUrl),
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'token': jwtToken,
                'tour_id': currentTour!['id'],
              }),
            );
            if (response.statusCode != 200) {
              String error = jsonDecode(response.body)['message'];
              print('Error validating QR code: ${response.body}');
              setState(() {
                currentTour!['transactions'].last['status'] = 'Failed';
                currentTour!['transactions'].last['error'] = error;
              });
              return;
            } else {
              setState(() {
                currentTour!['transactions'].last['status'] = 'Success';
              });
            }
          } catch (e) {
            print('Error decoding JWT: $e');
            // Optionally show an error message if JWT decoding fails
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: currentTour == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No active tour.',
                    style: TextStyle(
                        fontSize: 24, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  ElevatedButton(
                    onPressed: () => _openMapAdjuster(sourceController),
                    child: const Text('Select Source'),
                  ),
                  if (sourceController.text.isNotEmpty)
                    Text('Source: ${sourceController.text}'),
                  ElevatedButton(
                    onPressed: () => _openMapAdjuster(transit1Controller),
                    child: const Text('Select Transit'),
                  ),
                  if (transit1Controller.text.isNotEmpty)
                    Text('Source: ${transit1Controller.text}'),
                  ElevatedButton(
                    onPressed: () => _openMapAdjuster(destinationController),
                    child: const Text('Select Destination'),
                  ),
                  if (destinationController.text.isNotEmpty)
                    Text('Source: ${destinationController.text}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      print(destinationController.text);
                      // final sourceData =
                      //     await fetchLocationData(sourceController.text);
                      // final destinationData =
                      //     await fetchLocationData(destinationController.text);

                      // // Extracting coordinates (or use other data based on your needs)
                      // final sourceCoordinates =
                      //     sourceData['features'][0]['geometry']['coordinates'];
                      // final destinationCoordinates = destinationData['features']
                      //     [0]['geometry']['coordinates'];
                      // print(destinationCoordinates);
                      // final response = await http.post(
                      //   Uri.parse(tourCreateUrl),
                      //   headers: {
                      //     'Authorization': 'Token $token',
                      //     'Content-Type': 'application/json',
                      //   },
                      //   body: jsonEncode({
                      //     "source_lat":
                      //         sourceCoordinates[1], // Pokhara latitude
                      //     "source_lng":
                      //         sourceCoordinates[0], // Pokhara longitude
                      //     "destination_lat":
                      //         destinationCoordinates[1], // Kathmandu latitude
                      //     "destination_lng":
                      //         destinationCoordinates[0] // Kathmandu longitude
                      //   }),
                      // );
                      final response = await http.post(
                        Uri.parse(tourCreateUrl),
                        headers: {
                          'Authorization': 'Token $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          "source_lat": sourceController.text
                              .split(',')[0], // Pokhara latitude
                          "source_lng": sourceController.text
                              .split(',')[1], // Pokhara longitude
                          "destination_lat": destinationController.text
                              .split(',')[0], // Kathmandu latitude
                          "destination_lng": destinationController.text
                              .split(',')[1], // Kathmandu longitude
                        }),
                      );

                      if (response.statusCode != 200) {
                        print(response.body);
                      }

                // Logic to create a new tour
                setState(() {
                  final data = jsonDecode(response.body);
                  currentTour = (data['tour_data']);
                });

                      locationService(context);
                    },
                    child: const Text('Create New Tour'),
                  ),
                ],
              )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Current Tour: ${currentTour!['id']}',
                style: const TextStyle(
                    fontSize: 24, color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currentTour!['transactions'].length,
                itemBuilder: (context, index) {
                  final transaction = currentTour!['transactions'][index];
                  return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username: ${transaction['traveler_name']}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          Text(
                            'Price: ${transaction['amount']}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            transaction['status'],
                            style: TextStyle(
                              color: transaction['status'] == 'Success' ||
                                  transaction['status'] == 'Completed'
                                  ? Colors.green
                                  : transaction['status'] == 'Pending'
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (transaction['status'] == 'Failed')
                            Text(
                              transaction['error'],
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 6,
                              ),
                            ),
                        ],
                      ));
                },
              ),
            ),
            ElevatedButton(
              onPressed: _endTour,
              child: const Text('End Tour'),
            ),
          ],
        ),
      ),
      // Floating Action Button to add a new transaction
      floatingActionButton: currentTour == null
          ? null
          : FloatingActionButton(
        onPressed: () {
          // Open QR code scanner when clicked
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: SizedBox(
                width: double.infinity,
                height: 400,
                child: QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}