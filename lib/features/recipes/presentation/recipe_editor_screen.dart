import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../data/notebook_repository.dart';
import '../domain/recipe.dart';

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({
    super.key,
    required this.recipe,
    required this.uid,
    required this.notebook,
  });
  final Recipe recipe;
  final String uid;
  final NotebookRepository notebook;
  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final List<TextEditingController> _ingredients;
  late final List<TextEditingController> _steps;
  final _retired = <TextEditingController>[];
  bool _dirty = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.recipe.title);
    _notes = TextEditingController(text: widget.recipe.notes);
    _ingredients = widget.recipe.ingredients
        .map((s) => TextEditingController(text: s))
        .toList();
    _steps = widget.recipe.instructions
        .map((s) => TextEditingController(text: s))
        .toList();
  }

  @override
  void dispose() {
    for (final c in [_title, _notes, ..._ingredients, ..._steps, ..._retired]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    if (_busy) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar suas alterações?'),
        content: const Text('As edições ainda não foram salvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final recipe = widget.recipe.edited(
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      ingredients: _ingredients.map((c) => c.text.trim()).toList(),
      instructions: _steps.map((c) => c.text.trim()).toList(),
    );
    final error = recipe.validationError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.notebook.update(widget.uid, recipe);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível salvar. Confira a conexão. Se a receita foi removida em outro dispositivo, volte ao caderno.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Seu toque pessoal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _form,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Toda receita pode\nficar mais sua.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Adapte os ingredientes, ajuste os passos e guarde suas descobertas.',
                    style: TextStyle(color: ShelfColors.muted),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    key: const Key('edit-title'),
                    controller: _title,
                    enabled: !_busy,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Nome da receita',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Dê um nome para a receita.'
                        : null,
                  ),
                  const SizedBox(height: 26),
                  _listFields(
                    'Ingredientes',
                    _ingredients,
                    maxLength: 300,
                    multiline: false,
                  ),
                  const SizedBox(height: 26),
                  _listFields(
                    'Modo de preparo',
                    _steps,
                    maxLength: 5000,
                    multiline: true,
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    key: const Key('edit-notes'),
                    controller: _notes,
                    enabled: !_busy,
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Minhas observações',
                      hintText: 'O que deixou essa receita especial?',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('edit-save'),
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Salvar minhas alterações'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _listFields(
    String label,
    List<TextEditingController> fields, {
    required int maxLength,
    required bool multiline,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      ...fields.asMap().entries.map(
        (entry) => Padding(
          key: ObjectKey(entry.value),
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.value,
                  enabled: !_busy,
                  minLines: multiline ? 2 : 1,
                  maxLines: multiline ? 8 : 3,
                  maxLength: maxLength,
                  decoration: InputDecoration(
                    labelText:
                        '${multiline ? 'Passo' : 'Ingrediente'} ${entry.key + 1}',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Preencha este campo ou remova a linha.'
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip:
                    'Remover ${multiline ? 'passo' : 'ingrediente'} ${entry.key + 1}',
                onPressed: _busy || fields.length <= 1
                    ? null
                    : () => setState(() {
                        _retired.add(fields.removeAt(entry.key));
                        _dirty = true;
                      }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _busy || fields.length >= 40
              ? null
              : () => setState(() {
                  fields.add(TextEditingController());
                  _dirty = true;
                }),
          icon: const Icon(Icons.add, size: 18),
          label: Text(multiline ? 'Adicionar passo' : 'Adicionar ingrediente'),
        ),
      ),
    ],
  );
}
