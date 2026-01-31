import 'package:flutter/material.dart';

class RecordBook {
  final int id;
  // ... existing fields ...
  final int number; // Mapped from 'book_number'
  final String title; // Mapped from 'name'
  final int hijriYear;
  final String statusLabel;
  final String contractType; // Mapped from 'contract_type_name'
  final int totalPages;
  final int usedPages; // Mapped from 'constraints_count'
  final int usagePercentage; // Mapped from 'used_percentage'
  final String categoryLabel; // New field for hierarchical grouping
  final bool isActive; // To distinguish current year's books
  final int totalEntries;
  final int completedEntries;
  final int draftEntries;
  final int notebooksCount;
  final int bookNumber;
  final int entriesCount;
  final String? ministryRecordNumber;
  final int? templateId;
  final String? templateName;
  final int? issuanceYear;
  final List<int> years;

  RecordBook({
    required this.bookNumber,
    required this.entriesCount,
    this.ministryRecordNumber,
    this.templateId,
    this.templateName,
    this.issuanceYear,
    required this.years,
  });

  factory RecordBook.fromJson(Map<String, dynamic> json) {
    return RecordBook(
      contractTypeId: json['contract_type_id'],
    );
  }

  Color get statusColor {
    // Basic logic mapping status text to color
    if (statusLabel.contains('نشط') || statusLabel.contains('Active')) return Colors.green;
    if (statusLabel.contains('مكتمل') || statusLabel.contains('Full')) return Colors.blue;
    if (statusLabel.contains('ملغى') || statusLabel.contains('Cancelled')) return Colors.red;
    return Colors.grey;
  }
}
