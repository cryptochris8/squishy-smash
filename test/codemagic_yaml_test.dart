import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Pins the Codemagic config contract: pinned versions, signed IPA
/// step carries the Sentry DSN, and the variable group is referenced.
///
/// Why a test for a CI YAML? Because the file is a build-output
/// contract, not source code — analyzers won't catch a refactor that
/// silently drops the `--dart-define=SENTRY_DSN=...` flag. Without it,
/// the IPA still builds and ships, but Sentry is dark in production
/// and you only find out from one-star reviews. This test fires
/// immediately if anyone breaks the wiring.
void main() {
  late final YamlMap yaml;
  setUpAll(() {
    yaml = loadYaml(File('codemagic.yaml').readAsStringSync()) as YamlMap;
  });

  YamlMap workflow(String name) =>
      (yaml['workflows'] as YamlMap)[name] as YamlMap;

  Map<String, String> stepScripts(YamlMap wf) {
    final scripts = wf['scripts'] as YamlList;
    return {
      for (final s in scripts)
        (s['name'] as String): (s['script'] as String),
    };
  }

  group('codemagic.yaml — pinned tool versions', () {
    test('ios-debug pins flutter / xcode / cocoapods (no auto-tracking)', () {
      final env = workflow('ios-debug')['environment'] as YamlMap;
      expect(env['flutter'], isNot(equals('stable')),
          reason: 'pin a specific Flutter version — letting it track '
              '`stable` lets a silent upstream change break the build');
      expect(env['xcode'], isNot(equals('latest')));
      expect(env['cocoapods'], isNot(equals('default')));
    });

    test('ios-release pins the same way', () {
      final env = workflow('ios-release')['environment'] as YamlMap;
      expect(env['flutter'], isNot(equals('stable')));
      expect(env['xcode'], isNot(equals('latest')));
      expect(env['cocoapods'], isNot(equals('default')));
    });
  });

  group('codemagic.yaml — Sentry DSN wiring', () {
    test('ios-release references the `smash` variable group', () {
      // The `smash` variable group is where SENTRY_DSN (and other
      // secrets) live in the Codemagic dashboard. Drop the reference
      // and `$SENTRY_DSN` resolves to empty in the build script.
      final env = workflow('ios-release')['environment'] as YamlMap;
      final groups = env['groups'] as YamlList;
      expect(groups.toList(), contains('smash'));
    });

    test('signed-IPA step passes --dart-define=SENTRY_DSN', () {
      // Without this flag, Sentry init in main.dart sees an empty DSN
      // and falls through — the shipped IPA has crash reporting OFF.
      // Pin the flag's presence so a future refactor can't silently
      // drop it.
      final scripts = stepScripts(workflow('ios-release'));
      final ipaStep = scripts['Flutter build ipa (signed)'];
      expect(ipaStep, isNotNull,
          reason: 'expected a "Flutter build ipa (signed)" step');
      expect(ipaStep, contains('--dart-define=SENTRY_DSN='),
          reason: 'release IPA must forward SENTRY_DSN at build time');
      expect(ipaStep, contains(r'$SENTRY_DSN'),
          reason: 'value must come from the env var, not be inlined');
    });

    test('ios-debug does NOT pass SENTRY_DSN (dev + tests stay quiet)',
        () {
      // The unsigned debug workflow runs analyze + tests + an
      // unsigned build. We don't want any of those pinging Sentry —
      // they'd pollute the dashboard with non-user errors.
      final scripts = stepScripts(workflow('ios-debug'));
      for (final body in scripts.values) {
        expect(body, isNot(contains('SENTRY_DSN')),
            reason: 'ios-debug must not forward SENTRY_DSN — keep '
                'CI-side analyze/test runs out of the live dashboard');
      }
    });
  });
}
