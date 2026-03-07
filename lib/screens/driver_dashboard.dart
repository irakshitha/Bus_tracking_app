import 'package:flutter/material.dart';

class DriverDashboard extends StatefulWidget {
  final String routeName;
  final List<String> stops;

  const DriverDashboard({
    super.key,
    required this.routeName,
    required this.stops,
  });

  @override
  State<DriverDashboard> createState() =>
      _DriverDashboardState();
}

class _DriverDashboardState
    extends State<DriverDashboard> {

  bool isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Driver Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              widget.routeName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("Stops: ${widget.stops.join(" ➜ ")}"),

            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus,
                        size: 60,
                        color: isOnline
                            ? Colors.green
                            : Colors.red),
                    const SizedBox(height: 10),
                    Text(
                      isOnline
                          ? "Trip Active"
                          : "Trip Not Started",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                minimumSize: const Size(
                    double.infinity, 50),
              ),
              onPressed: () {
                setState(() {
                  isOnline = !isOnline;
                });
              },
              child: Text(
                  isOnline
                      ? "Stop Trip"
                      : "Start Trip"),
            ),
          ],
        ),
      ),
    );
  }
}