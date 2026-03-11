import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/student_tracking_screen.dart';
import 'screens/driver_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Tracking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
      routes: {
        '/studentTracking': (context) => const StudentTrackingScreen(
              routeName: "Route 1",
              stops: [
                "Bus Stand",
                "Stop 1",
                "Stop 2",
                "Stop 3",
                "College",
              ],
            ),
        '/driverDashboard': (context) => const DriverDashboard(
              routeName: "Route 1",
              stops: [
                "Bus Stand",
                "Stop 1",
                "Stop 2",
                "Stop 3",
                "College",
              ],
            ),
      },
    );
  }
}
