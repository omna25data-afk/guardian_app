import 'package:flutter/material.dart';

class RecordBook {
  final int id;
  final int number; // Changed from book_number
  final String title; // Changed from name
  final String contractType; // Changed from contract_type_name
  final int totalPages;
  final int constraintsCount;
  final int usagePercentage; // Changed from used_percentage
  final String statusLabel;
  final String statusColorName; // Changed from status_color

  RecordBook({
    required this.id,
    required this.number,
    required this.title,
    required this.contractType,
    required this.totalPages,
    required this.constraintsCount,
    required this.usagePercentage,
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
      default:
        return Colors.grey;
    }
  }

  factory RecordBook.fromJson(Map<String, dynamic> json) {
    return RecordBook(
      id: json['id'] as int? ?? 0,
      number: json['book_number'] as int? ?? 0, // Mapped from book_number
      title: json['name'] as String? ?? '', // Mapped from name
      contractType: json['contract_type_name'] as String? ?? '', // Mapped from contract_type_name
      totalPages: json['total_pages'] as int? ?? 0,
      constraintsCount: json['constraints_count'] as int? ?? 0,
      usagePercentage: (json['used_percentage'] as num? ?? 0).toInt(), // Mapped from used_percentage and ensured as int
      statusLabel: json['status_label'] as String? ?? '',
      statusColorName: json['status_color'] as String? ?? '', // Mapped from status_color
    );
  }
}
