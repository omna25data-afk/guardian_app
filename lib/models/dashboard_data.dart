import 'package:flutter/material.dart';

// --- Main Data Structure for the Dashboard ---
class DashboardData {
  final String welcomeMessage;
  final String dateGregorian;
  final String dateHijri;
  final DashboardStats stats;
  final GuardianRenewalStatus licenseStatus;
  final GuardianRenewalStatus cardStatus;

  DashboardData({
    required this.welcomeMessage,
    required this.dateGregorian,
    required this.dateHijri,
    required this.stats,
    required this.licenseStatus,
    required this.cardStatus,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse status
    GuardianRenewalStatus parseStatus(Map<String, dynamic> statusJson) {
      return GuardianRenewalStatus.fromJson(statusJson);
    }

    return DashboardData(
      // Accessing nested meta object
      welcomeMessage: json['meta']?['welcome_message'] ?? 'مرحباً بك',
      dateGregorian: json['meta']?['date_gregorian'] ?? '',
      dateHijri: json['meta']?['date_hijri'] ?? '',

      // Accessing nested stats object
      stats: DashboardStats.fromJson(json['stats'] ?? {}),

      // Accessing nested status_summary object
      licenseStatus: parseStatus(json['status_summary']?['license'] ?? {}),
      cardStatus: parseStatus(json['status_summary']?['card'] ?? {}),
    );
  }
}

// --- Statistics Structure ---
class DashboardStats {
  final int totalEntries;
  final int totalDrafts;
  final int totalDocumented;
  final int thisMonthEntries;

  DashboardStats({
    required this.totalEntries,
    required this.totalDrafts,
    required this.totalDocumented,
    required this.thisMonthEntries,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEntries: json['total_entries'] as int? ?? 0,
      totalDrafts: json['total_drafts'] as int? ?? 0,
      totalDocumented: json['total_documented'] as int? ?? 0,
      thisMonthEntries: json['this_month_entries'] as int? ?? 0,
    );
  }
}

// --- Renewal Status Structure (for License and Card) ---
class GuardianRenewalStatus {
  final String label;
  final String statusColorName; // 'success', 'danger', 'warning'
  final DateTime? expiryDate;
  final int daysRemaining;

  GuardianRenewalStatus({
    required this.label,
    required this.statusColorName,
    this.expiryDate,
    required this.daysRemaining,
  });

  // Helper to map color names from API to Material Colors
  Color get color {
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

  factory GuardianRenewalStatus.fromJson(Map<String, dynamic> json) {
    return GuardianRenewalStatus(
      label: json['status_label'] as String? ?? 'غير معروف',
      statusColorName: json['status_color'] as String? ?? '',
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date']) : null,
      daysRemaining: json['days_remaining'] as int? ?? 0,
    );
  }
}
