import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Deterministic source check for the iOS localization metadata.
///
/// Flutter app translations live in the ARB/gen-l10n layer; the Xcode
/// project only needs to ADVERTISE the four supported locales so iOS
/// picks the right Flutter bundle strings. This guards the canonical
/// structure Xcode creates via Runner → Info → Localizations:
/// `knownRegions` entries plus per-language `.strings` variant-group
/// children backed by real `*.lproj` resources on disk.
void main() {
  final pbxproj =
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  group('iOS localization metadata', () {
    test('knownRegions advertises all four app locales', () {
      for (final region in ['en', 'Base', 'ar', 'es', 'fr']) {
        expect(
          pbxproj,
          contains('\t\t\t\t$region,\n'),
          reason: 'knownRegions must list $region',
        );
      }
    });

    test('storyboard variant groups carry per-language .strings '
        'children that exist on disk', () {
      for (final locale in ['ar', 'es', 'fr']) {
        for (final storyboard in ['Main', 'LaunchScreen']) {
          final ref =
              'name = $locale; path = $locale.lproj/$storyboard.strings';
          expect(
            pbxproj,
            contains(ref),
            reason: 'PBXVariantGroup must reference $ref',
          );
          expect(
            File('ios/Runner/$locale.lproj/$storyboard.strings')
                .existsSync(),
            isTrue,
            reason:
                '$locale.lproj/$storyboard.strings must exist so the '
                'resource is actually bundled',
          );
        }
      }
    });

    test('Base.lproj storyboards remain the base localization', () {
      for (final storyboard in ['Main', 'LaunchScreen']) {
        expect(
          File('ios/Runner/Base.lproj/$storyboard.storyboard')
              .existsSync(),
          isTrue,
        );
      }
    });
  });

  group('iOS public brand metadata', () {
    test('Info.plist display names use the public brand', () {
      final plist =
          File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<string>PauseSignal</string>'));
      // The old working name must not remain as a display name.
      expect(plist, isNot(contains('<string>VoxGuard</string>')));
    });
  });
}
