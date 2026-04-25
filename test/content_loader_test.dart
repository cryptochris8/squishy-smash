import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/content_loader.dart';

/// Minimal valid pack JSON — just enough that `ContentPack.fromJson`
/// succeeds. The loader doesn't care about object physics; it cares
/// about top-level shape + schemaVersion.
String _minimalPackJson({
  required String packId,
  int? schemaVersion = 1,
}) {
  final map = <String, dynamic>{
    if (schemaVersion != null) 'schemaVersion': schemaVersion,
    'packId': packId,
    'displayName': packId,
    'themeTag': 'test',
    'releaseType': 'launch',
    'palette': {
      'primary': '#FF8FB8',
      'secondary': '#FFD36E',
      'accent': '#7FE7FF',
    },
    'arenaSuggestion': 'any',
    'featuredAudioSet': 'any',
    'unlockCost': 0,
    'objects': <Map<String, dynamic>>[],
  };
  return jsonEncode(map);
}

String _minimalScheduleJson({int? schemaVersion = 1}) {
  final map = <String, dynamic>{
    if (schemaVersion != null) 'schemaVersion': schemaVersion,
    'featuredRotation': <Map<String, dynamic>>[],
  };
  return jsonEncode(map);
}

/// Closure-based fake asset reader. Tests register a path -> body
/// mapping (or a path -> error) and pass `fake.read` to `loadAll`.
class _FakeAssets {
  final Map<String, String> _bodies = {};
  final Map<String, Object> _errors = {};

  void put(String path, String body) {
    _bodies[path] = body;
  }

  void fail(String path, Object error) {
    _errors[path] = error;
  }

  Future<String> read(String path) async {
    if (_errors.containsKey(path)) throw _errors[path]!;
    if (_bodies.containsKey(path)) return _bodies[path]!;
    throw StateError('No fake asset registered for $path');
  }
}

void main() {
  group('ContentLoader.loadAll resilience', () {
    test('loads every pack when all paths return valid v1 JSON', () async {
      final fake = _FakeAssets();
      for (final path in ContentLoader.bundledPackPaths) {
        // Use the path's filename as the packId so each is unique.
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      expect(result.packs, hasLength(ContentLoader.bundledPackPaths.length));
      expect(result.schedule.featuredRotation, isEmpty);
    });

    test('skips a pack with malformed JSON without crashing the load',
        () async {
      final fake = _FakeAssets();
      // First path: malformed.
      fake.put(ContentLoader.bundledPackPaths.first, '{ not valid json');
      // Remaining paths: valid.
      for (final path in ContentLoader.bundledPackPaths.skip(1)) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      // The bad pack is silently skipped; the good ones still load.
      expect(result.packs,
          hasLength(ContentLoader.bundledPackPaths.length - 1));
    });

    test('skips a pack whose asset read throws (e.g., file not found)',
        () async {
      final fake = _FakeAssets();
      // First path: simulate missing asset.
      fake.fail(ContentLoader.bundledPackPaths.first,
          StateError('asset missing'));
      for (final path in ContentLoader.bundledPackPaths.skip(1)) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      expect(result.packs,
          hasLength(ContentLoader.bundledPackPaths.length - 1));
    });

    test('rejects a pack with a future schemaVersion (skips, no crash)',
        () async {
      final fake = _FakeAssets();
      // First pack has schemaVersion=999 — newer than supported.
      fake.put(
        ContentLoader.bundledPackPaths.first,
        _minimalPackJson(packId: 'too_new', schemaVersion: 999),
      );
      for (final path in ContentLoader.bundledPackPaths.skip(1)) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      // Future-versioned pack is skipped with a debugPrint.
      expect(result.packs,
          hasLength(ContentLoader.bundledPackPaths.length - 1));
      expect(
        result.packs.any((p) => p.packId == 'too_new'),
        isFalse,
        reason: 'future-versioned packs must not be loaded',
      );
    });

    test('accepts a pack with no schemaVersion (treated as current)',
        () async {
      // Backward compat with pre-versioning content. A missing field
      // is treated as `contentSchemaVersion`, not as a failure.
      final fake = _FakeAssets();
      fake.put(
        ContentLoader.bundledPackPaths.first,
        _minimalPackJson(packId: 'legacy', schemaVersion: null),
      );
      for (final path in ContentLoader.bundledPackPaths.skip(1)) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      expect(result.packs,
          hasLength(ContentLoader.bundledPackPaths.length));
      expect(result.packs.any((p) => p.packId == 'legacy'), isTrue);
    });

    test('returns empty schedule when schedule asset fails to load',
        () async {
      final fake = _FakeAssets();
      for (final path in ContentLoader.bundledPackPaths) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.fail(ContentLoader.schedulePath, StateError('schedule missing'));

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      // Packs still load; schedule degrades to an empty rotation.
      expect(result.packs,
          hasLength(ContentLoader.bundledPackPaths.length));
      expect(result.schedule.featuredRotation, isEmpty);
    });

    test('returns empty schedule when schedule has a future schemaVersion',
        () async {
      final fake = _FakeAssets();
      for (final path in ContentLoader.bundledPackPaths) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath,
          _minimalScheduleJson(schemaVersion: 999));

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      expect(result.schedule.featuredRotation, isEmpty);
    });

    test('contentSchemaVersion is at least 2 (cardNumber link shipped)', () {
      // Pin the schema version. v2 added optional `cardNumber` to
      // smashables. Future bumps should add migration handling and
      // update this floor.
      expect(contentSchemaVersion, greaterThanOrEqualTo(2));
    });

    test('packs declaring schemaVersion 1 still load (additive v2)',
        () async {
      // The v1 → v2 change was purely additive (optional cardNumber
      // field). v1 packs with no cardNumber must continue to load.
      final fake = _FakeAssets();
      fake.put(
        ContentLoader.bundledPackPaths.first,
        _minimalPackJson(packId: 'legacy_v1', schemaVersion: 1),
      );
      for (final path in ContentLoader.bundledPackPaths.skip(1)) {
        final id = path.split('/').last.replaceAll('.json', '');
        fake.put(path, _minimalPackJson(packId: id));
      }
      fake.put(ContentLoader.schedulePath, _minimalScheduleJson());

      final result = await ContentLoader().loadAll(readAsset: fake.read);
      expect(result.packs.any((p) => p.packId == 'legacy_v1'), isTrue);
    });
  });
}
