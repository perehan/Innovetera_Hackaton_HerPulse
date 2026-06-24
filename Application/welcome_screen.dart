import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/predictive_alerts_service.dart';
import '../../widgets/pastel_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  final _alertsService = PredictiveAlertsService();
  List<PredictiveAlert> _patterns = [];

  final _historyData = List.generate(6, (i) => {
    'normal': (50 + (i * 7) % 40).toDouble(),
    'elevated': (5 + (i * 4) % 25).toDouble(),
    'high_risk': ((i * 2) % 15).toDouble(),
  });

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final logs = await _api.getSymptomLogs(limit: 50);
      setState(() => _patterns = _alertsService.getHistoricalPatterns(logs));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Health History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF500820))),
            const Text('6-month overview', style: TextStyle(fontSize: 13, color: Color(0xFF6B6B7A))),
            const SizedBox(height: 20),
            Container(height: 200, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(20)),
              child: BarChart(BarChartData(
                barGroups: _historyData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: e.value['normal']!, color: const Color(0xFF22C55E), width: 8, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: e.value['elevated']!, color: const Color(0xFFF59E0B), width: 8, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: e.value['high_risk']!, color: const Color(0xFFEF4444), width: 8, borderRadius: BorderRadius.circular(4)),
                ])).toList(),
                gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) { const m = ['Jan','Feb','Mar','Apr','May','Jun'];
                      return Text(m[v.toInt() % 6], style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B7A))); })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ))),
            const SizedBox(height: 24),
            if (_patterns.isNotEmpty) ...[
              const Text('⚡ Patterns in Your History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E2E3A))),
              const SizedBox(height: 12),
              ..._patterns.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(p.colorValue).withOpacity(0.3))),
                  child: Row(children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p.label} Pattern', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E2E3A))),
                      const SizedBox(height: 2),
                      Text(p.message, style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7A), height: 1.4)),
                    ])),
                  ]),
                ),
              )),
            ],
          ]),
        ),
      ),
    );
  }
}
