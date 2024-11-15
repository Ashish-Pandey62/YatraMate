import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:conductor_app/utils/location.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  @override
  bool get wantKeepAlive => true; // Keeps the state alive
  //initialize variable to store tours containing bus lat long heading speed
  List<dynamic>? tours;
  // Define latitude and longitude variables
  double latitude = 0.0;
  double longitude = 0.0;
  bool _locationFetched = false;
  double scale = 1.0;
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _updateBusPosition();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await determinePosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      _locationFetched = true;
    });
    mapController.mapEventStream.listen((event) {
      if (event is MapEventScrollWheelZoom ||
          event is MapEventScrollWheelZoom ||
          event is MapEventRotate) {
        // print('Zoom: ${mapController.camera.zoom}');
        setState(() {
          scale = 1 * mapController.camera.zoom * 0.15;
        });
      }
    });
  }

  void _updateBusPosition() async {
    final String baseUrl = dotenv.env['SITE_URL'] ?? '';
    final String toursURL = '$baseUrl/api/all-active-tour/';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    // First time request to server
    final response = await http.get(Uri.parse(toursURL), headers: {
      'Authorization': 'Token $token',
    });

    if (response.statusCode == 200) {
      setState(() {
        tours = jsonDecode(response.body)['data'];
      });
    } else {
      print('Failed to load tours');
    }

    // Every 10 seconds make request to server
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final response = await http.get(Uri.parse(toursURL), headers: {
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        // print(tours);
        setState(() {
          tours = jsonDecode(response.body)['data'];
        });
      } else {
        print('Failed to load tours');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          if (_locationFetched)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 8,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: [
                  for (var tour in tours ?? [])
                    Marker(
                        point: LatLng(
                            double.parse(tour['latitude']) +
                                Random().nextDouble() * 0,
                            double.parse(tour['longitude']) +
                                Random().nextDouble() * 0),
                        child: Transform.scale(
                          scale: scale,
                          child: Transform.rotate(
                              angle: double.parse(tour['heading']),
                              child:
                                  Image(image: AssetImage('./assets/bus.png'))),
                        )),
                ]),

                // MarkerLayer(
                //   markers: [
                //     for (var tour in tours ?? [])
                //       Marker(
                //         point: LatLng(
                //           double.parse(tour['latitude']),
                //           double.parse(tour['longitude']) + 0.005,
                //         ),
                //         child: Transform.scale(
                //           scale: 1,
                //           child: Container(
                //             padding: EdgeInsets.symmetric(
                //                 horizontal: 4.0), // Optional padding
                //             decoration: BoxDecoration(
                //               borderRadius: BorderRadius.circular(4.0),
                //             ),
                //             child: FittedBox(
                //                 fit: BoxFit
                //                     .contain, // Ensures text scales to fit within the box
                //                 child: Transform.rotate(
                //                   angle: double.parse(tour['heading']),
                //                   child: Text(
                //                     tour['conductor_name'].split(' ')[0],
                //                     style: TextStyle(
                //                       color: const Color.fromARGB(
                //                           255, 255, 255, 255),
                //                       fontSize: 60,
                //                       fontWeight: FontWeight.bold,
                //                     ),
                //                   ),
                //                 )),
                //           ),
                //         ),
                //       ),
                //   ],
                // )
              ],
            )
          else
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}