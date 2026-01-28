import '../../registry/data/models/registry_entry.dart';

class DashboardData {
  final String welcomeMessage;
  final String dateGregorian;
  final String dateHijri;
  final DashboardStats stats;
  final RenewalStatus licenseStatus;
  final RenewalStatus cardStatus;
  final List<RegistryEntry> recentActivities;
  final int unreadNotifications; // Keep simple int for now

  DashboardData({
    required this.welcomeMessage,
    required this.dateGregorian,
    required this.dateHijri,
    required this.stats,
    required this.licenseStatus,
    required this.cardStatus,
    required this.recentActivities,
    required this.unreadNotifications,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] ?? {};
    final statusSummary = json['status_summary'] ?? {};
    
    return DashboardData(
      welcomeMessage: meta['welcome_message'] ?? '',
      dateGregorian: meta['date_gregorian'] ?? '',
      dateHijri: meta['date_hijri'] ?? '',
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      licenseStatus: RenewalStatus.fromJson(statusSummary['license'] ?? {}),
      cardStatus: RenewalStatus.fromJson(statusSummary['card'] ?? {}),
      recentActivities: (json['recent_activities'] as List?)
          ?.map((e) => RegistryEntry.fromJson(e))
          .toList() ?? [],
      unreadNotifications: json['unread_notifications_count'] ?? 0,
    );
  }
}

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
      totalEntries: json['total_entries'] ?? 0,
      totalDrafts: json['total_drafts'] ?? 0,
      totalDocumented: json['total_documented'] ?? 0,
      thisMonthEntries: json['this_month_entries'] ?? 0,
    );
  }
}

class RenewalStatus {
  final String label;
  final String color;
  final String? expiryDate;
  final int? daysRemaining;

  RenewalStatus({
    required this.label,
    required this.color,
    this.expiryDate,
    this.daysRemaining,
  });

  factory RenewalStatus.fromJson(Map<String, dynamic> json) {
    return RenewalStatus(
      label: json['status_label'] ?? 'غير محدد',
      color: json['status_color'] ?? 'gray',
      expiryDate: json['expiry_date'],
      daysRemaining: json['days_remaining'],
    );
  }
}
