import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Reachable from Settings → About. Shows version, credits, support
/// links, and the privacy / support web URLs in a single quiet
/// surface. Apple App Review expects an in-app About / Credits
/// surface for any 4+ rated app shipping crash reporting; this is
/// also the only place we surface squishysmash.com URLs from
/// gameplay.
///
/// Pre-fix (P1.17) the route did not exist — both UX and UI-design
/// subagents flagged it as a missing surface in PRELAUNCH_AUDIT.md.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // GAME_POLISH_AUDIT.md UI-4: the hardcoded '0.1.1' string lagged
  // the live App Store build (0.1.2) — and would have lagged again
  // on every release. Now reads APP_VERSION from --dart-define so a
  // release build can pass `--dart-define=APP_VERSION=$VERSION` and
  // the value matches what shipped. Default tracks the in-flight
  // pubspec version so local dev/test still sees a plausible string.
  static const String _kAppVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '0.1.3');
  static const String _kSupportEmail = 'support@squishysmash.com';
  static const String _kWebsite = 'https://squishysmash.com';
  static const String _kPrivacyUrl = 'https://squishysmash.com/privacy';
  static const String _kSupportUrl = 'https://squishysmash.com/support';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      appBar: AppBar(
        // GAME_POLISH_AUDIT.md UI-2: only screen with an opaque
        // bgSurface AppBar — every other (collection, shop, settings)
        // uses Colors.transparent. Pre-fix the About screen read as
        // a different product surface. Now matches the rest.
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('About'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const _Brand(),
          const SizedBox(height: 28),
          const _Section('Version'),
          const _PlainRow(label: 'App version', value: _kAppVersion),
          const SizedBox(height: 24),
          const _Section('Support'),
          _LinkRow(
            label: 'Email',
            value: _kSupportEmail,
            uri: 'mailto:$_kSupportEmail',
          ),
          const SizedBox(height: 8),
          const _LinkRow(
            label: 'Help + how-to',
            value: 'squishysmash.com/support',
            uri: _kSupportUrl,
          ),
          const SizedBox(height: 24),
          const _Section('Legal'),
          const _LinkRow(
            label: 'Privacy policy',
            value: 'squishysmash.com/privacy',
            uri: _kPrivacyUrl,
          ),
          const SizedBox(height: 8),
          const _LinkRow(
            label: 'Website',
            value: 'squishysmash.com',
            uri: _kWebsite,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 Squishy Smash',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Made with care for soft, silly, sparkly humans.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Palette.pink.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Palette.pink, width: 1.5),
          ),
          child: const Icon(
            Icons.cruelty_free,
            color: Palette.pink,
            size: 56,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Squishy Smash',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A soft, sparkly world',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Palette.cream,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row that reads like a plain row but renders the value as a
/// tappable cream link. Tapping copies the URL to the clipboard so
/// the player (or a parent) can paste it into Safari — we
/// deliberately do NOT use url_launcher here because the brief
/// requires no external-link handlers from gameplay (4+ rating).
/// Settings is the one allowed surface, but staying clipboard-only
/// keeps the rating risk at zero.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.uri,
  });

  final String label;
  final String value;
  final String uri;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Palette.cream,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
