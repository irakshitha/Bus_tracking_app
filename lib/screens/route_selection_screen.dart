import 'package:flutter/material.dart';
import '../constants/routes_data.dart';
import 'home_screen.dart';

/// Screen where the user picks which bus route they want to track/drive.
class RouteSelectionScreen extends StatelessWidget {
  final String role;
  final String uid;

  const RouteSelectionScreen({
    super.key,
    required this.role,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Route'),
        centerTitle: true,
        automaticallyImplyLeading: false, // no back button after login
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appRoutes.length,
        itemBuilder: (context, index) {
          final route = appRoutes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      role: role,
                      uid: uid,
                      routeInfo: route,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_bus,
                          color: Color(0xFF1565C0), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.routeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            route.stops.join(' → '),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route.stops.length} stops',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}