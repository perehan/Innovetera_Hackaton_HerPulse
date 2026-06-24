import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/vital_detail/vital_detail_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/symptoms/symptoms_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/pills/pill_reminders_screen.dart';
import '../screens/emergency/emergency_contacts_screen.dart';
import '../screens/alert/alert_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../widgets/bottom_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (ctx, state) => const WelcomeScreen()),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardScreen()),
          GoRoute(path: '/history', builder: (ctx, state) => const HistoryScreen()),
          GoRoute(path: '/symptoms', builder: (ctx, state) => const SymptomsScreen()),
          GoRoute(path: '/chat', builder: (ctx, state) => const ChatScreen()),
          GoRoute(
            path: '/vital/:type',
            builder: (ctx, state) => VitalDetailScreen(type: state.pathParameters['type']!),
          ),
          GoRoute(path: '/pills', builder: (ctx, state) => const PillRemindersScreen()),
          GoRoute(path: '/emergency-contacts', builder: (ctx, state) => const EmergencyContactsScreen()),
        ],
      ),
      GoRoute(path: '/alert', builder: (ctx, state) => const AlertScreen()),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
