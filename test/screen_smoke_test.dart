import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/core/service_locator.dart';
import 'package:squishy_smash/ui/collection_screen.dart';
import 'package:squishy_smash/ui/gameplay_screen.dart';
import 'package:squishy_smash/ui/shop_screen.dart';

/// P1.21 from PRELAUNCH_AUDIT.md — widget smoke tests for the main
/// screens an App Store reviewer hits first. Each test only asserts
/// the screen builds and lays out one frame without throwing; a crash
/// on the build path is exactly the regression these guard against.
///
/// The screens read `ServiceLocator` directly, so the suite boots a
/// real (asset-backed, mock-prefs) ServiceLocator once for the file.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ServiceLocator.bootstrap();
  });

  testWidgets('ShopScreen builds without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ShopScreen), findsOneWidget);
  });

  testWidgets('CollectionScreen builds without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CollectionScreen), findsOneWidget);
  });

  testWidgets('GameplayScreen builds without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameplayScreen()));
    // A couple of frames to let the embedded Flame GameWidget begin
    // its async onLoad; a smoke test only needs no synchronous throw.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.byType(GameplayScreen), findsOneWidget);
  });
}
