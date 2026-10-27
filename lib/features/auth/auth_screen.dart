import 'package:flutter/material.dart';
import '../../app/firebase_config.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.service});
  final AuthService service;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.service.register(_name.text, _email.text, _password.text);
      } else {
        await widget.service.signIn(_email.text, _password.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Preencha seu e-mail para recuperar a senha.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.resetPassword(_email.text);
      if (mounted) {
        showMessage(
          context,
          'Se existir uma conta com esse e-mail, você receberá as instruções.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final form = Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Brand(),
                      if (FirebaseConfig.useEmulators) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Ambiente local · Contas e receitas de teste',
                          style: TextStyle(
                            fontSize: 12,
                            color: ShelfColors.darkRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      Text(
                        _register
                            ? 'Sua próxima receita\ncomeça aqui.'
                            : 'Bom ter você\nà mesa de novo.',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _register
                            ? 'Crie sua conta e dê um lugar às suas receitas favoritas.'
                            : 'Entre para abrir seu caderno de receitas.',
                        style: const TextStyle(
                          color: ShelfColors.muted,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          maxLength: 60,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Como podemos chamar você?'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        key: const Key('auth-email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v?.trim() ?? '')
                            ? null
                            : 'Digite um e-mail válido.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('auth-password'),
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: _register
                              ? 'Pelo menos 8 caracteres.'
                              : null,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v?.length ?? 0) < (_register ? 8 : 1)
                            ? 'Digite ${_register ? 'pelo menos 8 caracteres' : 'sua senha'}.'
                            : null,
                      ),
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _busy ? null : _reset,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _register
                                    ? 'Criar minha conta'
                                    : 'Entrar no meu caderno',
                              ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _error = null;
                                _form.currentState?.reset();
                              }),
                        child: Text(
                          _register
                              ? 'Já tenho uma conta · Entrar'
                              : 'Primeira vez aqui? Crie sua conta',
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Feito para quem acredita que boas receitas\nmerecem ser guardadas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ShelfColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        return Row(
          children: [
            Expanded(child: form),
            if (wide)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ShelfColors.olive, ShelfColors.ink],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: const RecipeImage(
                          url: 'https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg',
                          height: 220,
                        ),
                      ),
                      const SizedBox(height: 38),
                      const Text(
                        'Um mundo de sabores.\nUm caderno só seu.',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lora',
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Descubra, experimente e guarde.\nSua história na cozinha começa com uma receita.',
                        style: TextStyle(
                          color: ShelfColors.white,
                          fontSize: 18,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 44),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            [
                                  'Receitas do mundo',
                                  'Seu toque pessoal',
                                  'Sempre com você',
                                ]
                                .map(
                                  (text) => Chip(
                                    color: const WidgetStatePropertyAll(
                                      ShelfColors.darkRed,
                                    ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: .1,
                                    ),
                                    side: BorderSide.none,
                                    label: Text(
                                      text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
