import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback için gerekli
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'vital_input_screen/vital_input_screen.dart';
import '../../core/theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [DashboardScreen(), ProfileScreen()];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      // Sekme değiştirirken hafif titreşim hissi verir (Premium hissiyat)
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sayfanın alt barın kavisli kısmının arkasına uzanmasını sağlar
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),

      // 🔥 ORTA + BUTONU (FAB)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Tam yuvarlak
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          // VitalInputScreen'i aşağıdan yukarıya şık bir şekilde açar
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const VitalInputScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutQuart;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            ),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔻 BOTTOM BAR
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10, // Kavis boşluğunu biraz artırdık ki daha şık dursun
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons
                      .space_dashboard_rounded, // Daha modern yuvarlak ikonlar
                  label: "Özet",
                  index: 0,
                ),
                const SizedBox(width: 48), // Ortadaki FAB için ayrılan alan
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: "Profil",
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Alt bar sekmeleri için özel widget çıkarımı (Kod tekrarını önler ve temiz tutar)
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor:
            Colors.transparent, // Tıklama dalgasını kapatır (daha temiz bir UX)
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(
                icon,
                color: color,
                size: isSelected ? 26 : 24, // Aktifken hafifçe büyür
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
