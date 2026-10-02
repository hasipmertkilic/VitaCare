import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthConnectData {
  final int? heartRate;
  final int? systolic;
  final int? diastolic;
  final int? oxygen;
  final double? temperature;
  final String deviceName;
  final String sourceApp;
  final DateTime timestamp;
  final bool isSimulated;
  final int? batteryLevel;

  HealthConnectData({
    this.heartRate,
    this.systolic,
    this.diastolic,
    this.oxygen,
    this.temperature,
    this.deviceName = 'Health Connect',
    this.sourceApp = 'Health Connect',
    DateTime? timestamp,
    this.isSimulated = false,
    this.batteryLevel,
  }) : timestamp = timestamp ?? DateTime.now();
}

class HealthConnectService {
  final Health _health = Health();
  bool _isConfigured = false;

  Future<void> _configure() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
    } catch (e) {
      debugPrint('Health Connect configure note: $e');
    }
  }

  /// Checks if Health Connect status is available on Android.
  Future<bool> isHealthConnectAvailable() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      } catch (e) {
        debugPrint('Error checking Health Connect SDK status: $e');
      }
    }
    return true;
  }

  /// Prompts user to install Health Connect app if not installed (Android).
  Future<void> installHealthConnect() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _health.installHealthConnect();
      } catch (e) {
        debugPrint('Error opening Health Connect install page: $e');
      }
    }
  }

  /// Reads latest smartwatch metrics from Health Connect API on Android.
  Future<HealthConnectData> fetchHealthConnectData() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          await _health.installHealthConnect();
          throw Exception('Health Connect uygulaması kullanılabilir değil veya yüklü değil. Yükleme sayfası açıldı.');
        }
      } catch (e) {
        if (e is Exception) rethrow;
        debugPrint('Health Connect SDK kontrol hatası: $e');
      }
    }

    await _configure();

    // Required Health Connect data types
    final types = <HealthDataType>[
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BODY_TEMPERATURE,
    ];

    final permissions = types.map((_) => HealthDataAccess.READ).toList();

    bool hasPermissions = false;
    try {
      hasPermissions = await _health.hasPermissions(types, permissions: permissions) ?? false;
      if (!hasPermissions) {
        hasPermissions = await _health.requestAuthorization(types, permissions: permissions);
      }
    } catch (e) {
      debugPrint('Health Connect izin isteme hatası: $e');
    }

    if (!hasPermissions) {
      throw Exception('Health Connect erişim izinleri verilmedi. Lütfen ayarları kontrol edin.');
    }

    // Query recorded data from the last 30 days
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 30));

    List<HealthDataPoint> healthData = [];
    try {
      healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );
      healthData = _health.removeDuplicates(healthData);
    } catch (e) {
      debugPrint('Health Connect veri çekme hatası: $e');
      throw Exception('Health Connect verileri okunurken bir hata oluştu: $e');
    }

    if (healthData.isEmpty) {
      throw Exception('Health Connect uygulamasında henüz kaydedilmiş bir sağlık verisi bulunamadı.');
    }

    int? heartRate;
    int? systolic;
    int? diastolic;
    int? oxygen;
    double? temperature;

    DateTime? latestHrTime;
    DateTime? latestBpSysTime;
    DateTime? latestBpDiaTime;
    DateTime? latestOxTime;
    DateTime? latestTempTime;

    String deviceName = 'Health Connect';
    String sourceApp = 'Health Connect';

    for (var point in healthData) {
      final val = point.value;
      final time = point.dateTo;

      if (point.sourceName.isNotEmpty && point.sourceName != 'flutter') {
        deviceName = point.sourceName;
      }
      if (point.sourceId.isNotEmpty) {
        sourceApp = point.sourceId;
      }

      if (point.type == HealthDataType.HEART_RATE) {
        if (val is NumericHealthValue) {
          if (latestHrTime == null || time.isAfter(latestHrTime)) {
            latestHrTime = time;
            heartRate = val.numericValue.round();
          }
        }
      } else if (point.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
        if (val is NumericHealthValue) {
          if (latestBpSysTime == null || time.isAfter(latestBpSysTime)) {
            latestBpSysTime = time;
            systolic = val.numericValue.round();
          }
        }
      } else if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
        if (val is NumericHealthValue) {
          if (latestBpDiaTime == null || time.isAfter(latestBpDiaTime)) {
            latestBpDiaTime = time;
            diastolic = val.numericValue.round();
          }
        }
      } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
        if (val is NumericHealthValue) {
          if (latestOxTime == null || time.isAfter(latestOxTime)) {
            latestOxTime = time;
            final raw = val.numericValue;
            oxygen = (raw <= 1.0 ? raw * 100 : raw).round();
          }
        }
      } else if (point.type == HealthDataType.BODY_TEMPERATURE) {
        if (val is NumericHealthValue) {
          if (latestTempTime == null || time.isAfter(latestTempTime)) {
            latestTempTime = time;
            temperature = double.parse(val.numericValue.toStringAsFixed(1));
          }
        }
      }
    }

    if (heartRate == null &&
        systolic == null &&
        diastolic == null &&
        oxygen == null &&
        temperature == null) {
      throw Exception('Health Connect verileri arasında geçerli bir değer okunamadı.');
    }

    return HealthConnectData(
      heartRate: heartRate,
      systolic: systolic,
      diastolic: diastolic,
      oxygen: oxygen,
      temperature: temperature,
      deviceName: deviceName,
      sourceApp: sourceApp,
      isSimulated: false,
    );
  }
}

