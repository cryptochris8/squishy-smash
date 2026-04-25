import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/ui/widgets/card_album_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );

void main() {
  group('cardRarityColor', () {
    test('returns a distinct color for each rarity', () {
      final colors = Rarity.values.map(cardRarityColor).toSet();
      expect(colors.length, Rarity.values.length,
          reason: 'rarity colors must be unique');
    });

    test('common is the muted gray, mythic is the warm yellow', () {
      // Pin specific values so a brand refresh that changes one doesn't
      // silently swap pillars of the palette.
      expect(cardRarityColor(Rarity.common), const Color(0xFFB0B6C3));
      expect(cardRarityColor(Rarity.mythic), const Color(0xFFFFD36E));
    });
  });

  group('FilterPill', () {
    testWidgets('renders the label text', (tester) async {
      await tester.pumpWidget(_wrap(
        FilterPill(label: 'EPIC', selected: false, onTap: () {}),
      ));
      expect(find.text('EPIC'), findsOneWidget);
    });

    testWidgets('selected state shows the tint color on the label',
        (tester) async {
      const tint = Color(0xFFC98BFF);
      await tester.pumpWidget(_wrap(
        FilterPill(
          label: 'X',
          selected: true,
          onTap: () {},
          tint: tint,
        ),
      ));
      final text = tester.widget<Text>(find.text('X'));
      expect(text.style?.color, tint);
    });

    testWidgets('unselected state uses muted white', (tester) async {
      await tester.pumpWidget(_wrap(
        FilterPill(label: 'X', selected: false, onTap: () {}),
      ));
      final text = tester.widget<Text>(find.text('X'));
      expect(text.style?.color, isNot(const Color(0xFFFFD36E)),
          reason: 'unselected pill should not use the active tint');
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(
        FilterPill(label: 'X', selected: false, onTap: () => tapped++),
      ));
      await tester.tap(find.text('X'));
      expect(tapped, 1);
    });
  });

  group('RarityPill', () {
    testWidgets('renders the rarity display label uppercased',
        (tester) async {
      await tester.pumpWidget(_wrap(const RarityPill(rarity: Rarity.epic)));
      expect(find.text('EPIC'), findsOneWidget);
    });

    testWidgets('Mythic pill shows "LEGENDARY" (player-facing label)',
        (tester) async {
      // Pins the rarity terminology contract: internal enum is mythic,
      // player-facing copy is "Legendary". The pill must use the
      // displayLabel, not the token.
      await tester.pumpWidget(_wrap(
        const RarityPill(rarity: Rarity.mythic),
      ));
      expect(find.text('LEGENDARY'), findsOneWidget);
      expect(find.text('MYTHIC'), findsNothing);
    });
  });

  group('BurstProgressBar', () {
    testWidgets('shows "BURSTS X / Y" header text', (tester) async {
      await tester.pumpWidget(_wrap(
        const BurstProgressBar(bursts: 4, required: 7),
      ));
      expect(find.text('BURSTS  4 / 7'), findsOneWidget);
    });

    testWidgets('progress bar value matches bursts/required ratio',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const BurstProgressBar(bursts: 3, required: 6),
      ));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.5);
    });

    testWidgets('progress clamps at 1.0 when bursts exceed required',
        (tester) async {
      // Defends against display glitches if a card was unlocked via
      // burst and the player keeps bursting it.
      await tester.pumpWidget(_wrap(
        const BurstProgressBar(bursts: 99, required: 1),
      ));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
    });

    testWidgets('progress is 0.0 when bursts is 0', (tester) async {
      await tester.pumpWidget(_wrap(
        const BurstProgressBar(bursts: 0, required: 7),
      ));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.0);
    });

    testWidgets('safely handles required=0 without divide-by-zero',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const BurstProgressBar(bursts: 5, required: 0),
      ));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0,
          reason: 'required=0 means there is no threshold to grind — '
              'show the bar as full rather than NaN');
    });
  });
}
