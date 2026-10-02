import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/vital_type.dart';
import '../vital_detail/blood_pressure_chart.dart';
import '../vital_detail/vital_chart.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Sağlık Trendleri & Grafikler",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Nabız"),
            Tab(text: "Tansiyon"),
            Tab(text: "Oksijen"),
            Tab(text: "Ateş"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: VitalChart(vitalType: VitalType.heartRate),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: BloodPressureChart(),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: VitalChart(vitalType: VitalType.oxygen),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: VitalChart(vitalType: VitalType.temperature),
          ),
        ],
      ),
    );
  }
}
