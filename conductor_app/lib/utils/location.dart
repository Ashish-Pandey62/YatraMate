import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<Map<String, dynamic>> fetchLocationData(String query) async {
  final apiKey =
      '5b3ce3597851110001cf6248966817b9279641689b1420ce56329a55'; // Replace with your API key
  final url = Uri.parse(
      'https://api.openrouteservice.org/geocode/search?api_key=$apiKey&text=$query');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Failed to load location data');
  }
}

class SettingsOpener {
  static const _platform =
      MethodChannel('com.example.conductor_app/permission');

  // Method to call the platform channel to open location settings
  static Future<void> openLocationSettings() async {
    try {
      await _platform.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      print('Failed to open location settings: ${e.message}');
    }
  }
}

class PermissionHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.conductor_app/permission');

  static Future<void> requestScheduleExactAlarmPermission() async {
    try {
      await _channel.invokeMethod('requestScheduleExactAlarm');
    } on PlatformException catch (e) {
      print("Error requesting permission: ${e.message}");
    }
  }
}

class AlarmPermissionChecker {
  static const platform = MethodChannel('com.example.conductor_app/permission');

  Future<bool> checkScheduleExactAlarmPermission() async {
    try {
      final bool result =
          await platform.invokeMethod('checkScheduleExactAlarmPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    }
  }
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    //show snackbar if location services are disabled
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: const Text(
            'Location services are disabled. Please enable them in settings.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            SettingsOpener.openLocationSettings();
          },
        ),
      ),
    );
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: false,
      autoStartOnBoot: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

void startBackgroundService() async {
  final service = FlutterBackgroundService();

  bool isRunning = await service.isRunning(); // Check if service is running
  if (!isRunning) {
    await service.startService();
    print('Service started.');
  } else {
    print('Service is already runninggggggggg.');
  }
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  service.on('stop').listen((event) {
    service.stopSelf(); // Properly stops the background service
    print("Background service has been stopped.");
  });

  String baseUrl = "http://192.168.75.99:8000";
  String updateLocationUrl = '$baseUrl/api/update-location/';
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  print("flutter service is running");

  Timer.periodic(const Duration(seconds: 3), (timer) async {
    print("flutter service is running");
    try {
      Position position = await Geolocator.getCurrentPosition();
      final response = await http.post(
        Uri.parse(updateLocationUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
        }),
      );
    } catch (e) {
      print(e);
    }
  });
}
