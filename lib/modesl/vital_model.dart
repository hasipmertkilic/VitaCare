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
    return VitalModel(
      heartRate: (map['heartRate'] ?? 0) as int,
      oxygen: (map['oxygen'] ?? 0) as int,
      temperature: (map['temperature'] ?? 0).toDouble(),
      systolic: (map['systolic'] ?? 0) as int,
      diastolic: (map['diastolic'] ?? 0) as int,
      createdAt: map['createdAt'] != null ? map['createdAt'].toDate() : null,
    );
  }

  /// Dashboard için hazır string
  String get bloodPressureText => "$systolic / $diastolic";
}
