import 'package:cloud_firestore/cloud_firestore.dart';

class VitalModel {
  final int heartRate;
  final int oxygen;
  final double temperature;
  final int systolic;
  final int diastolic;
  final DateTime? createdAt;

  VitalModel({
    required this.heartRate,
    required this.oxygen,
    required this.temperature,
    required this.systolic,
    required this.diastolic,
    this.createdAt,
  });

  factory VitalModel.fromMap(Map<String, dynamic> map) {
    final dynamic createdAtVal = map['createdAt'];
    DateTime? dt;
    if (createdAtVal is Timestamp) {
      dt = createdAtVal.toDate();
    } else if (createdAtVal is DateTime) {
      dt = createdAtVal;
    }

    return VitalModel(
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
      oxygen: (map['oxygen'] as num?)?.toInt() ?? 0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      systolic: (map['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (map['diastolic'] as num?)?.toInt() ?? 0,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heartRate': heartRate,
      'oxygen': oxygen,
      'temperature': temperature,
      'systolic': systolic,
      'diastolic': diastolic,
      'createdAt': createdAt,
    };
  }

  /// Dashboard için hazır string
  String get bloodPressureText => "$systolic / $diastolic";
}
