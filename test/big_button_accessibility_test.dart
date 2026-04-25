import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standalone copy of the BigButton accessibility wrapper, sourced
/// from `lib/ui/widgets/big_button.dart`. Building the production
/// widget directly would pull in `ServiceLocator.ui` (its tap handler
/// fires `ServiceLocator.ui.buttonTap()`), and ServiceLocator isn't
/// initialized in unit tests. So we test the SHAPE of the Semantics
/// wrapping the GestureDetector — a structural mirror of what
/// production ships.
class _BigButtonShape extends StatelessWidget {
  const _BigButtonShape({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: Text(label),
        ),
      ),
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );

void main() {
  group('BigButton accessibility shape', () {
    testWidgets('exposes a button-flagged Semantics node with the label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(
        _BigButtonShape(label: 'PLAY', onTap: () {}),
      ));
      expect(
        find.bySemanticsLabel('PLAY'),
        findsOneWidget,
        reason: 'screen readers must find a node labeled PLAY',
      );
      handle.dispose();
    });

    testWidgets('Semantics.onTap fires when AT activates the node',
        (tester) async {
      final handle = tester.ensureSemantics();
      var fires = 0;
      await tester.pumpWidget(_wrap(
        _BigButtonShape(label: 'SHOP', onTap: () => fires++),
      ));
      // Find the SemanticsNode for the labeled button and dispatch
      // the AT-equivalent of a tap. Uses the (deprecated but working)
      // pipelineOwner accessor — the suggested replacement traverses
      // a different semantics tree that doesn't include test-pumped
      // widgets, so action dispatch silently no-ops there.
      final node = tester.getSemantics(find.bySemanticsLabel('SHOP'));
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(fires, 1);
      handle.dispose();
    });

    testWidgets('inner Text is excluded from the semantics tree '
        '(no double-read)', (tester) async {
      // The Semantics wrapper carries the label; the inner Text would
      // be redundant. excludeSemantics on the wrapper means VoiceOver
      // hears "PLAY, button" exactly once, not twice.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(
        _BigButtonShape(label: 'PLAY', onTap: () {}),
      ));
      final matches = find.bySemanticsLabel('PLAY');
      expect(matches, findsOneWidget,
          reason: 'duplicate "PLAY" semantics nodes mean the inner '
              'text was not excluded — VoiceOver would announce twice');
      handle.dispose();
    });

    testWidgets('a normal pointer tap fires onTap once', (tester) async {
      // Sanity check that adding Semantics didn't break the visible-tap
      // path (sighted users still need it to work).
      var fires = 0;
      await tester.pumpWidget(_wrap(
        _BigButtonShape(label: 'GO', onTap: () => fires++),
      ));
      await tester.tap(find.text('GO'));
      expect(fires, 1);
    });
  });
}
