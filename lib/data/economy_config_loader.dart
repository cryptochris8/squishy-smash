import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/service_locator.dart';
import 'content_loader.dart' show AssetReader;
import 'models/economy_config.dart';

/// Bundle path for the economy config JSON. Single source of truth —
/// editing this file flips every dependent value (thresholds, prices,
/// dupe bonuses, anti-spam, milestones).
const String kEconomyConfigPath = 'assets/data/economy.json';

/// Schema version the loader knows how to parse. Bump in lockstep
/// with `assets/data/economy.json`'s top-level schemaVersion when
/// adding a field that older readers can't safely default.
const int kEconomyConfigSchemaVersion = 1;

class EconomyConfigLoader {
  /// Read the bundled economy config. Falls back to the const-default
  /// `EconomyConfig()` if the file is missing, malformed, or carries
  /// a future schemaVersion — the app boots either way, just without
  /// any rebalance applied.
  Future<EconomyConfig> load({AssetReader? readAsset}) async {
    final read = readAsset ?? rootBundle.loadString;
    try {
      final raw = await read(kEconomyConfigPath);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _assertSchemaVersion(map);
      return EconomyConfig.fromJson(map);
    } catch (e, st) {
      // P1.23: route to diagnostics so Sentry sees a broken
      // economy.json. Fallback to defaults still happens — we just
      // also notify so we know the live config wasn't applied.
      ServiceLocator.diagnostics.record(
        source: 'economy_config',
        error: 'load failed; falling back to defaults: $e',
        stack: st,
      );
      return const EconomyConfig();
    }
  }

  void _assertSchemaVersion(Map<String, dynamic> map) {
    final raw = map['schemaVersion'];
    if (raw == null) return; // missing → assume current
    final v = (raw as num).toInt();
    if (v > kEconomyConfigSchemaVersion) {
      throw StateError(
        '$kEconomyConfigPath schemaVersion=$v is newer than supported '
        '($kEconomyConfigSchemaVersion). Update the app to load this '
        'config.',
      );
    }
  }
}
