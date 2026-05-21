import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:squishy_smash/ui/about_screen.dart';

/// Verifies Settings → About renders the app version read from the
/// real bundle (`package_info_plus` → `CFBundleShortVersionString`)
/// rather than a hardcoded literal that drifts from what shipped.
///
/// Pins: (a) the version row renders so users can self-report a
/// version, and (b) it shows the actual bundle version.
void main() {
  testWidgets('About screen renders the real bundle version', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Squishy Smash',
      packageName: 'com.example.squishysmash',
      version: '1.2.0',
      buildNumber: '31',
      buildSignature: '',
    );

    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('App version'), findsOneWidget,
        reason: 'the version row must render so users can self-report');
    expect(find.text('1.2.0'), findsOneWidget,
        reason: 'About must show the real bundle version, not a stale literal');
  });
}
