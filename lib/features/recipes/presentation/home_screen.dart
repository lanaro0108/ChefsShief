import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/app.dart';
import '../../../app/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/auth_service.dart';
import '../data/meal_api.dart';
import '../data/notebook_repository.dart';
import '../domain/recipe.dart';
import 'recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'search_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.auth,
    required this.api,
    required this.notebook,
  });
  final User user;
  final AuthService auth;
  final MealApi api;
  final NotebookRepository notebook;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final RecipeSearchController _search;
  late Stream<List<Recipe>> _notebook;
  final _query = TextEditingController(text: 'chicken');
  final _notebookQuery = TextEditingController();
  final _saving = <String>{};
  int _tab = 0;
  String _category = 'Todas';
  bool _alphabetical = false;

  @override
  void initState() {
    super.initState();
    _search = RecipeSearchController(widget.api);
    _notebook = widget.notebook.watchAll(widget.user.uid);
    unawaited(_search.search('chicken'));
  }

  @override
  void dispose() {
    _search.dispose();
    _query.dispose();
    _notebookQuery.dispose();
    super.dispose();
  }

  Future<void> _save(Recipe recipe) async {
    setState(() => _saving.add(recipe.id));
    try {
      final created = await widget.notebook.save(widget.user.uid, recipe);
      if (mounted) {
        showMessage(
          context,
          created
              ? 'Receita salva no seu caderno!'
              : 'Esta receita já está no seu caderno.',
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Não foi possível salvar. Confira sua conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(recipe.id));
    }
  }

  void _open(Recipe recipe, bool saved) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          initial: recipe,
          initiallySaved: saved,
          uid: widget.user.uid,
          notebook: widget.notebook,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await widget.auth.signOut();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Não foi possível sair. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Recipe>>(
    stream: _notebook,
    builder: (context, snapshot) {
      final saved = snapshot.data ?? <Recipe>[];
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const EmulatorNotice(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (desktop) _sidebar(saved.length),
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: desktop ? 36 : 20,
                                  vertical: 18,
                                ),
                                child: Row(
                                  children: [
                                    if (!desktop)
                                      const Brand()
                                    else
                                      const Text(
                                        'GOURMETGO / SEU ESPAÇO NA COZINHA',
                                        style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 1.4,
                                          color: ShelfColors.muted,
                                        ),
                                      ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      tooltip: 'Minha conta',
                                      onSelected: (_) => _signOut(),
                                      itemBuilder: (_) => [
                                        PopupMenuItem<String>(
                                          enabled: false,
                                          value: 'email',
                                          child: Text(
                                            widget.user.email ?? 'Minha conta',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'logout',
                                          child: Text('Sair da conta'),
                                        ),
                                      ],
                                      child: CircleAvatar(
                                        backgroundColor: ShelfColors.subtle,
                                        child: Text(
                                          (widget
                                                          .user
                                                          .displayName
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? widget.user.displayName!
                                                  : widget.user.email ?? 'C')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: ShelfColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: ShelfColors.line),
                              Expanded(
                                child: ListenableBuilder(
                                  listenable: _search,
                                  builder: (context, _) =>
                                      _content(saved, snapshot),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    selectedIndex: _tab,
                    onDestinationSelected: (tab) => setState(() => _tab = tab),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: 'Descobrir',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book),
                        label: 'Meu caderno',
                      ),
                    ],
                  ),
          );
        },
      );
    },
  );

  Widget _sidebar(int count) => Container(
    width: 238,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: ShelfColors.line)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Brand(),
        const SizedBox(height: 46),
        const Padding(
          padding: EdgeInsets.only(left: 14, bottom: 14),
          child: Text(
            'NA SUA MESA',
            style: TextStyle(
              fontSize: 10,
              color: ShelfColors.muted,
              letterSpacing: 2,
            ),
          ),
        ),
        _navigationItem(0, Icons.explore_outlined, 'Descobrir'),
        const SizedBox(height: 8),
        _navigationItem(
          1,
          Icons.menu_book_outlined,
          'Meu caderno',
          count: count,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ShelfColors.subtle,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco_outlined, color: ShelfColors.primary),
              SizedBox(height: 12),
              Text(
                'Uma pitada de inspiração',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'A melhor receita é aquela que ganha o seu toque.',
                style: TextStyle(
                  color: ShelfColors.muted,
                  height: 1.6,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'GourmetGo · Feito para saborear',
          style: TextStyle(fontSize: 10, color: ShelfColors.muted),
        ),
      ],
    ),
  );

  Widget _navigationItem(int tab, IconData icon, String label, {int? count}) =>
      Material(
        color: _tab == tab ? ShelfColors.darkRed : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _tab = tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: _tab == tab ? Colors.white : ShelfColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _tab == tab ? Colors.white : ShelfColors.ink,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      color: _tab == tab ? Colors.white70 : ShelfColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _content(List<Recipe> saved, AsyncSnapshot<List<Recipe>> notebook) {
    final discovering = _tab == 0;
    final filtered = saved
        .where(
          (r) =>
              r.title.toLowerCase().contains(
                _notebookQuery.text.toLowerCase(),
              ) &&
              (_category == 'Todas' || r.category == _category),
        )
        .toList();
    if (_alphabetical) {
      filtered.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    final categories = {
      'Todas',
      ...saved.map((r) => r.category).where((s) => s.isNotEmpty),
    };
    return SingleChildScrollView(
      key: PageStorageKey('tab-$_tab'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                discovering ? 'PARA O SEU PRÓXIMO PRATO' : 'SABORES QUE FICAM',
                style: const TextStyle(
                  color: ShelfColors.darkRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                discovering
                    ? 'O que vamos cozinhar hoje?'
                    : 'Meu caderno de receitas',
                style: MediaQuery.sizeOf(context).width < 600
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                discovering
                    ? 'Encontre uma nova inspiração e guarde o que der vontade de repetir.'
                    : '${saved.length} receitas, muitas possibilidades. Tudo com o seu toque.',
                style: const TextStyle(color: ShelfColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 26),
              if (discovering) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ShelfColors.subtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.soup_kitchen_outlined,
                        size: 46,
                        color: ShelfColors.primary,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Do mundo para a sua cozinha',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Explore receitas de diferentes lugares com o TheMealDB.',
                              style: TextStyle(color: ShelfColors.darkRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              TextField(
                key: Key(discovering ? 'recipe-search' : 'notebook-search'),
                controller: discovering ? _query : _notebookQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: discovering
                      ? 'Buscar receitas'
                      : 'Buscar no meu caderno',
                  hintText: discovering
                      ? 'Ex.: chicken, pasta, cake...'
                      : 'Qual receita você quer preparar?',
                  suffixIcon: discovering
                      ? IconButton(
                          tooltip: 'Buscar agora',
                          onPressed: () => _search.search(_query.text),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: discovering
                    ? _search.schedule
                    : (_) => setState(() {}),
                onSubmitted: discovering ? _search.search : null,
              ),
              const SizedBox(height: 12),
              if (discovering) ...[
                const Text(
                  'Dica: o catálogo internacional encontra receitas pelo nome em inglês.',
                  style: TextStyle(color: ShelfColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      {
                            'Frango': 'chicken',
                            'Massas': 'pasta',
                            'Sobremesas': 'cake',
                            'Vegetariano': 'vegetarian',
                          }.entries
                          .map(
                            (e) => ActionChip(
                              label: Text(e.key),
                              avatar: const Icon(Icons.north_east, size: 14),
                              onPressed: () {
                                _query.text = e.value;
                                _search.search(e.value);
                              },
                            ),
                          )
                          .toList(),
                ),
              ] else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...categories.map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _alphabetical = !_alphabetical),
                      icon: const Icon(Icons.sort_by_alpha, size: 18),
                      label: Text(
                        _alphabetical ? 'Ordem: A–Z' : 'Ordem: mais recentes',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              if (discovering && _search.loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (discovering && _search.error != null)
                StatusPanel(
                  icon: Icons.wifi_off_outlined,
                  title: 'A busca precisa de mais um instante',
                  message: _search.error!,
                  action: FilledButton(
                    onPressed: () => _search.search(_query.text),
                    child: const Text('Tentar novamente'),
                  ),
                )
              else if (!discovering && notebook.hasError)
                StatusPanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'Não foi possível abrir o caderno',
                  message:
                      'Confira a conexão e tente novamente. Seu caderno continua protegido.',
                  action: OutlinedButton(
                    onPressed: () => setState(() {
                      _notebook = widget.notebook.watchAll(widget.user.uid);
                    }),
                    child: const Text('Verificar novamente'),
                  ),
                )
              else if (!discovering && !notebook.hasData)
                const Center(child: CircularProgressIndicator())
              else if ((discovering ? _search.recipes : filtered).isEmpty)
                StatusPanel(
                  icon: discovering
                      ? Icons.search_off
                      : Icons.menu_book_outlined,
                  title: discovering
                      ? 'Ainda não encontramos esse sabor'
                      : saved.isEmpty
                      ? 'Seu caderno começa com uma receita'
                      : 'Nenhuma receita com esse filtro',
                  message: discovering
                      ? 'Experimente outro nome em inglês, como chicken ou cake.'
                      : saved.isEmpty
                      ? 'Descubra um prato e toque no marcador para guardar a receita aqui.'
                      : 'Tente outro nome ou escolha outra categoria.',
                  action: !discovering && saved.isEmpty
                      ? FilledButton(
                          onPressed: () => setState(() => _tab = 0),
                          child: const Text('Descobrir receitas'),
                        )
                      : null,
                )
              else ...[
                Row(
                  children: [
                    Text(
                      discovering ? 'Inspirações para você' : 'Suas receitas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${(discovering ? _search.recipes : filtered).length} receitas',
                      style: const TextStyle(
                        color: ShelfColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth >= 1050
                        ? 4
                        : constraints.maxWidth >= 720
                        ? 3
                        : constraints.maxWidth >= 480
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (count - 1) * 20) / count;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: (discovering ? _search.recipes : filtered).map((
                        recipe,
                      ) {
                        final isSaved = saved.any((r) => r.id == recipe.id);
                        return SizedBox(
                          width: width,
                          child: RecipeCard(
                            recipe: recipe,
                            saved: isSaved,
                            busy: _saving.contains(recipe.id),
                            onOpen: () => _open(recipe, isSaved),
                            onSave: () => _save(recipe),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 36),
              const Divider(color: ShelfColors.line),
              const SizedBox(height: 12),
              const Text(
                'Receitas por TheMealDB · Seu caderno, seu jeito de cozinhar.',
                style: TextStyle(color: ShelfColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
