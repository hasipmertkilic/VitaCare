import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../welcome/welcome_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isSavingName = false;
  bool _isUploadingImage = false;

  String _name = 'Kullanıcı';
  String _email = '';
  String _createdAt = '';
  String? _profileImageUrl;

  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fetchUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _navigateToWelcome();
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _name = doc.data()?['name'] as String? ?? 'Kullanıcı';
        _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
        _email = user.email ?? '';
        _createdAt = _formatDate(user.metadata.creationTime);
        _isLoading = false;
      });
      _nameController.text = _name;
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _email = user.email ?? '';
        _isLoading = false;
      });
      _nameController.text = _name;
      _animationController.forward();
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  void _navigateToWelcome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  // ── Profil Resmi Seçme ve Yükleme ────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final uid = _auth.currentUser!.uid;
      final file = File(pickedFile.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile_picture.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      if (!mounted) return;
      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      _showSnackBar('Profil fotoğrafı güncellendi ✓', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnackBar('Fotoğraf yüklenirken bir hata oluştu.');
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _name) {
      _nameFocusNode.unfocus();
      return;
    }
    setState(() => _isSavingName = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({'name': newName});
        if (!mounted) return;
        setState(() => _name = newName);
        _showSnackBar('İsim güncellendi ✓', isError: false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Güncelleme başarısız, tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
        _nameFocusNode.unfocus();
      }
    }
  }

  // ── E-posta değiştirme ──────────────────────────────────────────────────
  Future<void> _changeEmail() async {
    final emailController = TextEditingController(text: _email);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'E-postayı Güncelle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dialogInputDecoration('Yeni e-posta adresi'),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'E-posta zorunludur.';
                        if (!v.contains('@'))
                          return 'Geçerli bir e-posta girin.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: _dialogInputDecoration('Mevcut şifreniz')
                          .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () => setS(() => obscure = !obscure),
                            ),
                          ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Şifre zorunludur.' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text(
                    'Güncelle',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(emailController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'Doğrulama e-postası gönderildi. Onayladıktan sonra e-postanız güncellenir.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      switch (e.code) {
        case 'wrong-password':
          _showSnackBar('Şifre hatalı.');
          break;
        case 'email-already-in-use':
          _showSnackBar('Bu e-posta zaten kullanımda.');
          break;
        case 'requires-recent-login':
          _showSnackBar('Lütfen tekrar giriş yapıp deneyin.');
          break;
        default:
          _showSnackBar('Hata: ${e.message}');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Beklenmeyen bir hata oluştu.');
    }
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkmak istediğinize emin misiniz?',
      confirmLabel: 'Çıkış Yap',
      isDestructive: false,
    );
    if (!confirmed) return;
    await _auth.signOut();
    _navigateToWelcome();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title: 'Hesabı Sil',
      message:
          'Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
      confirmLabel: 'Evet, Sil',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
      _navigateToWelcome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == 'requires-recent-login') {
        _showSnackBar('Lütfen tekrar giriş yapın ve tekrar deneyin.');
      } else {
        _showSnackBar('Hesap silinemedi: ${e.message}');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Beklenmeyen bir hata oluştu.');
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: isDestructive
                      ? Colors.red
                      : AppColors.primary,
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
          'Hesabım',
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
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _SectionHeader(title: 'Profil Bilgileri'),
                      const SizedBox(height: 10),
                      _buildEditableNameCard(),
                      _buildEmailCard(),
                      _ProfileCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Üyelik Tarihi',
                        value: _createdAt,
                      ),
                      _ProfileCard(
                        icon: Icons.verified_user_rounded,
                        title: 'Hesap Durumu',
                        value: 'Aktif',
                        valueColor: Colors.green.shade600,
                      ),

                      const SizedBox(height: 20),

                      _SectionHeader(title: 'Diğer'),
                      const SizedBox(height: 10),
                      _buildActionCard([
                        _ActionTileData(
                          icon: Icons.notifications_rounded,
                          title: 'Bildirimler',
                          onTap: () => _navigate(const NotificationsScreen()),
                        ),
                        _ActionTileData(
                          icon: Icons.lock_rounded,
                          title: 'Şifre Değiştir',
                          onTap: () => _navigate(const ChangePasswordScreen()),
                        ),
                        _ActionTileData(
                          icon: Icons.shield_rounded,
                          title: 'Gizlilik & Güvenlik',
                          onTap: () => _navigate(const PrivacyScreen()),
                        ),
                        _ActionTileData(
                          icon: Icons.help_outline_rounded,
                          title: 'Yardım & Destek',
                          onTap: () => _navigate(const HelpScreen()),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSignOutButton(),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _deleteAccount,
                        child: const Text(
                          'Hesabı Kalıcı Olarak Sil',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Avatar ──────────────────────────────────────────────────────────────
  // ── Avatar ──────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none, // Kritik: Taşan ikonun tıklanabilirliğini korur
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.6), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage:
                _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                if (_isUploadingImage)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -4, // İkonu biraz dışarı aldık daha şık dursun
          right: -4,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4, // Gölge ekledik
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                print(
                  "📸 KAMERA BUTONUNA TIKLANDI!",
                ); // Tıklandığını terminalden gör
                if (!_isUploadingImage) {
                  _pickAndUploadImage();
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0), // Tıklama alanını kocaman yaptık
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Editable name card ──────────────────────────────────────────────────
  Widget _buildEditableNameCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.badge_rounded, AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ad Soyad',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'İsminizi girin',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                ),
              ],
            ),
          ),
          if (_isSavingName)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (_, value, __) {
                final isDirty = value.text.trim() != _name;
                return isDirty
                    ? GestureDetector(
                        onTap: _saveName,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  // ── Email card with edit button ─────────────────────────────────────────
  Widget _buildEmailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.email_rounded, AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-posta',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _changeEmail,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(List<_ActionTileData> tiles) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    tile.icon,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                title: Text(
                  tile.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: tile.onTap,
              ),
              if (index < tiles.length - 1)
                const Divider(height: 1, indent: 60, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade100),
          ),
        ),
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTileData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTileData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
