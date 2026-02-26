import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class HeartRateChart extends StatelessWidget {
  final List<int> values;

  const HeartRateChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Henüz grafik verisi yok",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 🧠 1. VERİLERİ ANALİZ ET
    int dataMin = values.reduce(min);
    int dataMax = values.reduce(max);

    // 🧠 2. Y EKSENİNİ YUVARLA (Nabız değerleri)
    double minY = ((dataMin - 10) / 20).floor() * 20.0;
    if (minY < 0) minY = 0;

    double maxY = ((dataMax + 10) / 20).ceil() * 20.0;
    if (maxY == minY) maxY += 20;

    double yInterval = (maxY - minY) > 100 ? 40 : 20;

    // 🧠 3. X EKSENİ (ÖLÇÜMLER) ARALIĞI
    // Artık gün değil, ölçüm sırasını temsil ediyor
    double xInterval = 1;
    if (values.length > 14) {
      xInterval = (values.length / 5)
          .ceilToDouble(); // Çok ölçüm varsa aralıkları aç
    } else if (values.length > 7) {
      xInterval = 2; // 7-14 ölçüm varsa 2 ölçümde bir yazdır
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: values.length > 1 ? (values.length - 1).toDouble() : 1,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: xInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),

          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // Y EKSENİ (Nabız Değerleri)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),

            // X EKSENİ (Ölçüm Sırası: #1, #2, #3...)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value != value.toInt()) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "#${value.toInt() + 1}", // 1.G yerine #1, #2, #3 şeklinde ölçüm sırası yazacak
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 2),
              left: BorderSide(color: Colors.transparent, width: 0),
              right: BorderSide(color: Colors.transparent, width: 0),
              top: BorderSide(color: Colors.transparent, width: 0),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (i) => FlSpot(i.toDouble(), values[i].toDouble()),
              ),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              isStrokeCapRound: true,

              dotData: FlDotData(
                show: values.length <= 14,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: Colors.redAccent,
                  );
                },
              ),

              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.2),
                    Colors.redAccent.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
