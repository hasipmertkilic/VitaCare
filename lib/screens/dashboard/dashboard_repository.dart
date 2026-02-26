import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardRepository(this._auth, this._firestore);

  Future<String?> fetchUserName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['name'];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchLatestVital() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchLast7DaysVitals() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
