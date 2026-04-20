import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routes.dart';

class SquishySmashApp extends StatelessWidget {
  const SquishySmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF8FB8),
        secondary: Color(0xFFFFD36E),
        surface: Color(0xFF1A1320),
      ),
      scaffoldBackgroundColor: const Color(0xFF120B17),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Squishy Smash',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.fredokaTextTheme(base.textTheme),
      ),
      initialRoute: AppRoutes.menu,
      routes: AppRoutes.table,
    );
  }
}
