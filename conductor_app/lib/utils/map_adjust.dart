import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:conductor_app/utils/location.dart';

class MapAdjusterScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapAdjusterScreen({required this.initialPosition, Key? key})
      : super(key: key);

  @override
  _MapAdjusterScreenState createState() => _MapAdjusterScreenState();
}

class _MapAdjusterScreenState extends State<MapAdjusterScreen> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  // Future<void> fetchLocationData() async {
  //   // Sample implementation to fetch coordinates based on user input.
  //   // Replace with actual API call or logic as required.
  //   String query = _locationController.text;
  //   // Here you would use fetchLocationData(query) function to get the new coordinates.
  //   // For demonstration, assume fetched coordinates (replace these with actual fetched data):
  //   LatLng fetchedPosition =
  //       LatLng(27.7172, 85.3240); // Example coordinates for Kathmandu

  //   setState(() {
  //     _selectedPosition = fetchedPosition;
  //     _mapController.move(
  //         _selectedPosition, _mapController.zoom); // Move the map
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(
                  context, _selectedPosition); // Return the selected position
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 13.0,
              onTap: null, // Disable tap gesture to focus on dragging
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              DragMarkers(
                markers: [
                  DragMarker(
                    point: _selectedPosition,
                    size: const Size.square(75),
                    offset: const Offset(0, -20),
                    dragOffset: const Offset(0, -35),
                    builder: (_, __, isDragging) {
                      return Icon(
                        isDragging ? Icons.edit_location : Icons.location_on,
                        size: isDragging ? 75 : 50,
                        color: Colors.blueGrey,
                      );
                    },
                    onDragEnd: (details, point) {
                      setState(() {
                        _selectedPosition = point;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter location',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final location_data = await fetchLocationData(
                        _locationController
                            .text); // Call function to fetch and move to location
                    final location =
                        location_data['features'][0]['geometry']['coordinates'];
                    final latitude = location[1];
                    final longitude = location[0];
                    print('Location data: $latitude, $longitude');
                    setState(() {
                      _selectedPosition = LatLng(latitude, longitude);
                      _mapController.move(_selectedPosition, 10);
                    });
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
