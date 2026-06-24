class VitalReading {
  final double heartRate;
  final double temperature;
  final double stressLevel;
  final double oxygenLevel;
  final double motionLevel;
  final String overallStatus;
  final String source;
  final DateTime timestamp;

  const VitalReading({
    required this.heartRate,
    required this.temperature,
    required this.stressLevel,
    required this.oxygenLevel,
    required this.motionLevel,
    required this.overallStatus,
    this.source = 'simulated',
    required this.timestamp,
  });

  factory VitalReading.fromJson(Map<String, dynamic> json) => VitalReading(
    heartRate: (json['heart_rate'] as num).toDouble(),
    temperature: (json['temperature'] as num).toDouble(),
    stressLevel: (json['stress_level'] as num).toDouble(),
    oxygenLevel: (json['oxygen_level'] as num).toDouble(),
    motionLevel: (json['motion_level'] as num).toDouble(),
    overallStatus: json['overall_status'] ?? 'normal',
    source: json['source'] ?? 'simulated',
    timestamp: DateTime.tryParse(json['created_date'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'heart_rate': heartRate,
    'temperature': temperature,
    'stress_level': stressLevel,
    'oxygen_level': oxygenLevel,
    'motion_level': motionLevel,
    'overall_status': overallStatus,
    'source': source,
  };
}
