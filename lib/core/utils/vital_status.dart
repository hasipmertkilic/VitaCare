import 'package:flutter/material.dart';

enum VitalLevel { low, normal, high, danger }

class VitalStatus {
  final String label;
  final Color color;
  final VitalLevel level;

  VitalStatus({required this.label, required this.color, required this.level});
}
