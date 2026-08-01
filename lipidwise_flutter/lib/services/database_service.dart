import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveAssessment(Map<String, dynamic> rawData, Map<String, dynamic> resultData, String role) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Only save if logged in

    try {
      await _db.collection('assessments').add({
        'uid': user.uid,
        'userEmail': user.email,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
        'inputData': rawData,
        'aiResult': resultData,
      });
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }
}
