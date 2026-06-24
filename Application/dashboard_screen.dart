import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/pastel_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) context.go('/dashboard');
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
              const Icon(Icons.favorite, color: Color(0xFF500820), size: 56),
              const SizedBox(height: 12),
              const Text('CVD Early Warning', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF500820))),
              const Text('Your heart health companion', style: TextStyle(color: Color(0xFF6B6B7A))),
              const SizedBox(height: 40),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white.withOpacity(0.75),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: true,
                decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white.withOpacity(0.75),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF500820),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_loading ? 'Signing in...' : 'Sign In',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              )),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/register'),
                child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF9A1A38)))),
            ],
          ),
        ),
      ),
    );
  }
}
