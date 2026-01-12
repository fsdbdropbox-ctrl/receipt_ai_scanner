class User {
  final String id;
  final String email;
  final String provider; // 'apple' or 'google'
  final bool hasFiscalProfile;

  User({
    required this.id,
    required this.email,
    required this.provider,
    required this.hasFiscalProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      provider: json['provider'] as String,
      hasFiscalProfile: json['hasFiscalProfile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'provider': provider,
      'hasFiscalProfile': hasFiscalProfile,
    };
  }
}
