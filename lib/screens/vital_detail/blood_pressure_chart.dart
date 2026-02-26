import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BloodPressureChart extends StatelessWidget {
  const BloodPressureChart({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getHistory() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vitals')
        .orderBy(
          'createdAt',
          descending: false,
        ) // Eskiden yeniye sıralama garantisi
        .limit(15)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 340,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 340,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "Henüz kan basıncı verisi bulunmuyor.\nÖlçümlerinizi ekledikçe grafik burada görünecek.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final systolicSpots = <FlSpot>[];
        final diastolicSpots = <FlSpot>[];
        final measurementDates = <DateTime>[];

        double rawMinY = double.infinity;
        double rawMaxY = double.negativeInfinity;

        // 🧠 VERİLERİ ÇEK VE ANALİZ ET
        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data();
          final Timestamp? ts = data['createdAt'] as Timestamp?;
          final DateTime date = ts != null ? ts.toDate() : DateTime.now();
          measurementDates.add(date);

          final double sys = (data['systolic'] as num?)?.toDouble() ?? 0;
          final double dia = (data['diastolic'] as num?)?.toDouble() ?? 0;

          if (sys > rawMaxY) rawMaxY = sys;
          if (sys < rawMinY) rawMinY = sys;
          if (dia > rawMaxY) rawMaxY = dia;
          if (dia < rawMinY) rawMinY = dia;

          systolicSpots.add(FlSpot(i.toDouble(), sys));
          diastolicSpots.add(FlSpot(i.toDouble(), dia));
        }

        // 🧠 DİNAMİK Y EKSENİ
        if (rawMinY == rawMaxY) {
          rawMinY -= 10;
          rawMaxY += 10;
        }

        double minY = ((rawMinY - 20) / 20).floor() * 20.0;
        if (minY < 0) minY = 0;

        double maxY = ((rawMaxY + 20) / 20).ceil() * 20.0;
        if (maxY < 140) maxY = 140; // 120 normal çizgisini rahat görmek için
        if (maxY == minY) maxY += 20;

        double xInterval = docs.length > 7
            ? (docs.length / 5).ceilToDouble()
            : 1;

        return Container(
          height: 380,
          padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷️ GÖSTERGE (LEGEND)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    "Sistolik",
                    const Color(0xFFFF6B6B),
                  ), // Modern Kırmızı
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    "Diyastolik",
                    const Color(0xFF4D96FF),
                  ), // Modern Mavi
                ],
              ),
              const SizedBox(height: 32),

              // 📈 GRAFİK WIDGET'I
              Expanded(
                child: LineChart(
                  LineChartData(
                    clipData: const FlClipData.all(),
                    minX: 0,
                    maxX: (docs.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,

                    // Dokunma (Touch) Ayarları: Tooltip Gösterimi
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.black87,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final isSystolic = touchedSpot.barIndex == 0;
                            return LineTooltipItem(
                              '${touchedSpot.y.toInt()} mmHg\n',
                              TextStyle(
                                color: isSystolic
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF4D96FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: isSystolic ? 'Sistolik' : 'Diyastolik',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),

                    // Normal Değer Çizgileri
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 120,
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(bottom: 4),
                            labelResolver: (_) => "120",
                            style: TextStyle(
                              color: const Color(0xFFFF6B6B).withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        HorizontalLine(
                          y: 80,
                          color: const Color(0xFF4D96FF).withOpacity(0.3),
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(bottom: 4),
                            labelResolver: (_) => "80",
                            style: TextStyle(
                              color: const Color(0xFF4D96FF).withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Arkaplan Izgarası
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      drawVerticalLine:
                          false, // Sadece yatay çizgiler kalsın (Daha temiz)
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),

                    // Eksen Yazıları
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      // SOL EKSEN (Tansiyon Değerleri)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),

                      // ALT EKSEN (Gün/Ay)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: xInterval,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= measurementDates.length)
                              return const SizedBox();

                            DateTime date = measurementDates[index];
                            String dayMonth =
                                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";

                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                dayMonth,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Çerçeve Kenarlığı
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.5,
                        ),
                        left: const BorderSide(color: Colors.transparent),
                        right: const BorderSide(color: Colors.transparent),
                        top: const BorderSide(color: Colors.transparent),
                      ),
                    ),

                    // Çizgiler ve Stilleri
                    lineBarsData: [
                      // 🔴 SİSTOLİK ÇİZGİSİ
                      LineChartBarData(
                        spots: systolicSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFFFF6B6B),
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show:
                              true, // Dokunma hissi için noktalar her zaman kalsın ama küçük olsun
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFFFF6B6B),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B).withOpacity(0.25),
                              const Color(0xFFFF6B6B).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // 🔵 DİYASTOLİK ÇİZGİSİ
                      LineChartBarData(
                        spots: diastolicSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF4D96FF),
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF4D96FF),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4D96FF).withOpacity(0.25),
                              const Color(0xFF4D96FF).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 600), // Yeni kullanım
                  curve: Curves.easeInOutCubic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🏷️ Yardımcı Widget: Gösterge Oluşturucu
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
