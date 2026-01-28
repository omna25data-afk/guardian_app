class RecordBook {
  final int id;
  final int number; // Mapped from 'book_number'
  final String title; // Mapped from 'name'
  final int hijriYear;
  final String statusLabel;
  final String contractType; // Mapped from 'contract_type_name'
  final int totalPages;
  final int usedPages; // Mapped from 'constraints_count'
  final int usagePercentage; // Mapped from 'used_percentage'
  
  RecordBook({
    required this.id,
    required this.number,
    required this.title,
    required this.hijriYear,
    required this.statusLabel,
    required this.contractType,
    required this.totalPages,
    required this.usedPages,
    required this.usagePercentage,
  });

  factory RecordBook.fromJson(Map<String, dynamic> json) {
    return RecordBook(
      id: json['id'],
      number: json['book_number'] ?? 0,
      title: json['name'] ?? '',
      hijriYear: json['hijri_year'] ?? 0,
      statusLabel: json['status_label'] ?? '',
      contractType: json['contract_type_name'] ?? json['type_name'] ?? '',
      totalPages: json['total_pages'] ?? 0,
      usedPages: json['constraints_count'] ?? 0,
      usagePercentage: json['used_percentage'] ?? 0,
    );
  }
}
