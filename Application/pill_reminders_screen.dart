class SymptomLog {
  final String? id;
  final List<String> symptoms;
  final String? notes;
  final String severity;
  final DateTime? createdDate;

  const SymptomLog({
    this.id,
    required this.symptoms,
    this.notes,
    required this.severity,
    this.createdDate,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) => SymptomLog(
    id: json['id'],
    symptoms: List<String>.from(json['symptoms'] ?? []),
    notes: json['notes'],
    severity: json['severity'] ?? 'mild',
    createdDate: DateTime.tryParse(json['created_date'] ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms,
    'notes': notes,
    'severity': severity,
  };
}
