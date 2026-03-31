import 'package:flutter/material.dart';
import '../constants/routes_data.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'driver_dashboard.dart';
import 'student_tracking_screen.dart';
import 'announcements_screen.dart';
import 'trip_history_screen.dart';
import 'profile_screen.dart';

/// The main shell after login + route selection.
/// Holds a bottom navigation bar with:
///   0 — Home (tracking / driver dashboard)
///   1 — Announcements
///   2 — Trip History
///   3 — Profile
/// Plus an SOS floating action button.
class HomeScreen extends StatefulWidget {
  final String role;
  final String uid;
  final RouteInfo routeInfo;

  const HomeScreen({
    super.key,
    required this.role,
    required this.uid,
    required this.routeInfo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _displayName = '';

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final profile = await _firestoreService.getUserProfile(widget.uid);
    if (mounted && profile != null) {
      setState(() => _displayName = profile.name);
    }
  }

  List<Widget> get _screens => [
        // Tab 0: Tracking / Dashboard
        widget.role.toLowerCase() == 'driver'
            ? DriverDashboard(
                routeInfo: widget.routeInfo,
                uid: widget.uid,
              )
            : StudentTrackingScreen(
                routeInfo: widget.routeInfo,
                uid: widget.uid,
              ),

        // Tab 1: Announcements
        AnnouncementsScreen(
          routeId: widget.routeInfo.routeId,
          routeName: widget.routeInfo.routeName,
          role: widget.role,
          uid: widget.uid,
          displayName: _displayName,
        ),

        // Tab 2: Trip History
        TripHistoryScreen(
          routeId: widget.routeInfo.routeId,
          routeName: widget.routeInfo.routeName,
        ),

        // Tab 3: Profile
        ProfileScreen(
          uid: widget.uid,
          role: widget.role,
          routeName: widget.routeInfo.routeName,
        ),
      ];

  // ── SOS: confirm dialog → write alert to Firestore → notification ──
  Future<void> _triggerSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Send SOS Alert?'),
          ],
        ),
        content: const Text(
          'This will immediately send an emergency alert '
          'with your current location to the monitoring system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send SOS',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Try to get current GPS position
    final position = await _locationService.getCurrentPosition();

    final alert = SosAlert(
      uid: widget.uid,
      name: _displayName.isNotEmpty ? _displayName : 'Unknown',
      role: widget.role,
      lat: position?.latitude,
      lng: position?.longitude,
      message: 'Emergency SOS from ${widget.role} on ${widget.routeInfo.routeName}',
      timestamp: DateTime.now(),
    );

    await _firestoreService.sendSos(alert);
    await NotificationService.sosSent();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('🆘 SOS sent! Help has been alerted.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to preserve state when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // SOS floating action button
      floatingActionButton: FloatingActionButton(
        heroTag: 'sos_fab',
        backgroundColor: Colors.red,
        onPressed: _triggerSOS,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos, color: Colors.white, size: 22),
            Text('SOS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: Icon(widget.role.toLowerCase() == 'driver'
                ? Icons.dashboard
                : Icons.location_on),
            label: widget.role.toLowerCase() == 'driver'
                ? 'Dashboard'
                : 'Track',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Notices',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}