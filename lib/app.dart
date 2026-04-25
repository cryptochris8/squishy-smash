import 'package:flutter/material.dart';

import 'core/routes.dart';

/// Font family registered in pubspec.yaml under `flutter > fonts`.
/// Bundled (not fetched at runtime) so the app's typography is locked
/// in even on first launch with no network — critical for App Store
/// review devices that run under restricted connectivity.
const String _kBundledFontFamily = 'Fredoka';

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
        // Use the bundled Fredoka TTF instead of GoogleFonts.fredokaTextTheme
        // — same family name, but resolved from the asset bundle so no
        // network fetch happens. Variable font handles weights 300–700
        // automatically when TextStyle.fontWeight is set downstream.
        textTheme: base.textTheme.apply(fontFamily: _kBundledFontFamily),
      ),
      initialRoute: AppRoutes.menu,
      routes: AppRoutes.table,
    );
  }
}
