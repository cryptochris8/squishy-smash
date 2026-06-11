import 'dart:convert';
import 'dart:io';
import 'dart:ui' show instantiateImageCodec;

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/content_loader.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';

/// Every mythic-tier smashable with a card mapping must ship its
/// pre-rendered squish sheet (SmashableComponent loads
/// `anim/card_NNN_squish.webp` for the 3D squash cycle). The sheet
/// contract is fixed: 13 horizontal cells (see
/// tools/render3d/pack_squish_sheet.py and
/// SmashableComponent._squishFrameCount).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mythicCards = <String, String>{}; // sheet path -> owning object id
  for (final path in ContentLoader.bundledPackPaths) {
    final map =
        json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final pack = ContentPack.fromJson(map);
    for (final obj in pack.objects) {
      final cardNumber = obj.cardNumber;
      if (obj.rarity != Rarity.mythic || cardNumber == null) continue;
      final n = int.parse(cardNumber.split('/').first);
      final sheet =
          'assets/images/anim/card_${n.toString().padLeft(3, '0')}_squish.webp';
      mythicCards[sheet] = obj.id;
    }
  }

  test('found the mythic launch smashables with card mappings', () {
    // The three launch packs each crown one Legendary (cards 016/032/048).
    expect(mythicCards.length, greaterThanOrEqualTo(3),
        reason: 'expected at least the 3 launch-pack Legendaries');
  });

  group('squish sheets ship for mythic smashables', () {
    for (final entry in mythicCards.entries) {
      test('${entry.value} -> ${entry.key}', () async {
        final file = File(entry.key);
        expect(file.existsSync(), isTrue,
            reason: 'missing squish sheet for ${entry.value}');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(50 * 1024),
            reason: 'suspiciously small sheet (broken export?)');
        final codec = await instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width % 13, 0,
            reason: 'sheet width must be 13 equal cells');
        expect(frame.image.height, 320,
            reason: 'cell height contract is 320 px');
      });
    }
  });
}
