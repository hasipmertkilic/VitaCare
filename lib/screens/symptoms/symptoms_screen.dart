import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _symptomOptions = [
    {'name': 'Baş Ağrısı', 'icon': Icons.psychology_rounded},
    {'name': 'Halsizlik', 'icon': Icons.battery_charging_full_rounded},
    {'name': 'Baş Dönmesi', 'icon': Icons.autorenew_rounded},
    {'name': 'Mide Bulantısı', 'icon': Icons.sick_rounded},
    {'name': 'Nefes Darlığı', 'icon': Icons.air_rounded},
    {'name': 'Göğüs Ağrısı', 'icon': Icons.favorite_border_rounded},
    {'name': 'Öksürük', 'icon': Icons.coronavirus_rounded},
    {'name': 'Üşüme / Titreme', 'icon': Icons.ac_unit_rounded},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String name) {
    setState(() {
      if (_selectedSymptoms.contains(name)) {
        _selectedSymptoms.remove(name);
      } else {
        _selectedSymptoms.add(name);
      }
    });
  }

  void _saveSymptoms() {
    if (_selectedSymptoms.isEmpty && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir belirti seçin veya not ekleyin.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Belirtileriniz başarıyla kaydedildi ✓'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Semptom Kaydı",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hissettiğiniz belirtileri seçin",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Bu bilgiler sağlık durumunuzun takibinde doktorunuza yardımcı olur.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _symptomOptions.map((item) {
                final name = item['name'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedSymptoms.contains(name);

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleSymptom(name),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            const Text(
              "Ekstra Notlar & Açıklama",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Detay eklemek isterseniz buraya yazabilirsiniz...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSymptoms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Belirtileri Kaydet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
