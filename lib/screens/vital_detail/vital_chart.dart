import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/utils/vital_type.dart';

class VitalChart extends StatelessWidget {
  final VitalType vitalType;

  const VitalChart({super.key, required this.vitalType});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getVitalHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vitals')
        .orderBy('createdAt', descending: false)
        .limit(20)
        .snapshots();
  }

  Color _getChartColor() => switch (vitalType) {
    VitalType.heartRate => Colors.redAccent,
    VitalType.oxygen => Colors.blueAccent,
    VitalType.temperature => Colors.orangeAccent,
    VitalType.bloodPressure => Colors.deepPurpleAccent,
  };

  String _getUnit() => switch (vitalType) {
    VitalType.heartRate => "bpm",
    VitalType.oxygen => "%",
    VitalType.temperature => "°C",
    VitalType.bloodPressure => "mmHg",
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getVitalHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 380,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }

        final docs = snapshot.data!.docs;
        final chartColor = _getChartColor();
        final List<DateTime> measurementDates = [];
        final List<FlSpot> spots = [];

        double rawMinY = 1000.0;
        double rawMaxY = -1000.0;

        int spotIndex = 0;
        for (var doc in docs) {
          final data = doc.data();
          double y = 0;

          switch (vitalType) {
            case VitalType.heartRate:
              y = (data['heartRate'] as num?)?.toDouble() ?? 0;
              break;
            case VitalType.oxygen:
              y = (data['oxygen'] as num?)?.toDouble() ?? 0;
              break;
            case VitalType.temperature:
              y = (data['temperature'] as num?)?.toDouble() ?? 0;
              break;
            case VitalType.bloodPressure:
              y = (data['systolic'] as num?)?.toDouble() ?? 0;
              break;
          }

          // 🛠️ Hatalı verileri filtreleme (0 veya imkansız değerler)
          if (vitalType == VitalType.temperature && y < 30.0) continue;
          if (y <= 0) continue;

          final Timestamp? ts = data['createdAt'] as Timestamp?;
          measurementDates.add(ts?.toDate() ?? DateTime.now());

          if (y < rawMinY) rawMinY = y;
          if (y > rawMaxY) rawMaxY = y;

          spots.add(FlSpot(spotIndex.toDouble(), y));
          spotIndex++;
        }

        if (spots.isEmpty) return _emptyState();

        // 🌡️ ATEŞ İÇİN HASSAS VE TEMİZ ARAYÜZ (0.5 ARALIĞI)
        double minY, maxY, yInterval;
        if (vitalType == VitalType.temperature) {
          minY = 35.0;
          maxY = 41.0;
          yInterval = 0.5;
        } else {
          yInterval = (vitalType == VitalType.oxygen) ? 2.0 : 20.0;
          minY = (rawMinY - yInterval);
          maxY = (rawMaxY + yInterval);
        }

        return Container(
          height: 450,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummary(
                lastValue: spots.last.y,
                avg: spots.map((e) => e.y).reduce((a, b) => a + b) / spots.length,
                min: rawMinY,
                max: rawMaxY,
                color: chartColor,
                unit: _getUnit(),
                isFloat: vitalType == VitalType.temperature,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: chartColor,
                        getTooltipItems: (ts) => ts
                            .map(
                              (s) => LineTooltipItem(
                                "${s.y.toStringAsFixed(1)} ${_getUnit()}",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: yInterval,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: yInterval,
                          reservedSize: 35,
                          getTitlesWidget: (val, meta) {
                            return Text(
                              vitalType == VitalType.temperature
                                  ? val.toStringAsFixed(1)
                                  : val.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            int idx = value.toInt();
                            if (idx < 0 ||
                                idx >= measurementDates.length ||
                                (measurementDates.length > 5 && idx % 2 != 0)) {
                              return const SizedBox();
                            }
                            final date = measurementDates[idx];
                            final hourStr = date.hour.toString().padLeft(2, '0');
                            final minStr = date.minute.toString().padLeft(2, '0');
                            return Text(
                              "${date.day}/${date.month}\n$hourStr:$minStr",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: chartColor,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              chartColor.withValues(alpha: 0.2),
                              chartColor.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary({
    required double lastValue,
    required double avg,
    required double min,
    required double max,
    required Color color,
    required String unit,
    required bool isFloat,
  }) {
    String f(double v) => isFloat ? v.toStringAsFixed(1) : v.toInt().toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Son Ölçüm",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${f(lastValue)} $unit",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _stat("Min", f(min)),
            const SizedBox(width: 8),
            _stat("Ort", f(avg)),
            const SizedBox(width: 8),
            _stat("Max", f(max)),
          ],
        ),
      ],
    );
  }

  Widget _stat(String l, String v) => Column(
    children: [
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(
        v,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _emptyState() => Container(
    height: 380,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Text(
      "Veri bulunamadı veya hatalı veri filtrelendi.",
      style: TextStyle(color: Colors.grey),
    ),
  );
}
