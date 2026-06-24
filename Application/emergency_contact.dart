import '../models/vital_reading.dart';
import '../models/symptom_log.dart';

class PredictiveAlert {
  final String id;
  final String label;
  final String message;
  final String emoji;
  final int colorValue;

  const PredictiveAlert({
    required this.id,
    required this.label,
    required this.message,
    required this.emoji,
    required this.colorValue,
  });
}

class _PrecursorRule {
  final String id;
  final String symptom;
  final String label;
  final bool Function(VitalReading) check;
  final String message;
  final String emoji;
  final int colorValue;

  const _PrecursorRule({
    required this.id,
    required this.symptom,
    required this.label,
    required this.check,
    required this.message,
    required this.emoji,
    required this.colorValue,
  });
}

class PredictiveAlertsService {
  static final _rules = [
    _PrecursorRule(
      id: 'low_spo2_headache', symptom: 'headache', label: 'Headache Risk',
      check: (v) => v.oxygenLevel < 96,
      message: 'Your SpO₂ is lower than usual. Based on past patterns, low oxygen levels preceded headache episodes.',
      emoji: '🤕', colorValue: 0xFFF87171,
    ),
    _PrecursorRule(
      id: 'high_stress_dizziness', symptom: 'dizziness', label: 'Dizziness Risk',
      check: (v) => v.stressLevel > 65,
      message: 'Elevated stress levels have preceded dizziness in your history. Try slow breathing.',
      emoji: '😵', colorValue: 0xFFFBBF24,
    ),
    _PrecursorRule(
      id: 'high_hr_fatigue', symptom: 'fatigue', label: 'Fatigue Risk',
      check: (v) => v.heartRate > 95,
      message: 'Your heart rate is elevated. Past records show this pattern occurred before fatigue episodes.',
      emoji: '😴', colorValue: 0xFFA78BFA,
    ),
    _PrecursorRule(
      id: 'low_o2_breathing', symptom: 'shortness_of_breath', label: 'Breathing Risk',
      check: (v) => v.oxygenLevel < 95,
      message: 'Low oxygen levels have previously preceded shortness of breath. Avoid strenuous activity.',
      emoji: '😮', colorValue: 0xFF60A5FA,
    ),
    _PrecursorRule(
      id: 'high_temp_nausea', symptom: 'nausea', label: 'Nausea Risk',
      check: (v) => v.temperature > 37.3,
      message: 'A slight temperature elevation has historically appeared before nausea for you. Stay hydrated.',
      emoji: '🤢', colorValue: 0xFF34D399,
    ),
  ];

  Set<String> _getActivatedPatterns(List<SymptomLog> logs) {
    final ids = <String>{};
    for (final log in logs) {
      for (final rule in _rules) {
        if (log.symptoms.contains(rule.symptom)) ids.add(rule.id);
      }
    }
    return ids;
  }

  List<PredictiveAlert> getPredictiveAlerts(VitalReading vitals, List<SymptomLog> logs) {
    final activated = _getActivatedPatterns(logs);
    return _rules
        .where((r) => activated.contains(r.id) && r.check(vitals))
        .map((r) => PredictiveAlert(id: r.id, label: r.label, message: r.message, emoji: r.emoji, colorValue: r.colorValue))
        .toList();
  }

  List<PredictiveAlert> getHistoricalPatterns(List<SymptomLog> logs) {
    final activated = _getActivatedPatterns(logs);
    return _rules
        .where((r) => activated.contains(r.id))
        .map((r) => PredictiveAlert(id: r.id, label: r.label, message: r.message, emoji: r.emoji, colorValue: r.colorValue))
        .toList();
  }
}
