import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Bundled Fredoka font', () {
    test('TTF asset exists on disk', () {
      final f = File('assets/google_fonts/Fredoka.ttf');
      expect(f.existsSync(), isTrue,
          reason: 'Fredoka.ttf must be checked in — without it, the '
              'pubspec entry resolves to nothing and the app silently '
              'falls back to a system font on first launch');
    });

    test('TTF starts with the OpenType magic number', () {
      // 0x00 0x01 0x00 0x00 = TrueType outlines (the canonical TTF
      // magic). A wrong-format file (e.g., a 404 HTML page mistakenly
      // saved as .ttf) would fail to load on device and the user
      // would only notice via the wrong font appearing.
      final bytes = File('assets/google_fonts/Fredoka.ttf')
          .readAsBytesSync()
          .take(4)
          .toList();
      expect(bytes, [0x00, 0x01, 0x00, 0x00]);
    });

    test('TTF is the variable-font size — single file covers all weights',
        () {
      // Variable Fredoka (~150-180 KB) bundles every weight axis the
      // UI uses (300/400/500/600/700) into one file. A static-instance
      // file would be ~70 KB and only one weight; pinning a floor
      // catches accidental swaps to a single-weight build.
      final size = File('assets/google_fonts/Fredoka.ttf').lengthSync();
      expect(size, greaterThan(100 * 1024),
          reason: 'TTF too small ($size bytes) — likely a single-weight '
              'static instance instead of the variable font');
    });

    test('OFL license is bundled alongside the font', () {
      // SIL OFL 1.1 requires the license travel with the font in any
      // distribution. Shipping the TTF without OFL.txt is a license
      // violation.
      final license = File('assets/google_fonts/OFL.txt');
      expect(license.existsSync(), isTrue,
          reason: 'OFL.txt is required by the SIL Open Font License '
              'whenever the font binary is redistributed');
      final body = license.readAsStringSync();
      expect(body, contains('SIL Open Font License'));
    });

    test('pubspec.yaml registers the Fredoka family pointing at the TTF',
        () {
      // Ties the asset on disk to the Flutter font resolver. Without
      // this entry, Flutter never finds the bundled file and silently
      // falls back to a system font.
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      final fonts = pubspec['flutter']['fonts'] as YamlList;
      final fredoka = fonts.firstWhere(
        (entry) => entry['family'] == 'Fredoka',
        orElse: () => null,
      );
      expect(fredoka, isNotNull,
          reason: 'pubspec.yaml is missing a `flutter > fonts` entry '
              'with family: Fredoka');
      final fredokaFonts = fredoka['fonts'] as YamlList;
      expect(fredokaFonts, hasLength(greaterThanOrEqualTo(1)));
      final assetPath = fredokaFonts.first['asset'] as String;
      expect(assetPath, 'assets/google_fonts/Fredoka.ttf');
      expect(File(assetPath).existsSync(), isTrue);
    });

    test('google_fonts package is no longer a runtime dependency', () {
      // Removing the package eliminates the latent runtime-fetch risk:
      // even if a future contributor accidentally writes
      // GoogleFonts.someFamily(...), it won't compile.
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      final deps = pubspec['dependencies'] as YamlMap;
      expect(deps.containsKey('google_fonts'), isFalse,
          reason: 'google_fonts dropped — bundled Fredoka covers the '
              'one font we used. If you re-add it, also re-add a '
              'runtime-fetching guard.');
    });
  });
}
