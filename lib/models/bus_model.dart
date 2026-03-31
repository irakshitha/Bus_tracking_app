import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────
// BusLocation — real-time GPS position of the bus on a route
// ─────────────────────────────────────────────────────────────
class BusLocation {
  final double lat;
  final double lng;
  final String currentStop; // name of the nearest stop
  final int currentStopIndex;
  final DateTime timestamp;
  final bool isActive; // is the trip currently running?
  final String driverUid;
  final String driverName;

  BusLocation({
    required this.lat,
    required this.lng,
    required this.currentStop,
    required this.currentStopIndex,
    required this.timestamp,
    required this.isActive,
    required this.driverUid,
    required this.driverName,
  });

  factory BusLocation.fromMap(Map<String, dynamic> map) {
    return BusLocation(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      currentStop: map['currentStop'] ?? '',
      currentStopIndex: (map['currentStopIndex'] as num?)?.toInt() ?? 0,
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
      driverUid: map['driverUid'] ?? '',
      driverName: map['driverName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'currentStop': currentStop,
        'currentStopIndex': currentStopIndex,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': isActive,
        'driverUid': driverUid,
        'driverName': driverName,
      };
}

// ─────────────────────────────────────────────────────────────
// UserProfile — data stored in Firestore for each user
// ─────────────────────────────────────────────────────────────
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role; // 'Student' or 'Driver'
  final String? routeId; // which route they are assigned to

  UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.routeId,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      routeId: map['routeId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        if (routeId != null) 'routeId': routeId,
      };
}

// ─────────────────────────────────────────────────────────────
// Announcement — notice posted by driver or admin to a route
// ─────────────────────────────────────────────────────────────
class Announcement {
  final String id;
  final String message;
  final String routeId; // 'all' means visible to everyone
  final String postedBy;
  final DateTime postedAt;

  Announcement({
    required this.id,
    required this.message,
    required this.routeId,
    required this.postedBy,
    required this.postedAt,
  });

  factory Announcement.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      message: map['message'] ?? '',
      routeId: map['routeId'] ?? 'all',
      postedBy: map['postedBy'] ?? '',
      postedAt: (map['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TripRecord — a logged trip for history
// ─────────────────────────────────────────────────────────────
class TripRecord {
  final String id;
  final String routeId;
  final String routeName;
  final String driverName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;

  TripRecord({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.driverName,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
  });

  factory TripRecord.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return TripRecord(
      id: doc.id,
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      driverName: map['driverName'] ?? '',
      startTime:
          (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  /// Duration of the trip as a readable string
  String get durationText {
    if (endTime == null) return 'Ongoing';
    final diff = endTime!.difference(startTime);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes} min';
  }
}

// ─────────────────────────────────────────────────────────────
// SosAlert — emergency alert raised by student or driver
// ─────────────────────────────────────────────────────────────
class SosAlert {
  final String uid;
  final String name;
  final String role;
  final double? lat;
  final double? lng;
  final String message;
  final DateTime timestamp;

  SosAlert({
    required this.uid,
    required this.name,
    required this.role,
    this.lat,
    this.lng,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'role': role,
        'lat': lat,
        'lng': lng,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'resolved': false,
      };
}
