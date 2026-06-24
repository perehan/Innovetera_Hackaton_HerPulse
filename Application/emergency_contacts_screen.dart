class PillReminder {
  final String? id;
  final String medicationName;
  final String? dosage;
  final List<String> times;
  final bool active;
  final String? notes;
  final DateTime? lastTaken;

  const PillReminder({
    this.id,
    required this.medicationName,
    this.dosage,
    required this.times,
    this.active = true,
    this.notes,
    this.lastTaken,
  });

  factory PillReminder.fromJson(Map<String, dynamic> json) => PillReminder(
    id: json['id'],
    medicationName: json['medication_name'] ?? '',
    dosage: json['dosage'],
    times: List<String>.from(json['times'] ?? []),
    active: json['active'] ?? true,
    notes: json['notes'],
    lastTaken: DateTime.tryParse(json['last_taken'] ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'medication_name': medicationName,
    'dosage': dosage,
    'times': times,
    'active': active,
    'notes': notes,
  };
}
