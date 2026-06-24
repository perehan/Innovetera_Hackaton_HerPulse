import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: CVDApp()));
}

class CVDApp extends ConsumerWidget {
  const CVDApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CVD Early Warning Patch',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static const primaryColor = Color(0xFF500820);
  static const secondaryColor = Color(0xFF9A1A38);
  static const accentColor = Color(0xFFC86878);
  static const blushColor = Color(0xFFE8A8B0);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600),
    ),
    scaffoldBackgroundColor: const Color(0xFFFDF4F5),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.75),
    ),
  );
}
