import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user role
  Future<void> saveUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc =
        await _db.collection('users').doc(uid).get();

    if (doc.exists) {
      return doc['role'];
    }
    return null;
  }
}