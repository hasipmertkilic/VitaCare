import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/vital_analyzer.dart';
import '../../core/utils/vital_status.dart';
import '../../core/utils/vital_type.dart';

import 'dashboard_controller.dart';
import 'dashboard_repository.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/health_card.dart';

import '../alert/danger_alert_bar.dart';
import '../vital_detail/vital_detail_screen.dart';
import '../welcome/welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardController _controller;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _userName = 'Kullanıcı';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = DashboardController(
      DashboardRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final name = await _controller.getUserName();
      if (!mounted) return;
      setState(() {
        _userName = name;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  bool _hasDanger(List<VitalStatus> statuses) =>
      statuses.any((s) => s.level == VitalLevel.danger);

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  void _openDetail(VitalType type) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => VitalDetailScreen(vitalType: type),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? _buildErrorState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadUser,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: [
                          DashboardHeader(
                            userName: _userName,
                            onLogout: _logout,
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildVitalsStream(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVitalsStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _controller.getLatestVital(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStreamErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final data = snapshot.data!.docs.first.data();
        return _buildVitalsContent(data);
      },
    );
  }

  Widget _buildVitalsContent(Map<String, dynamic> data) {
    final int heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
    final int oxygen = (data['oxygen'] as num?)?.toInt() ?? 0;
    final double temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
    final int systolic = (data['systolic'] as num?)?.toInt() ?? 0;
    final int diastolic = (data['diastolic'] as num?)?.toInt() ?? 0;

    final heartStatus = VitalAnalyzer.heartRate(heartRate);
    final oxygenStatus = VitalAnalyzer.oxygen(oxygen);
    final tempStatus = VitalAnalyzer.temperature(temperature);
    final bpStatus = VitalAnalyzer.bloodPressure(systolic, diastolic);

    final statuses = [heartStatus, oxygenStatus, tempStatus, bpStatus];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasDanger(statuses)) ...[
          const DangerAlertBar(),
          const SizedBox(height: 16),
        ],

        // Last updated timestamp
        if (data['timestamp'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLastUpdated(data['timestamp']),
          ),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
          children: [
            HealthCard(
              title: 'Nabız',
              value: '$heartRate bpm',
              status: heartStatus,
              icon: Icons.favorite_rounded,
              onTap: () => _openDetail(VitalType.heartRate),
            ),
            HealthCard(
              title: 'Kan Basıncı',
              value: '$systolic / $diastolic',
              status: bpStatus,
              icon: Icons.monitor_heart_rounded,
              onTap: () => _openDetail(VitalType.bloodPressure),
            ),
            HealthCard(
              title: 'Oksijen',
              value: '%$oxygen',
              status: oxygenStatus,
              icon: Icons.air_rounded,
              onTap: () => _openDetail(VitalType.oxygen),
            ),
            HealthCard(
              title: 'Vücut Isısı',
              value: '${temperature.toStringAsFixed(1)} °C',
              status: tempStatus,
              icon: Icons.thermostat_rounded,
              onTap: () => _openDetail(VitalType.temperature),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLastUpdated(dynamic timestamp) {
    String timeText = '';
    try {
      final DateTime dt = (timestamp as dynamic).toDate() as DateTime;
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        timeText = 'Az önce güncellendi';
      } else if (diff.inMinutes < 60) {
        timeText = '${diff.inMinutes} dakika önce güncellendi';
      } else if (diff.inHours < 24) {
        timeText = '${diff.inHours} saat önce güncellendi';
      } else {
        timeText = '${diff.inDays} gün önce güncellendi';
      }
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 48,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz sağlık verisi yok',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sağlık verileriniz burada görünecek.\nCihazınızı bağlayarak ölçüm alabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text(
            'Veriler yüklenemedi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Bağlantınızı kontrol edip sayfayı aşağı çekerek yenileyin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bir hata oluştu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lütfen uygulamayı yeniden başlatın.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadUser();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
