import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app/app.dart';
import 'app/firebase_config.dart';
import 'features/auth/auth_service.dart';
import 'features/recipes/data/meal_api.dart';
import 'features/recipes/data/notebook_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!FirebaseConfig.configured) {
    runApp(const SetupApp());
    return;
  }
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.options,
    ).timeout(const Duration(seconds: 25));
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    if (FirebaseConfig.useEmulators) {
      await auth.useAuthEmulator(FirebaseConfig.emulatorHost, 9099);
      firestore.useFirestoreEmulator(FirebaseConfig.emulatorHost, 8080);
      firestore.settings = const Settings(persistenceEnabled: false);
    }
    runApp(
      ChefsShelfApp(
        auth: AuthService(auth),
        api: MealApi(http.Client()),
        notebook: FirestoreNotebookRepository(firestore),
      ),
    );
  } catch (_) {
    runApp(const SetupApp(initializationFailed: true));
  }
}
