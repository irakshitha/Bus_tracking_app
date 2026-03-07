import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  final String routeName;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    const studentName = "Anusree";
    const studentPhone = "9876543210";
    const driverName = "Mr. Kumar";
    const driverPhone = "9123456780";
    const destination = "College Campus";

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: role.toLowerCase() == "student"
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person,
                          size: 80, color: Colors.blue),
                      const SizedBox(height: 20),
                      const Text("Name: $studentName"),
                      const SizedBox(height: 10),
                      const Text("Phone: $studentPhone"),
                      const SizedBox(height: 10),
                      Text("Route: $routeName"),
                      const SizedBox(height: 10),
                      const Text("Destination: $destination"),
                      const SizedBox(height: 10),
                      const Text("Driver Name: $driverName"),
                      const SizedBox(height: 10),
                      const Text("Driver Phone: $driverPhone"),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person,
                          size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      const Text("Driver Name: $driverName"),
                      const SizedBox(height: 10),
                      const Text("Driver Phone: $driverPhone"),
                      const SizedBox(height: 10),
                      Text("Route Handling: $routeName"),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}