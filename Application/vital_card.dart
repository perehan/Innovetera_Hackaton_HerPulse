import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/pastel_background.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      variant: 'alert',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [GestureDetector(onTap: () => context.go('/dashboard'),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)))]),
            const Spacer(),
            const Icon(Icons.warning_rounded, color: Colors.white, size: 80),
            const SizedBox(height: 16),
            const Text('High Risk Detected', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Your vitals require immediate attention', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 32),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: const Column(children: [
                _Step(number: '1', text: 'Sit or lie down in a comfortable position'),
                _Step(number: '2', text: 'Take slow deep breaths (4s in, hold 4s, out 6s)'),
                _Step(number: '3', text: 'Loosen any tight clothing'),
                _Step(number: '4', text: 'Do not eat or drink anything'),
                _Step(number: '5', text: 'Call for help if symptoms worsen'),
              ])),
            const Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:911')),
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text('Call Emergency (911)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF500820),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => context.go('/dashboard'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("I'm Feeling Better", style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number, text;
  const _Step({required this.number, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
        child: Center(child: Text(number, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4))),
    ]),
  );
}
