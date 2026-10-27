import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseConfig {
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static bool get configured =>
      useEmulators ||
      [projectId, apiKey, appId, senderId].every((value) => value.isNotEmpty);

  static FirebaseOptions get options => useEmulators
      ? const FirebaseOptions(
          apiKey: 'demo-key-for-emulators-only',
          appId: '1:123456789:web:chefs-shelf-demo',
          messagingSenderId: '123456789',
          projectId: 'demo-chefs-shelf',
          authDomain: 'demo-chefs-shelf.firebaseapp.com',
        )
      : const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
          authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
          storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        );
}
