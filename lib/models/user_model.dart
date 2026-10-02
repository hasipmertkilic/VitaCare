class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final dynamic createdAtVal = map['createdAt'];
    DateTime? dt;
    if (createdAtVal != null) {
      try {
        dt = (createdAtVal as dynamic).toDate() as DateTime?;
      } catch (_) {}
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'Kullanıcı',
      email: map['email'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
    };
  }
}
