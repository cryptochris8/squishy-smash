import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/constants.dart';

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
        primary: Palette.pink,
        secondary: Palette.cream,
        surface: Palette.bgSurface,
      ),
      scaffoldBackgroundColor: Palette.bgDeep,
      useMaterial3: true,
      // DS-4: brand the SwitchListTile at the theme level so every
      // toggle (currently Settings → haptics, mute; the future
      // toggles will inherit too) reads as Squishy Smash rather than
      // the default Material teal/grey. toxicLime is the on-state
      // accent used elsewhere for "active" / "earned" affordances.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Palette.cream;
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Palette.toxicLime;
          return Colors.white.withValues(alpha: 0.18);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Palette.toxicLime;
          return Colors.white24;
        }),
      ),
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
      navigatorObservers: <NavigatorObserver>[appRouteObserver],
    );
  }
}
