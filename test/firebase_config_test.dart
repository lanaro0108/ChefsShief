import 'package:chefs_shelf/app/firebase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unset optional Firebase settings are absent from Android SDK options',
    () {
      final options = FirebaseConfig.options;
      expect(
        options.authDomain,
        isNull,
        reason:
            'Android Firebase Auth rejects an empty custom authentication domain.',
      );
      expect(options.asMap['authDomain'], isNull);
      expect(options.storageBucket, isNull);
    },
  );
}
