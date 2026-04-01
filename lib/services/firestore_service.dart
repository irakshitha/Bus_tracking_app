import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

/// Central service for all Firestore database operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ────────────────────────────────────────────────
  // USER PROFILE
  // ────────────────────────────────────────────────

  /// Create or update a user document in Firestore.
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String email,
    required String role,
    String? routeId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      if (routeId != null) 'routeId': routeId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save just the user role during registration (backwards-compatible helper).
  Future<void> saveUserRole(String uid, String role) async {
    await _db
        .collection('users')
        .doc(uid)
        .set({'role': role}, SetOptions(merge: true));
  }

  /// Fetch the role string for a uid.
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc['role'] as String? : null;
  }

  /// Fetch full user profile.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
  }

  /// Update only name and phone in the user document.
  Future<void> updateUserProfile(
      String uid, String name, String phone) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  // ────────────────────────────────────────────────
  // LIVE BUS LOCATION  (driver writes → student reads)
  // ────────────────────────────────────────────────

  /// Write the driver's current GPS location to Firestore.
  /// Document key is the routeId (e.g. 'route_1').
  Future<void> updateBusLocation(
      String routeId, BusLocation location) async {
    await _db
        .collection('bus_locations')
        .doc(routeId)
        .set(location.toMap(), SetOptions(merge: true));
  }

  /// Mark a route's bus as offline (trip ended).
  Future<void> clearBusLocation(String routeId) async {
    await _db.collection('bus_locations').doc(routeId).set({
      'isActive': false,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Real-time stream of bus location for a route.
  /// Used by StudentTrackingScreen to listen for updates.
  Stream<BusLocation?> busLocationStream(String routeId) {
    return _db
        .collection('bus_locations')
        .doc(routeId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return BusLocation.fromMap(snap.data()!);
    });
  }

  // ────────────────────────────────────────────────
  // TRIP HISTORY
  // ────────────────────────────────────────────────

  /// Create a new trip record when a driver starts a trip.
  /// Returns the new trip's document ID.
  Future<String> startTrip({
    required String routeId,
    required String routeName,
    required String driverUid,
    required String driverName,
  }) async {
    final ref = await _db.collection('trips').add({
      'routeId': routeId,
      'routeName': routeName,
      'driverUid': driverUid,
      'driverName': driverName,
      'startTime': FieldValue.serverTimestamp(),
      'isCompleted': false,
    });
    return ref.id;
  }

  /// Mark a trip as completed.
  Future<void> endTrip(String tripId) async {
    await _db.collection('trips').doc(tripId).update({
      'endTime': FieldValue.serverTimestamp(),
      'isCompleted': true,
    });
  }

  /// Stream of trip history for a given route (latest first).
  Stream<List<TripRecord>> tripHistoryStream(String routeId) {
    return _db
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .orderBy('startTime', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TripRecord.fromDoc(d)).toList());
  }

  // ────────────────────────────────────────────────
  // ANNOUNCEMENTS
  // ────────────────────────────────────────────────

  /// Post a new announcement for a route (or 'all').
  Future<void> postAnnouncement({
    required String routeId,
    required String message,
    required String postedBy,
  }) async {
    await _db.collection('announcements').add({
      'routeId': routeId,
      'message': message,
      'postedBy': postedBy,
      'postedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of announcements visible to a given route
  /// (includes both route-specific and 'all' announcements).
  Stream<List<Announcement>> announcementsStream(String routeId) {
    return _db
        .collection('announcements')
        .orderBy('postedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Announcement.fromDoc(d))
            .where((a) => a.routeId == routeId || a.routeId == 'all')
            .toList());
  }

  /// Delete an announcement by ID.
  Future<void> deleteAnnouncement(String announcementId) async {
    await _db.collection('announcements').doc(announcementId).delete();
  }

  // ────────────────────────────────────────────────
  // BOARDING CONFIRMATION
  // ────────────────────────────────────────────────

  /// Student confirms they are boarding at a specific stop.
  Future<void> confirmBoarding({
    required String routeId,
    required String stopName,
    required String uid,
    required String studentName,
  }) async {
    await _db
        .collection('boarding')
        .doc(routeId)
        .collection('stops')
        .doc(stopName)
        .set({
      'count': FieldValue.increment(1),
      'students': FieldValue.arrayUnion([uid]),
      'studentNames': FieldValue.arrayUnion([studentName]),
    }, SetOptions(merge: true));
  }

  /// Stream of boarding count for all stops on a route.
  /// Used by the driver dashboard.
  Stream<Map<String, int>> boardingCountStream(String routeId) {
    return _db
        .collection('boarding')
        .doc(routeId)
        .collection('stops')
        .snapshots()
        .map((snap) {
      final Map<String, int> counts = {};
      for (final doc in snap.docs) {
        counts[doc.id] = (doc.data()['count'] as num?)?.toInt() ?? 0;
      }
      return counts;
    });
  }

  // ────────────────────────────────────────────────
  // SOS ALERTS
  // ────────────────────────────────────────────────

  /// Send an SOS alert from any user.
  Future<void> sendSos(SosAlert alert) async {
    await _db.collection('sos_alerts').add(alert.toMap());
  }
}