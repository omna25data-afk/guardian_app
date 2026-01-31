class PhysicalNotebook {
  final int bookNumber;
  final int entriesCount;
  final String? ministryRecordNumber;
  final int? templateId;
  final String? templateName;
  final int? issuanceYear;
  final List<int> years;

  PhysicalNotebook({
    required this.bookNumber,
    required this.entriesCount,
    this.ministryRecordNumber,
    this.templateId,
    this.templateName,
    this.issuanceYear,
    required this.years,
  });

  factory PhysicalNotebook.fromJson(Map<String, dynamic> json) {
    return PhysicalNotebook(
      bookNumber: json['book_number'] ?? 0,
      entriesCount: json['entries_count'] ?? 0,
      ministryRecordNumber: json['ministry_record_number'],
      templateId: json['template_id'],
      templateName: json['template_name'],
      issuanceYear: json['issuance_year'],
      years: (json['years'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }
}
