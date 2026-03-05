import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;

  // Toggles
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _weeklyReport = true;
  bool _appUpdates = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _pushEnabled = data['pushEnabled'] as bool? ?? true;
          _emailEnabled = data['emailEnabled'] as bool? ?? false;
          _weeklyReport = data['weeklyReport'] as bool? ?? true;
          _appUpdates = data['appUpdates'] as bool? ?? true;
          _promotions = data['promotions'] as bool? ?? false;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePreference(String key, bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set({key: value}, SetOptions(merge: true));
  }

  void _updateToggle(String key, bool value, void Function() stateChange) {
    setState(stateChange);
    _savePreference(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Bildirim Kanalları'),
                  const SizedBox(height: 10),
                  _buildToggleCard([
                    _ToggleItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: AppColors.primary,
                      title: 'Push Bildirimleri',
                      subtitle: 'Uygulama içi anlık bildirimler',
                      value: _pushEnabled,
                      onChanged: (v) => _updateToggle(
                        'pushEnabled',
                        v,
                        () => _pushEnabled = v,
                      ),
                    ),
                    _ToggleItem(
                      icon: Icons.email_rounded,
                      iconColor: Colors.orange,
                      title: 'E-posta Bildirimleri',
                      subtitle: 'Önemli güncellemeler e-postanıza gönderilir',
                      value: _emailEnabled,
                      onChanged: (v) => _updateToggle(
                        'emailEnabled',
                        v,
                        () => _emailEnabled = v,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _sectionHeader('Bildirim Türleri'),
                  const SizedBox(height: 10),
                  _buildToggleCard([
                    _ToggleItem(
                      icon: Icons.bar_chart_rounded,
                      iconColor: Colors.teal,
                      title: 'Haftalık Rapor',
                      subtitle: 'Her hafta özet rapor alın',
                      value: _weeklyReport,
                      onChanged: (v) => _updateToggle(
                        'weeklyReport',
                        v,
                        () => _weeklyReport = v,
                      ),
                    ),
                    _ToggleItem(
                      icon: Icons.system_update_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Uygulama Güncellemeleri',
                      subtitle: 'Yeni özellikler ve iyileştirmeler',
                      value: _appUpdates,
                      onChanged: (v) =>
                          _updateToggle('appUpdates', v, () => _appUpdates = v),
                    ),
                    _ToggleItem(
                      icon: Icons.local_offer_rounded,
                      iconColor: Colors.pinkAccent,
                      title: 'Kampanya & Teklifler',
                      subtitle: 'Özel fırsatlar ve indirimler',
                      value: _promotions,
                      onChanged: (v) =>
                          _updateToggle('promotions', v, () => _promotions = v),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tercihleriniz otomatik olarak kaydedilir. Push bildirimleri için cihaz bildirim izninin açık olması gerekmektedir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleCard(List<_ToggleItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: item.value,
                      onChanged: item.onChanged,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              if (idx < items.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
