class User {
  final int id;
  final String name;
  final String phoneNumber; // Changed from email to phoneNumber
  final String? token;
  final bool isGuardian;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.token,
    required this.isGuardian,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json;
    return User(
      id: userData['id'],
      name: userData['name'],
      phoneNumber: userData['phone_number'] ?? '', // Map from phone_number
      token: json['access_token'] ?? json['token'],
      isGuardian: (userData['roles'] as List?)?.contains('legitimate_guardian') ?? false,
    );
  }
}
