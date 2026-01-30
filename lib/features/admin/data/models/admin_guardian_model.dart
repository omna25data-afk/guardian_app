class AdminGuardian {
  final int id;
  final String name;
  final String serialNumber;
  final String? phone;
  final String? photoUrl;
  final String? employmentStatus;
  final String? employmentStatusColor;
  final String? licenseStatus;
  final String? licenseColor;
  final String? cardStatus;
  final String? cardColor;

  AdminGuardian({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.phone,
    this.photoUrl,
    this.employmentStatus,
    this.employmentStatusColor,
    this.licenseStatus,
    this.licenseColor,
    this.cardStatus,
    this.cardColor,
  });

  factory AdminGuardian.fromJson(Map<String, dynamic> json) {
    return AdminGuardian(
      id: json['id'],
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      phone: json['phone'],
      photoUrl: json['photo_url'],
      employmentStatus: json['employment_status'],
      employmentStatusColor: json['employment_status_color'],
      licenseStatus: json['license_status'],
      licenseColor: json['license_color'],
      cardStatus: json['card_status'],
      cardColor: json['card_color'],
    );
  }
}
