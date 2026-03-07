import 'package:flutter/material.dart';
import 'home_screen.dart';

class RouteSelectionScreen extends StatelessWidget {
  final String role;

  const RouteSelectionScreen({
    super.key,
    required this.role,
  });

  final List<Map<String, dynamic>> routes = const [
    {
      "routeName": "Route 1 - Anna Nagar",
      "stops": ["Anna Nagar", "Koyambedu", "Vadapalani", "College"]
    },
    {
      "routeName": "Route 2 - T Nagar",
      "stops": ["T Nagar", "Saidapet", "Guindy", "College"]
    },
    {
      "routeName": "Route 3 - Tambaram",
      "stops": ["Tambaram", "Chrompet", "Pallavaram", "College"]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Route"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];

          return Card(
            child: ListTile(
              title: Text(
                route["routeName"],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Stops: ${route["stops"].join(" ➜ ")}",
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      role: role,
                      routeName: route["routeName"],
                      stops: List<String>.from(route["stops"]),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}