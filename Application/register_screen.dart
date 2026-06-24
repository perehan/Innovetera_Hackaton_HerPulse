class EmergencyContact {
  final String? id;
  final String name;
  final String? relationship;
  final String? phone;
  final String email;
  final bool notifyOnHighRisk;

  const EmergencyContact({
    this.id,
    required this.name,
    this.relationship,
    this.phone,
    required this.email,
    this.notifyOnHighRisk = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    id: json['id'],
    name: json['name'] ?? '',
    relationship: json['relationship'],
    phone: json['phone'],
    email: json['email'] ?? '',
    notifyOnHighRisk: json['notify_on_high_risk'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'phone': phone,
    'email': email,
    'notify_on_high_risk': notifyOnHighRisk,
  };
}
