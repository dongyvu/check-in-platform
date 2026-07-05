class AppProfile {
  final String id;
  final String? email;
  final String displayName;
  final String role;
  final String? avatarUrl;

  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      displayName: (map['display_name'] as String?) ?? '用户',
      role: (map['role'] as String?) ?? 'user',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}
