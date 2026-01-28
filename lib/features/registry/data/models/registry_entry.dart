class RegistryEntry {
  final int? id;
  final int? serialNumber;
  final String statusLabel; // Mapped from 'status_label'
  final String firstParty; // Mapped from 'first_party_name'
  final String secondParty; // Mapped from 'second_party_name'
  final String contractType; // Mapped from 'contract_type.name' or 'contract_type_name' depending on endpoint
  final String dateHijri; // Mapped from 'document_date.hijri'
  final String dateGregorian;
  final double totalFees; // Mapped from 'fees.total'

  RegistryEntry({
    this.id,
    this.serialNumber,
    required this.statusLabel,
    required this.firstParty,
    required this.secondParty,
    required this.contractType,
    required this.dateHijri,
    required this.dateGregorian,
    required this.totalFees,
  });

  factory RegistryEntry.fromJson(Map<String, dynamic> json) {
    // Handle flattened or nested structures if API varies
    final contract = json['contract_type'] ?? {};
    final dates = json['document_date'] ?? {};
    final fees = json['fees'] ?? {};

    return RegistryEntry(
      id: json['id'],
      serialNumber: json['serial_number'],
      statusLabel: json['status_label'] ?? '',
      firstParty: json['first_party_name'] ?? '',
      secondParty: json['second_party_name'] ?? '',
      contractType: contract['name'] ?? json['contract_type_name'] ?? '',
      dateHijri: dates['hijri'] ?? json['hijri_date'] ?? '',
      dateGregorian: dates['gregorian'] ?? json['document_gregorian_date'] ?? '',
      totalFees: (fees['total'] ?? json['fee_amount'] ?? 0).toDouble(),
    );
  }
}
