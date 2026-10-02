import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/vital_status.dart';
import '../../models/vital_model.dart';
import '../../services/alert_engine.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getVitalsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Sağlık Uyarıları",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getVitalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState("Henüz kaydedilmiş vital veri bulunmuyor.");
          }

          final allAlerts = <HealthAlert>[];
          for (var doc in snapshot.data!.docs) {
            final vital = VitalModel.fromMap(doc.data());
            allAlerts.addAll(AlertEngine.evaluateVitals(vital));
          }

          if (allAlerts.isEmpty) {
            return _buildSuccessState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allAlerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = allAlerts[index];
              final isDanger = alert.level == VitalLevel.danger;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDanger ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDanger ? Colors.red.shade200 : Colors.orange.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDanger ? Colors.red : Colors.orange).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isDanger ? Colors.red.shade600 : Colors.orange.shade600,
                      radius: 20,
                      child: Icon(
                        isDanger ? Icons.warning_rounded : Icons.info_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDanger ? Colors.red.shade900 : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDanger ? Colors.red.shade800 : Colors.orange.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, size: 56, color: Colors.green.shade600),
            ),
            const SizedBox(height: 20),
            const Text(
              "Her Şey Yolunda!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Son ölçümlerinizde herhangi bir riskli sağlık durumu tespit edilmedi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }
}
