import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    _PolicySection(
      title: '1. Toplanan Veriler',
      content:
          'Hizmetimizi kullanırken ad, e-posta adresi ve kullanım istatistikleri gibi bilgiler toplanmaktadır. Bu veriler yalnızca hizmeti sunmak amacıyla kullanılır.',
    ),
    _PolicySection(
      title: '2. Verilerin Kullanımı',
      content:
          'Toplanan veriler; hesap yönetimi, kişiselleştirilmiş deneyim sunumu ve uygulama güvenliğinin sağlanması amacıyla kullanılmaktadır. Reklam veya üçüncü taraf pazarlama amaçlı kullanılmaz.',
    ),
    _PolicySection(
      title: '3. Veri Paylaşımı',
      content:
          'Kişisel verileriniz hiçbir koşulda üçüncü taraflarla satılmaz veya kiralanmaz. Yasal zorunluluk olmadıkça yetkisiz kişi veya kuruluşlarla paylaşılmaz.',
    ),
    _PolicySection(
      title: '4. Veri Güvenliği',
      content:
          'Verileriniz endüstri standardı SSL/TLS şifrelemesiyle iletilmekte, güvenli sunucularda saklanmaktadır. Düzenli güvenlik denetimleri gerçekleştirilmektedir.',
    ),
    _PolicySection(
      title: '5. Çerezler ve İzleme',
      content:
          'Uygulamamız oturum yönetimi için zorunlu çerezler kullanmaktadır. Analitik amaçlı kullanım tercihlerinizi bildirim ayarlarından yönetebilirsiniz.',
    ),
    _PolicySection(
      title: '6. Kullanıcı Hakları',
      content:
          'KVKK ve GDPR kapsamında verilerinize erişme, düzeltme, silme ve taşıma haklarına sahipsiniz. Talepleriniz için destek@uygulama.com adresine başvurabilirsiniz.',
    ),
    _PolicySection(
      title: '7. Veri Saklama Süresi',
      content:
          'Verileriniz hesabınız aktif olduğu sürece veya yasal zorunluluklar gerektirdiği süre boyunca saklanır. Hesap silme işlemi sonrasında tüm verileriniz 30 gün içinde sistemden kaldırılır.',
    ),
    _PolicySection(
      title: '8. Politika Güncellemeleri',
      content:
          'Bu politika zaman zaman güncellenebilir. Önemli değişiklikler e-posta veya uygulama bildirimi yoluyla size iletilecektir. Güncel politikayı her zaman bu sayfadan inceleyebilirsiniz.',
    ),
  ];

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
          'Gizlilik & Güvenlik',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withOpacity(0.12),
                    Colors.indigo.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.indigo,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gizlilik Politikamız',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Son güncelleme: Ocak 2025',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Policy sections
            Container(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              section.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Sorularınız için: destek@uygulama.com',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});
}
