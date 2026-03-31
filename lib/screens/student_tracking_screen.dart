import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/routes_data.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

/// Student's live bus tracking screen.
/// Listens to Firestore in real time for the driver's GPS position
/// and updates the map, ETA, and stop progress accordingly.
class StudentTrackingScreen extends StatefulWidget {
  final RouteInfo routeInfo;
  final String uid;

  const StudentTrackingScreen({
    super.key,
    required this.routeInfo,
    required this.uid,
  });

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  GoogleMapController? _mapController;

  BusLocation? _busLocation;
  int _lastNotifiedStopIndex = -1; // avoids repeated notifications
  bool _boardingConfirmed = false;
  String _studentName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final profile = await _firestoreService.getUserProfile(widget.uid);
    if (profile != null && mounted) {
      setState(() =>
          _studentName = profile.name.isNotEmpty ? profile.name : 'Student');
    }
  }

  /// Calculate ETA in minutes based on remaining stops.
  int _calculateETA(int currentStopIndex) {
    final remaining =
        widget.routeInfo.stops.length - currentStopIndex - 1;
    return remaining <= 0 ? 0 : remaining * 4; // ~4 min per stop
  }

  /// Check if bus is near any stop and fire a notification if so.
  void _checkAndNotify(BusLocation loc) {
    final pos = LatLng(loc.lat, loc.lng);
    final nearIdx = LocationService.nearestStopIndex(
      pos,
      widget.routeInfo.coordinates,
      thresholdMeters: 150,
    );

    if (nearIdx >= 0 && nearIdx != _lastNotifiedStopIndex) {
      _lastNotifiedStopIndex = nearIdx;
      final stopName = widget.routeInfo.stops[nearIdx];
      final eta = _calculateETA(nearIdx);

      if (eta > 0) {
        NotificationService.busApproachingStop(stopName, eta);
      } else {
        NotificationService.busArrivedAtStop(stopName);
      }
    }
  }

  /// Student taps "Board at this stop"
  Future<void> _confirmBoarding(String stopName) async {
    await _firestoreService.confirmBoarding(
      routeId: widget.routeInfo.routeId,
      stopName: stopName,
      uid: widget.uid,
      studentName: _studentName,
    );
    if (mounted) {
      setState(() => _boardingConfirmed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Boarding confirmed at $stopName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        centerTitle: true,
      ),
      body: StreamBuilder<BusLocation?>(
        stream: _firestoreService
            .busLocationStream(widget.routeInfo.routeId),
        builder: (context, snapshot) {
          // Show loading only on first load
          if (snapshot.connectionState == ConnectionState.waiting &&
              _busLocation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            _busLocation = snapshot.data;
            // Trigger notification if bus is near a stop
            _checkAndNotify(_busLocation!);
          }

          final busLoc = _busLocation;
          final isActive = busLoc?.isActive ?? false;
          final currentStopName = busLoc?.currentStop ?? '';
          final currentStopIndex = busLoc?.currentStopIndex ?? 0;
          final eta = _calculateETA(currentStopIndex);

          final busLatLng = busLoc != null
              ? LatLng(busLoc.lat, busLoc.lng)
              : widget.routeInfo.coordinates.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Status Banner ──
                _buildStatusBanner(isActive, busLoc?.driverName ?? ''),

                const SizedBox(height: 12),

                // ── Route info card ──
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.route, color: Color(0xFF1565C0)),
                    title: Text(
                      widget.routeInfo.routeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isActive
                          ? 'Now at: $currentStopName'
                          : 'Bus not started yet',
                    ),
                    trailing: isActive
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$eta',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              const Text('min',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Google Map ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 280,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: busLatLng,
                        zoom: 14,
                      ),
                      onMapCreated: (c) {
                        _mapController = c;
                        // If we already have a location, move camera
                        if (busLoc != null) {
                          c.animateCamera(
                              CameraUpdate.newLatLng(busLatLng));
                        }
                      },
                      markers: _buildMarkers(busLatLng),
                      polylines: _buildPolyline(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Boarding confirmation button ──
                if (isActive && !_boardingConfirmed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.emoji_people),
                      label: Text(
                          'Board at $currentStopName'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: currentStopName.isNotEmpty
                          ? () => _confirmBoarding(currentStopName)
                          : null,
                    ),
                  ),
                if (_boardingConfirmed)
                  const Chip(
                    avatar: Icon(Icons.check_circle, color: Colors.green),
                    label: Text('Boarding confirmed'),
                  ),

                const SizedBox(height: 16),

                // ── Stops Progress ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stops Progress',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(widget.routeInfo.stops.length, (i) {
                  final passed = i <= currentStopIndex && isActive;
                  final isCurrent =
                      i == currentStopIndex && isActive;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      passed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCurrent
                          ? const Color(0xFF1565C0)
                          : passed
                              ? Colors.green
                              : Colors.grey,
                    ),
                    title: Text(
                      widget.routeInfo.stops[i],
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? const Color(0xFF1565C0)
                            : null,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Chip(
                            label: Text('Bus here'),
                            backgroundColor: Color(0xFFE3F2FD),
                          )
                        : null,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(bool isActive, String driverName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive ? Colors.green : Colors.orange),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.circle : Icons.circle_outlined,
            color: isActive ? Colors.green : Colors.orange,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isActive
                  ? 'Bus is live${driverName.isNotEmpty ? ' — Driver: $driverName' : ''}'
                  : 'Waiting for driver to start the trip…',
              style: TextStyle(
                color: isActive ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(LatLng busLatLng) {
    final markers = <Marker>{};

    // Stop markers
    for (int i = 0; i < widget.routeInfo.stops.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: widget.routeInfo.coordinates[i],
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.routeInfo.stops[i]),
      ));
    }

    // Bus marker — only show if trip is active
    if (_busLocation?.isActive == true) {
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: busLatLng,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: '🚌 Bus'),
        zIndexInt: 2,
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolyline() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routeInfo.coordinates,
        color: const Color(0xFF1565C0).withValues(alpha: 0.5),
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    };
  }
}
