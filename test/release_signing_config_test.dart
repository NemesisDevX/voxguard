import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Configuration regression coverage for the Android release-signing
/// contract: key.properties keys stay standard, the VOXGUARD_*
/// environment fallback stays explicit, and the fail-loud release
/// guard is present.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('key.properties keys remain the standard AGP names', () {
    for (final key in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword',
    ]) {
      expect(gradle, contains('"$key"'));
    }
  });

  test('explicit VOXGUARD_* environment fallback is wired', () {
    for (final env in [
      'VOXGUARD_KEYSTORE_FILE',
      'VOXGUARD_KEYSTORE_PASSWORD',
      'VOXGUARD_KEY_ALIAS',
      'VOXGUARD_KEY_PASSWORD',
    ]) {
      expect(gradle, contains('"$env"'));
    }
  });

  test('release without credentials fails loudly', () {
    expect(gradle, contains('BLOCKED_EXTERNAL'));
    expect(gradle, contains('releaseSigningReady'));
  });
}
