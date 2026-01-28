import 'package:flutter/material.dart';

class RegistryEntry {
  final int id;
  final String serialNumber;
  final String firstPartyName;
  final String secondPartyName;
  final String contractTypeName;
  final String documentHijriDate;
  final String statusLabel;
  final String statusColorName;

  RegistryEntry({
    required this.id,
    required this.serialNumber,
    required this.firstPartyName,
    required this.secondPartyName,
    required this.contractTypeName,
    required this.documentHijriDate,
    required this.statusLabel,
    required this.statusColorName,
  });

  Color get statusColor {
    switch (statusColorName) {
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'draft':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  factory RegistryEntry.fromJson(Map<String, dynamic> json) {
    return RegistryEntry(
      id: json['id'] as int? ?? 0,
      serialNumber: json['serial_number'] as String? ?? '-',
      firstPartyName: json['first_party_name'] as String? ?? '',
      secondPartyName: json['second_party_name'] as String? ?? '',
      contractTypeName: json['contract_type_name'] as String? ?? '',
      documentHijriDate: json['document_hijri_date'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      statusColorName: json['status_color'] as String? ?? '',
    );
  }
}
