import 'package:flutter/material.dart';
import '../../core/utils/vital_type.dart';
import 'blood_pressure_chart.dart';
import 'vital_chart.dart';

class VitalDetailScreen extends StatelessWidget {
  final VitalType vitalType;

  const VitalDetailScreen({super.key, required this.vitalType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: vitalType == VitalType.bloodPressure
            ? const BloodPressureChart()
            : VitalChart(vitalType: vitalType),
      ),
    );
  }

  String _title() {
    switch (vitalType) {
      case VitalType.heartRate:
        return "Nabız Detayı";
      case VitalType.oxygen:
        return "Oksijen Detayı";
      case VitalType.temperature:
        return "Vücut Isısı Detayı";
      case VitalType.bloodPressure:
        return "Kan Basıncı Detayı";
    }
  }
}
