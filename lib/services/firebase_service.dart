import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/vital_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(user.uid, doc.data()!);
  }

  Stream<List<VitalModel>> getVitalHistory({int limit = 20}) {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => VitalModel.fromMap(doc.data())).toList();
        });
  }

  Future<void> addVitalRecord(VitalModel vital) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .add({
          'heartRate': vital.heartRate,
          'oxygen': vital.oxygen,
          'temperature': vital.temperature,
          'systolic': vital.systolic,
          'diastolic': vital.diastolic,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
