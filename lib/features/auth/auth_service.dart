import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this.auth);
  final FirebaseAuth auth;

  Stream<User?> get changes => auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.updateDisplayName(name.trim());
  }

  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() => auth.signOut();
}

String authError(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Não foi possível concluir. Tente novamente.';
  }
  return switch (error.code) {
    'invalid-email' => 'Digite um e-mail válido.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha incorretos.',
    'email-already-in-use' =>
      'Este e-mail já tem cadastro. Entre na sua conta.',
    'weak-password' => 'Use uma senha com pelo menos 8 caracteres.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde um pouco antes de tentar de novo.',
    'network-request-failed' =>
      'Sem conexão. Confira sua internet e tente novamente.',
    'operation-not-allowed' =>
      'O login por e-mail precisa ser ativado no Firebase.',
    'user-disabled' => 'Esta conta foi desativada.',
    _ => 'Não foi possível concluir. Tente novamente.',
  };
}
