import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GAME_POLISH_AUDIT.md UX-4 — verifies the empty-album hint banner
/// is wired into the production widget. We can't render the full
/// CollectionScreen in a unit test without bootstrapping the
/// ServiceLocator (out of scope for this slice), so this is a
/// structural test: read the production source, assert the hint
/// copy + PLAY CTA wiring are present, catch any accidental delete
/// or rename.
void main() {
  // Pulled out as constants so a deliberate copy edit fails with a
  // single explicit assertion rather than a confusing tree mismatch.
  const kHintCopy = 'Tap PLAY to start smashing.';
  const kSubCopy = 'Cards unlock as you burst squishies.';

  test('empty-album banner copy stays present in the production widget',
      () async {
    final source =
        await File('lib/ui/collection_screen.dart').readAsString();
    expect(source.contains(kHintCopy), isTrue,
        reason: 'UX-4 hint must remain in collection_screen.dart');
    expect(source.contains(kSubCopy), isTrue,
        reason: 'sub-copy explains the 3-path unlock loop to new players');
    expect(source.contains("label: 'PLAY'"), isTrue,
        reason: 'PLAY CTA label must remain on the banner');
    // Visibility gate: banner must be gated on unlockedTotal == 0
    // so returning players don't see it.
    expect(source.contains('unlockedTotal == 0'), isTrue,
        reason: 'banner must only render when no cards are unlocked');
  });
}
