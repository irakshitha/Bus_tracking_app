import 'package:flutter/material.dart';
import 'driver_dashboard.dart';
import 'student_tracking_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String routeName;
  final List<String> stops;

  const HomeScreen({
    super.key,
    required this.role,
    required this.routeName,
    required this.stops,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      widget.role.toLowerCase() == "driver"
          ? DriverDashboard(
              routeName: widget.routeName,
              stops: widget.stops,
            )
          : StudentTrackingScreen(
              routeName: widget.routeName,
              stops: widget.stops,
            ),
      ProfileScreen(
        role: widget.role,
        routeName: widget.routeName,
      ),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            setState(() {
              selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),
    );
  }
}