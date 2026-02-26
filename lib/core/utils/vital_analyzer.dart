import 'package:flutter/material.dart';
import 'vital_status.dart';

class VitalAnalyzer {
  /// ❤️ NABIZ (bpm) — Yetişkin, Dinlenme Halinde
  /// Referans: 60-100 Normal, <60 Bradikardi, >100 Taşikardi
  static VitalStatus heartRate(int value) {
    if (value < 45) {
      return VitalStatus(
        label: "Kritik Düşük (Şiddetli Bradikardi)",
        color: Colors.blue.shade900,
        level: VitalLevel.danger,
      );
    } else if (value < 60) {
      return VitalStatus(
        label: "Düşük (Bradikardi)",
        color: Colors.blue,
        level: VitalLevel.low,
      );
    } else if (value <= 100) {
      return VitalStatus(
        label: "Normal",
        color: Colors.green,
        level: VitalLevel.normal,
      );
    } else if (value <= 130) {
      return VitalStatus(
        label: "Yüksek (Taşikardi)",
        color: Colors.orange,
        level: VitalLevel.high,
      );
    } else {
      return VitalStatus(
        label: "Kritik Yüksek",
        color: Colors.red,
        level: VitalLevel.danger,
      );
    }
  }

  /// 🫁 OKSİJEN SATURASYONU (SpO₂ %)
  /// Referans: %95-100 Normal, <%90 Hipoksi (Kritik)
  static VitalStatus oxygen(int value) {
    if (value < 90) {
      return VitalStatus(
        label: "Kritik (Hipoksi)",
        color: Colors.red.shade900,
        level: VitalLevel.danger,
      );
    } else if (value < 95) {
      return VitalStatus(
        label: "Düşük (Tıbbi Destek Gerekebilir)",
        color: Colors.orange,
        level: VitalLevel.high,
      );
    } else if (value <= 100) {
      return VitalStatus(
        label: "Normal",
        color: Colors.green,
        level: VitalLevel.normal,
      );
    } else {
      return VitalStatus(
        label: "Hatalı Ölçüm",
        color: Colors.grey,
        level: VitalLevel.low,
      );
    }
  }

  /// 🩺 KAN BASINCI (mmHg)
  /// AHA (American Heart Association) Standartlarına Göre
  static VitalStatus bloodPressure(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return VitalStatus(
        label: "Hipertansif Kriz!",
        color: Colors.red.shade900,
        level: VitalLevel.danger,
      );
    } else if (systolic >= 140 || diastolic >= 90) {
      return VitalStatus(
        label: "Hipertansiyon (Evre 2)",
        color: Colors.red,
        level: VitalLevel.danger,
      );
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return VitalStatus(
        label: "Hipertansiyon (Evre 1)",
        color: Colors.deepOrange,
        level: VitalLevel.high,
      );
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return VitalStatus(
        label: "Yükselmiş (Pre-Hipertansiyon)",
        color: Colors.orange,
        level: VitalLevel.high,
      );
    } else if (systolic >= 90 && diastolic >= 60) {
      return VitalStatus(
        label: "Normal",
        color: Colors.green,
        level: VitalLevel.normal,
      );
    } else {
      return VitalStatus(
        label: "Düşük (Hipotansiyon)",
        color: Colors.blue,
        level: VitalLevel.low,
      );
    }
  }

  /// 🌡️ VÜCUT SICAKLIĞI (°C)
  /// Referans: 36.1-37.2 Normal, >38 Ateş
  static VitalStatus temperature(double value) {
    if (value < 35.0) {
      return VitalStatus(
        label: "Hipotermi",
        color: Colors.blue.shade800,
        level: VitalLevel.danger,
      );
    } else if (value < 36.1) {
      return VitalStatus(
        label: "Hafif Düşük",
        color: Colors.blue,
        level: VitalLevel.low,
      );
    } else if (value <= 37.5) {
      return VitalStatus(
        label: "Normal",
        color: Colors.green,
        level: VitalLevel.normal,
      );
    } else if (value <= 38.5) {
      return VitalStatus(
        label: "Hafif Ateş",
        color: Colors.orange,
        level: VitalLevel.high,
      );
    } else {
      return VitalStatus(
        label: "Yüksek Ateş",
        color: Colors.red,
        level: VitalLevel.danger,
      );
    }
  }
}
