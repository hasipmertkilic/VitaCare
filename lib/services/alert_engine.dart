import '../core/utils/vital_analyzer.dart';
import '../core/utils/vital_status.dart';
import '../models/vital_model.dart';

class HealthAlert {
  final String title;
  final String message;
  final VitalLevel level;
  final DateTime timestamp;

  HealthAlert({
    required this.title,
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

class AlertEngine {
  /// Vital verisindeki risk durumlarını tespit edip uyarı listesi döndürür.
  static List<HealthAlert> evaluateVitals(VitalModel vital) {
    final alerts = <HealthAlert>[];
    final now = vital.createdAt ?? DateTime.now();

    // Nabız analizi
    final hrStatus = VitalAnalyzer.heartRate(vital.heartRate);
    if (hrStatus.level == VitalLevel.danger || hrStatus.level == VitalLevel.high) {
      alerts.add(
        HealthAlert(
          title: "Nabız Uyarısı (${vital.heartRate} bpm)",
          message: "Nabız değeriniz ${hrStatus.label.toLowerCase()} olarak tespit edildi.",
          level: hrStatus.level,
          timestamp: now,
        ),
      );
    }

    // Oksijen analizi
    final oxStatus = VitalAnalyzer.oxygen(vital.oxygen);
    if (oxStatus.level == VitalLevel.danger || oxStatus.level == VitalLevel.high) {
      alerts.add(
        HealthAlert(
          title: "Oksijen Uyarısı (%${vital.oxygen})",
          message: "Kan oksijen seviyeniz ${oxStatus.label.toLowerCase()} seviyesinde.",
          level: oxStatus.level,
          timestamp: now,
        ),
      );
    }

    // Tansiyon analizi
    final bpStatus = VitalAnalyzer.bloodPressure(vital.systolic, vital.diastolic);
    if (bpStatus.level == VitalLevel.danger || bpStatus.level == VitalLevel.high) {
      alerts.add(
        HealthAlert(
          title: "Tansiyon Uyarısı (${vital.bloodPressureText} mmHg)",
          message: "Kan basıncınız: ${bpStatus.label}.",
          level: bpStatus.level,
          timestamp: now,
        ),
      );
    }

    // Ateş analizi
    final tempStatus = VitalAnalyzer.temperature(vital.temperature);
    if (tempStatus.level == VitalLevel.danger || tempStatus.level == VitalLevel.high) {
      alerts.add(
        HealthAlert(
          title: "Vücut Isısı Uyarısı (${vital.temperature.toStringAsFixed(1)} °C)",
          message: "Vücut sıcaklığınız ${tempStatus.label.toLowerCase()} durumunda.",
          level: tempStatus.level,
          timestamp: now,
        ),
      );
    }

    return alerts;
  }
}
