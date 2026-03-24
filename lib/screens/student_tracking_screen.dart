import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentTrackingScreen extends StatefulWidget {
  final String routeName;
  final List<String> stops;

  const StudentTrackingScreen({
    super.key,
    required this.routeName,
    required this.stops,
  });

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  int currentStopIndex = 0;
  bool isBusMoving = true;

  GoogleMapController? _mapController;

  // Dummy coordinates for simulation
  final List<LatLng> _stopCoordinates = const [
    LatLng(12.9716, 77.5946), // Bus Stand
    LatLng(12.9750, 77.6000), // Stop 1
    LatLng(12.9800, 77.6100), // Stop 2
    LatLng(12.9850, 77.6200), // Stop 3
    LatLng(12.9900, 77.6300), // College
  ];

  LatLng _currentBusPosition = const LatLng(12.9716, 77.5946);

  /// ✅ ETA Calculation (No negative values)
  int calculateETA() {
    int remainingStops = widget.stops.length - currentStopIndex - 1;

    if (remainingStops <= 0) {
      return 0;
    }

    return remainingStops * 4; // 4 minutes per stop
  }

  @override
  void initState() {
    super.initState();
    if (widget.stops.isNotEmpty) {
      simulateBusMovement();
    }
  }

  /// ✅ Simulate live bus movement
  void simulateBusMovement() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (currentStopIndex < widget.stops.length - 1) {
        setState(() {
          currentStopIndex++;
          if (currentStopIndex < _stopCoordinates.length) {
            _currentBusPosition = _stopCoordinates[currentStopIndex];
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentBusPosition),
            );
          }
        });

        // Show notification when reaching stop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Bus reached ${widget.stops[currentStopIndex]}",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        timer.cancel();
        setState(() {
          isBusMoving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bus has reached destination"),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Route Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: ListTile(
                title: Text(
                  widget.routeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Current Stop: ${widget.stops[currentStopIndex]}",
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Actual Google Map
            SizedBox(
              height: 300,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentBusPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: _currentBusPosition,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                      infoWindow: const InfoWindow(title: 'Bus Current Location'),
                      zIndex: 2,
                    ),
                    for (int i = 0; i < widget.stops.length && i < _stopCoordinates.length; i++)
                      Marker(
                        markerId: MarkerId('stop_$i'),
                        position: _stopCoordinates[i],
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: InfoWindow(title: widget.stops[i]),
                        zIndex: 1,
                      ),
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Bus Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bus Status:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isBusMoving ? "Moving" : "Reached Destination",
                  style: TextStyle(
                      color: isBusMoving ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ETA Display
            Text(
              "ETA: ${calculateETA()} minutes",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// Stops Progress Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Stops Progress",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            /// Stops List
            Expanded(
              child: ListView.builder(
                itemCount: widget.stops.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      index <= currentStopIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: index <= currentStopIndex
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(widget.stops[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
