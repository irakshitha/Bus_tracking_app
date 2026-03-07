import 'package:flutter/material.dart';
import 'dart:async';

class StudentTrackingScreen extends StatefulWidget {
  final String routeName;
  final List<String> stops;

  const StudentTrackingScreen({
    super.key,
    required this.routeName,
    required this.stops,
  });

  @override
  State<StudentTrackingScreen> createState() =>
      _StudentTrackingScreenState();
}

class _StudentTrackingScreenState
    extends State<StudentTrackingScreen> {

  int currentStopIndex = 0;
  bool isBusMoving = true;

  /// ✅ ETA Calculation (No negative values)
  int calculateETA() {
    int remainingStops =
        widget.stops.length - currentStopIndex - 1;

    if (remainingStops <= 0) {
      return 0;
    }

    return remainingStops * 4; // 4 minutes per stop
  }

  @override
  void initState() {
    super.initState();
    simulateBusMovement();
  }

  /// ✅ Simulate live bus movement
  void simulateBusMovement() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (currentStopIndex < widget.stops.length - 1) {
        setState(() {
          currentStopIndex++;
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Current Stop: ${widget.stops[currentStopIndex]}",
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Map Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade300,
              ),
              child: const Center(
                child: Icon(
                  Icons.map,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Bus Status Row
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bus Status:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  isBusMoving
                      ? "Moving"
                      : "Reached Destination",
                  style: TextStyle(
                      color: isBusMoving
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ETA Display
            Text(
              "ETA: ${calculateETA()} minutes",
              style: const TextStyle(
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// Stops Progress Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Stops Progress",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
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