import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/vital_status.dart';

class HealthCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VitalStatus status;
  final VoidCallback? onTap;

  const HealthCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: status.color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: status.color.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: status.color.withOpacity(0.15),
              child: Icon(icon, color: status.color),
            ),
            const Spacer(),
            Text(title, style: TextStyle(color: AppColors.textSecondary)),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
