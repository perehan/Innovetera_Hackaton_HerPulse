import 'dart:math';
import '../models/vital_reading.dart';

class VitalsService {
  final _random = Random();

  VitalReading generateSimulatedReading() {
    final hr = 65 + _random.nextInt(30).toDouble();
    final temp = double.parse((36.2 + _random.nextDouble() * 1.5).toStringAsFixed(1));
    final stress = (20 + _random.nextInt(60)).toDouble();
    final oxygen = (94 + _random.nextInt(6)).toDouble();
    final motion = _random.nextInt(80).toDouble();

    String status = 'normal';
    if (hr > 100 || temp > 37.5 || stress > 70 || oxygen < 95) status = 'elevated';
    if (hr > 120 || temp > 38.5 || stress > 85 || oxygen < 92) status = 'high_risk';

    return VitalReading(
      heartRate: hr,
      temperature: temp,
      stressLevel: stress,
      oxygenLevel: oxygen,
      motionLevel: motion,
      overallStatus: status,
      timestamp: DateTime.now(),
    );
  }

  String getTrendDirection(double current, double? previous) {
    if (previous == null) return 'stable';
    if (current > previous * 1.05) return 'up';
    if (current < previous * 0.95) return 'down';
    return 'stable';
  }

  Map<String, String> getInsight(VitalReading v) {
    if (v.overallStatus == 'high_risk') {
      return {'text': 'Your vitals need immediate attention', 'action': 'Please rest and stay calm'};
    }
    if (v.overallStatus == 'elevated') {
      return {'text': 'Some readings are slightly elevated', 'action': 'Try deep breathing exercises'};
    }
    if (v.heartRate < 70 && v.stressLevel < 30) {
      return {'text': "You're very relaxed right now", 'action': 'Great time for meditation'};
    }
    if (v.oxygenLevel >= 98) {
      return {'text': 'Excellent oxygen levels', 'action': 'Keep up the good work'};
    }
    return {'text': 'Your vitals are looking stable', 'action': 'Stay hydrated and active'};
  }
}
