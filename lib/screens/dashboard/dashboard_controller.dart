import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_repository.dart';

class DashboardController {
  final DashboardRepository repository;

  DashboardController(this.repository);

  Future<String> getUserName() async {
    return await repository.fetchUserName() ?? "Kullanıcı";
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLatestVital() {
    return repository.fetchLatestVital();
  }

  Future<void> logout() async {
    await repository.signOut();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLast7DaysVitals() {
    return repository.fetchLast7DaysVitals();
  }
}
