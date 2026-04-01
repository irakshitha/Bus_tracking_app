import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/routes_data.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

/// Driver's dashboard — shows the route on a map and lets the driver
/// start/stop the trip. When the trip is active, the driver's real GPS
/// is streamed to Firestore so students can track in real time.
class DriverDashboard extends StatefulWidget {
  final RouteInfo routeInfo;
  final String uid;

  const DriverDashboard({
    super.key,
    required this.routeInfo,
    required this.uid,
  });

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<Map<String, int>>? _boardingSub;

  bool isOnline = false;
  bool _hasPermission = false;
  LatLng? _currentPosition;
  String _currentStop = '';
  int _currentStopIndex = 0;
  Map<String, int> _boardingCounts = {};
  String? _activeTripId;

  // Driver's name pulled from Firestore (set externally or default)
  String _driverName = 'Driver';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _listenBoardingCounts();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final profile = await _firestoreService.getUserProfile(widget.uid);
    if (profile != null && mounted) {
      setState(() => _driverName = profile.name.isNotEmpty
          ? profile.name
          : 'Driver');
    }
  }

  Future<void> _checkPermission() async {
    final granted = await _locationService.requestPermission();
    if (mounted) setState(() => _hasPermission = granted);
  }

  void _listenBoardingCounts() {
    _boardingSub = _firestoreService
        .boardingCountStream(widget.routeInfo.routeId)
        .listen((counts) {
      if (mounted) setState(() => _boardingCounts = counts);
    });
  }

  // ── Start trip: begin GPS stream → write to Firestore ──
  Future<void> _startTrip() async {
    if (!_hasPermission) {
      await _checkPermission();
      if (!_hasPermission) {
        _snack('Location permission is required to start the trip');
        return;
      }
    }

    // Create trip record in Firestore
    final tripId = await _firestoreService.startTrip(
      routeId: widget.routeInfo.routeId,
      routeName: widget.routeInfo.routeName,
      driverUid: widget.uid,
      driverName: _driverName,
    );

    setState(() {
      isOnline = true;
      _activeTripId = tripId;
    });

    // Begin GPS position stream
    _gpsSub = _locationService.getPositionStream().listen((position) {
      _onPositionUpdate(position);
    });
  }

  // ── Stop trip: cancel GPS, mark trip complete in Firestore ──
  Future<void> _stopTrip() async {
    await _gpsSub?.cancel();
    _gpsSub = null;

    await _firestoreService.clearBusLocation(widget.routeInfo.routeId);

    if (_activeTripId != null) {
      await _firestoreService.endTrip(_activeTripId!);
    }

    if (mounted) {
      setState(() {
        isOnline = false;
        _activeTripId = null;
        _currentPosition = null;
      });
    }
  }

  // ── Called every time GPS updates ──
  void _onPositionUpdate(Position pos) {
    final newPos = LatLng(pos.latitude, pos.longitude);

    // Detect which stop the bus is nearest to
    final stopIdx = LocationService.nearestStopIndex(
      newPos,
      widget.routeInfo.coordinates,
      thresholdMeters: 200,
    );

    final stopName = stopIdx >= 0
        ? widget.routeInfo.stops[stopIdx]
        : _currentStop;

    // Update Firestore
    _firestoreService.updateBusLocation(
      widget.routeInfo.routeId,
      BusLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        currentStop: stopName,
        currentStopIndex: stopIdx >= 0 ? stopIdx : _currentStopIndex,
        timestamp: DateTime.now(),
        isActive: true,
        driverUid: widget.uid,
        driverName: _driverName,
      ),
    );

    // Update map
    if (mounted) {
      setState(() {
        _currentPosition = newPos;
        if (stopIdx >= 0) {
          _currentStop = stopName;
          _currentStopIndex = stopIdx;
        }
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _boardingSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPos = CameraPosition(
      target: widget.routeInfo.coordinates.first,
      zoom: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status card ──
            _buildStatusCard(),
            const SizedBox(height: 16),

            // ── Map ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 260,
                child: GoogleMap(
                  initialCameraPosition: initialCameraPos,
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _buildMarkers(),
                  polylines: _buildPolyline(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Start / Stop button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: Icon(isOnline ? Icons.stop_circle : Icons.play_circle),
                label: Text(isOnline ? 'Stop Trip' : 'Start Trip',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOnline ? Colors.red[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isOnline ? _stopTrip : _startTrip,
              ),
            ),

            const SizedBox(height: 20),

            // ── Boarding counts ──
            if (isOnline) ...[
              const Text(
                'Boarding Confirmations',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...widget.routeInfo.stops.map((stop) {
                final count = _boardingCounts[stop] ?? 0;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_pin_circle,
                      color: Color(0xFF1565C0)),
                  title: Text(stop),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? Colors.green[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count boarding',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? Colors.green[800] : Colors.grey,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.directions_bus,
              size: 48,
              color: isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.routeInfo.routeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline
                        ? (_currentStop.isNotEmpty
                            ? 'At: $_currentStop'
                            : 'Trip Active — tracking GPS')
                        : 'Trip not started',
                    style: TextStyle(
                      color: isOnline ? Colors.green[700] : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isOnline ? Colors.green : Colors.grey),
              ),
              child: Text(
                isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.green[700] : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Stop markers
    for (int i = 0; i < widget.routeInfo.stops.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: widget.routeInfo.coordinates[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.routeInfo.stops[i]),
      ));
    }

    // Live bus position marker
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: _currentPosition!,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Bus (You)'),
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
        color: const Color(0xFF1565C0),
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    };
  }
}