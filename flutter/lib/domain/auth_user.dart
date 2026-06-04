class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.nickname,
    this.googleId,
  });

  final String id;
  final String email;
  final String? nickname;
  final String? googleId;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        nickname: json['nickname'] as String?,
        googleId: json['google_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'google_id': googleId,
      };

  AuthUser copyWith({String? nickname}) => AuthUser(
        id: id,
        email: email,
        nickname: nickname ?? this.nickname,
        googleId: googleId,
      );
}
