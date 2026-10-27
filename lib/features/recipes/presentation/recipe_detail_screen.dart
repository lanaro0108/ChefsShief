import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets.dart';
import '../data/notebook_repository.dart';
import '../domain/recipe.dart';
import 'recipe_editor_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.initial,
    required this.initiallySaved,
    required this.uid,
    required this.notebook,
  });
  final Recipe initial;
  final bool initiallySaved;
  final String uid;
  final NotebookRepository notebook;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final Stream<List<Recipe>> _stream;
  final _checked = <int>{};
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _stream = widget.notebook.watchAll(widget.uid);
  }

  Future<void> _save(Recipe recipe) async {
    setState(() => _busy = true);
    try {
      final created = await widget.notebook.save(widget.uid, recipe);
      if (mounted) {
        showMessage(
          context,
          created
              ? 'Receita salva! Agora você pode dar seu toque pessoal.'
              : 'Esta receita já está no seu caderno.',
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Não foi possível salvar. Confira a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover do caderno?'),
        content: Text(
          '“${recipe.title}” será removida, incluindo suas edições e observações. Você poderá salvar a receita original novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter receita'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover receita'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.notebook.delete(widget.uid, recipe.id);
      if (mounted) {
        showMessage(context, 'Receita removida do seu caderno.');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Não foi possível remover. Confira a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Recipe recipe) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecipeEditorScreen(
          recipe: recipe,
          uid: widget.uid,
          notebook: widget.notebook,
        ),
      ),
    );
    if (updated == true && mounted) {
      setState(_checked.clear);
      showMessage(context, 'Seu toque foi salvo na receita.');
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Recipe>>(
    stream: _stream,
    builder: (context, snapshot) {
      Recipe? stored;
      for (final recipe in snapshot.data ?? <Recipe>[]) {
        if (recipe.id == widget.initial.id) {
          stored = recipe;
          break;
        }
      }
      final saved = stored != null;
      final recipe = stored ?? widget.initial;
      final missing = widget.initiallySaved && snapshot.hasData && !saved;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Da descoberta à sua mesa',
            style: TextStyle(fontSize: 15),
          ),
        ),
        body: missing
            ? const StatusPanel(
                icon: Icons.menu_book_outlined,
                title: 'Esta receita saiu do caderno',
                message:
                    'Ela foi removida em outra tela ou dispositivo. Volte para continuar explorando.',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (snapshot.hasError)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Não foi possível sincronizar o caderno. Confira sua conexão.',
                              style: TextStyle(color: ShelfColors.orange),
                            ),
                          ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final image = ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: RecipeImage(
                                url: recipe.imageUrl,
                                height: 330,
                              ),
                            );
                            final description = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  saved
                                      ? 'NO SEU CADERNO'
                                      : 'UMA NOVA DESCOBERTA',
                                  style: const TextStyle(
                                    color: ShelfColors.orange,
                                    letterSpacing: 2,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  recipe.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (recipe.category.isNotEmpty)
                                      Chip(
                                        avatar: const Icon(
                                          Icons.restaurant_outlined,
                                          size: 17,
                                        ),
                                        label: Text(recipe.category),
                                      ),
                                    if (recipe.area.isNotEmpty)
                                      Chip(
                                        avatar: const Icon(
                                          Icons.public_outlined,
                                          size: 17,
                                        ),
                                        label: Text(recipe.area),
                                      ),
                                    Chip(
                                      label: Text(
                                        '${recipe.ingredients.length} ingredientes',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                if (_busy) const LinearProgressIndicator(),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (!saved)
                                      FilledButton.icon(
                                        onPressed: _busy || snapshot.hasError
                                            ? null
                                            : () => _save(recipe),
                                        icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                        ),
                                        label: const Text('Salvar no caderno'),
                                      )
                                    else ...[
                                      FilledButton.icon(
                                        onPressed: _busy
                                            ? null
                                            : () => _edit(recipe),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Dar meu toque'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _busy
                                            ? null
                                            : () => _delete(recipe),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Remover'),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  saved
                                      ? 'Uma cópia só sua. Edite sem alterar a receita original.'
                                      : 'Guarde uma cópia completa e adapte ao seu gosto.',
                                  style: const TextStyle(
                                    color: ShelfColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                            if (constraints.maxWidth < 750) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  image,
                                  const SizedBox(height: 26),
                                  description,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: image),
                                const SizedBox(width: 36),
                                Expanded(child: description),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 38),
                        const Divider(color: ShelfColors.line),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final ingredients = Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ShelfColors.line),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Na bancada',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Marque o que já separou.',
                                    style: TextStyle(
                                      color: ShelfColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ...recipe.ingredients.asMap().entries.map(
                                    (e) => CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      value: _checked.contains(e.key),
                                      title: Text(
                                        e.value,
                                        style: TextStyle(
                                          decoration: _checked.contains(e.key)
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: _checked.contains(e.key)
                                              ? ShelfColors.muted
                                              : ShelfColors.ink,
                                        ),
                                      ),
                                      onChanged: (checked) => setState(() {
                                        if (checked == true) {
                                          _checked.add(e.key);
                                        } else {
                                          _checked.remove(e.key);
                                        }
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            final instructions = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mãos à massa',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Um passo de cada vez, no seu ritmo.',
                                  style: TextStyle(color: ShelfColors.muted),
                                ),
                                const SizedBox(height: 26),
                                ...recipe.instructions.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 25),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(
                                            0xFFEAF0E3,
                                          ),
                                          child: Text(
                                            '${e.key + 1}',
                                            style: const TextStyle(
                                              color: ShelfColors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: SelectableText(
                                            e.value,
                                            semanticsLabel: e.value,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (recipe.notes.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EDD9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Meu toque pessoal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SelectableText(
                                          recipe.notes,
                                          semanticsLabel: recipe.notes,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                            if (constraints.maxWidth < 750) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ingredients,
                                  const SizedBox(height: 30),
                                  instructions,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 320, child: ingredients),
                                const SizedBox(width: 40),
                                Expanded(child: instructions),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Fonte: TheMealDB. O catálogo original está em inglês.',
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
      );
    },
  );
}
