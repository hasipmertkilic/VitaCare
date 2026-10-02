import 'package:flutter_test/flutter_test.dart';
import 'package:vitacare/services/health_connect_service.dart';

void main() {
  test('HealthConnectData creates instance correctly', () {
    final data = HealthConnectData(
      heartRate: 75,
      systolic: 120,
      diastolic: 80,
      oxygen: 98,
      temperature: 36.6,
      deviceName: 'Galaxy Watch 6 (Health Connect)',
      sourceApp: 'Health Connect',
    );

    expect(data.heartRate, equals(75));
    expect(data.systolic, equals(120));
    expect(data.diastolic, equals(80));
    expect(data.oxygen, equals(98));
    expect(data.temperature, equals(36.6));
    expect(data.deviceName, contains('Health Connect'));
  });
}


