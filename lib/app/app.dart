import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/widgets.dart';
import '../core/kitchen_backdrop.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/auth_service.dart';
import '../features/recipes/data/meal_api.dart';
import '../features/recipes/data/notebook_repository.dart';
import '../features/recipes/presentation/home_screen.dart';
import 'firebase_config.dart';
import 'theme.dart';

class ChefsShelfApp extends StatelessWidget {
  const ChefsShelfApp({
    super.key,
    required this.auth,
    required this.api,
    required this.notebook,
  });
  final AuthService auth;
  final MealApi api;
  final NotebookRepository notebook;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.changes,
    builder: (context, snapshot) => MaterialApp(
      // A different account gets a new Navigator, disposing all private routes.
      key: ValueKey(snapshot.data?.uid),
      title: 'Chef’s Shelf · Seu caderno de receitas',
      debugShowCheckedModeBanner: false,
      theme: shelfTheme(),
      builder: (context, child) =>
          KitchenBackdrop(child: child ?? const SizedBox.shrink()),
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      home: Builder(
        builder: (context) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: StatusPanel(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível conectar',
                message: 'Confira a conexão e reabra o aplicativo.',
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          return user == null
              ? AuthScreen(service: auth)
              : HomeScreen(
                  key: ValueKey(user.uid),
                  user: user,
                  auth: auth,
                  api: api,
                  notebook: notebook,
                );
        },
      ),
    ),
  );
}

class SetupApp extends StatelessWidget {
  const SetupApp({super.key, this.initializationFailed = false});
  final bool initializationFailed;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: shelfTheme(),
    builder: (context, child) =>
        KitchenBackdrop(child: child ?? const SizedBox.shrink()),
    home: Scaffold(
      body: StatusPanel(
        icon: Icons.restaurant_menu,
        title: initializationFailed
            ? 'Não foi possível iniciar o Firebase'
            : 'Vamos preparar a cozinha?',
        message: initializationFailed
            ? 'Confira a configuração Firebase e a conexão. Se estiver em modo local, inicie os emuladores. Consulte o README do projeto.'
            : 'Os dados do Firebase não foram recebidos na inicialização. '
                  'Para Android, preencha config/firebase.android.json e execute:\n\n'
                  'flutter run --dart-define-from-file=config/firebase.android.json\n\n'
                  'No Android Studio, adicione essa opção em Additional run args. '
                  'Encerre a execução atual antes de iniciar novamente.',
      ),
    ),
  );
}

class EmulatorNotice extends StatelessWidget {
  const EmulatorNotice({super.key});
  @override
  Widget build(BuildContext context) => FirebaseConfig.useEmulators
      ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          color: ShelfColors.subtle,
          child: const Text(
            'Ambiente local · Contas e receitas de teste',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ShelfColors.ink),
          ),
        )
      : const SizedBox.shrink();
}
