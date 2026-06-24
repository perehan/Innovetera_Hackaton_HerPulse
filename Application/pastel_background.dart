import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/pastel_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF500820))),
              const SizedBox(height: 32),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white.withOpacity(0.75),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: true,
                decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white.withOpacity(0.75),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF500820),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_loading ? 'Creating...' : 'Create Account',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              )),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in', style: TextStyle(color: Color(0xFF9A1A38)))),
            ],
          ),
        ),
      ),
    );
  }
}
