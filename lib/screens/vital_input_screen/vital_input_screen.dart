import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class VitalInputScreen extends StatefulWidget {
  const VitalInputScreen({super.key});

  @override
  State<VitalInputScreen> createState() => _VitalInputScreenState();
}

class _VitalInputScreenState extends State<VitalInputScreen> {
  final heartRateController = TextEditingController();
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final oxygenController = TextEditingController();
  final temperatureController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> saveVitals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Boş alan kontrolü
    if (heartRateController.text.trim().isEmpty ||
        systolicController.text.trim().isEmpty ||
        diastolicController.text.trim().isEmpty ||
        oxygenController.text.trim().isEmpty ||
        temperatureController.text.trim().isEmpty) {
      _showSnack("Lütfen tüm sağlık verilerini doldurun.", isError: true);
      return;
    }

    // Virgül ile girilen değerleri noktaya çevirip parse etme (Örn: 36,5 -> 36.5)
    final tempText = temperatureController.text.replaceAll(',', '.');

    final heartRate = int.tryParse(heartRateController.text);
    final systolic = int.tryParse(systolicController.text);
    final diastolic = int.tryParse(diastolicController.text);
    final oxygen = int.tryParse(oxygenController.text);
    final temperature = double.tryParse(tempText);

    if (heartRate == null ||
        systolic == null ||
        diastolic == null ||
        oxygen == null ||
        temperature == null) {
      _showSnack("Lütfen geçerli sayısal değerler girin.", isError: true);
      return;
    }

    try {
      setState(() => isLoading = true);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vitals')
          .add({
            'heartRate': heartRate,
            'systolic': systolic,
            'diastolic': diastolic,
            'oxygen': oxygen,
            'temperature': temperature,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      _showSnack("Sağlık verileriniz başarıyla kaydedildi.", isError: false);
      Navigator.pop(context); // İşlem bitince ekranı kapat
    } catch (_) {
      _showSnack(
        "Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    heartRateController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    oxygenController.dispose();
    temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Ekranda boş bir yere tıklanınca klavyeyi kapatır
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            "Yeni Kayıt Ekle",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Güncel değerlerinizi girerek sağlık durumunuzu takip edin.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              _InputCard(
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                label: "Nabız",
                hint: "Örn: 72",
                unit: "bpm",
                controller: heartRateController,
                textInputAction: TextInputAction.next,
              ),

              // Sistolik ve Diastolik değerlerini yan yana şık bir şekilde alıyoruz
              Row(
                children: [
                  Expanded(
                    child: _InputCard(
                      icon: Icons.arrow_upward_rounded,
                      iconColor: Colors.orange,
                      label: "Sistolik",
                      hint: "120",
                      unit: "mmHg",
                      controller: systolicController,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InputCard(
                      icon: Icons.arrow_downward_rounded,
                      iconColor: Colors.blueAccent,
                      label: "Diastolik",
                      hint: "80",
                      unit: "mmHg",
                      controller: diastolicController,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              _InputCard(
                icon: Icons.water_drop_rounded,
                iconColor: Colors.lightBlue,
                label: "Kan Oksijeni",
                hint: "Örn: 98",
                unit: "%",
                controller: oxygenController,
                textInputAction: TextInputAction.next,
              ),

              _InputCard(
                icon: Icons.thermostat_rounded,
                iconColor: Colors.deepOrange,
                label: "Vücut Isısı",
                hint: "Örn: 36.5",
                unit: "°C",
                controller: temperatureController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction
                    .done, // Son alan olduğu için "Bitti" butonu çıkar
              ),

              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Verileri Kaydet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40), // Alt boşluk
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;
  final String unit;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const _InputCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
    required this.unit,
    required this.controller,
    this.keyboardType = TextInputType.number,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Daha yumuşak köşeler
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.02,
            ), // Çok hafif, modern bir gölge
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4, bottom: 0),
                    // Sağ tarafa ölçü birimini ekliyoruz (bpm, % vb.)
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
