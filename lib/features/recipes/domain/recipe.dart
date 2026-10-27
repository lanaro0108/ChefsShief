/// Snapshot independente da API. Ingredientes e passos são arrays de strings.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    this.imageUrl = '',
    this.category = '',
    this.area = '',
    this.notes = '',
    this.sourceId = '',
    this.savedAt,
  });

  final String id;
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final String category;
  final String area;
  final String notes;
  final String sourceId;
  final DateTime? savedAt;

  bool get isPreview => ingredients.isEmpty || instructions.isEmpty;

  factory Recipe.fromMealSummary(Map<String, dynamic> meal, {String category = ''}) {
    final id = (meal['idMeal'] as String? ?? '').trim();
    final title = (meal['strMeal'] as String? ?? '').trim();
    if (!RegExp(r'^[0-9]{1,32}
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? value
        : '';
  }

  factory Recipe.fromMeal(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    for (var index = 1; index <= 20; index++) {
      final ingredient = (meal['strIngredient$index'] as String? ?? '').trim();
      final measure = (meal['strMeasure$index'] as String? ?? '').trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(
          [measure, ingredient].where((s) => s.isNotEmpty).join(' '),
        );
      }
    }
    final text = (meal['strInstructions'] as String? ?? '').trim();
    final steps = text
        .split(RegExp(r'\r?\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final id = meal['idMeal'] as String? ?? '';
    final title = (meal['strMeal'] as String? ?? '').trim();
    if (id.isEmpty || title.isEmpty || ingredients.isEmpty || steps.isEmpty) {
      throw const FormatException('A API retornou uma receita incompleta.');
    }
    return Recipe(
      id: 'meal_$id',
      sourceId: id,
      title: title,
      ingredients: List.unmodifiable(ingredients),
      instructions: List.unmodifiable(steps),
      imageUrl: safeImage(meal['strMealThumb'] as String? ?? ''),
      category: meal['strCategory'] as String? ?? '',
      area: meal['strArea'] as String? ?? '',
    );
  }

  factory Recipe.fromMap(
    String id,
    Map<String, dynamic> map, {
    DateTime? savedAt,
  }) => Recipe(
    id: id,
    title: map['title'] as String,
    ingredients: List<String>.unmodifiable(map['ingredients'] as List),
    instructions: List<String>.unmodifiable(map['instructions'] as List),
    imageUrl: safeImage(map['imageUrl'] as String? ?? ''),
    category: map['category'] as String? ?? '',
    area: map['area'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    sourceId: map['sourceId'] as String? ?? '',
    savedAt: savedAt,
  );

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'ingredients': ingredients,
    'instructions': instructions,
    'imageUrl': imageUrl,
    'category': category,
    'area': area,
    'notes': notes,
    'sourceId': sourceId,
  };

  Recipe edited({
    required String title,
    required List<String> ingredients,
    required List<String> instructions,
    required String notes,
  }) => Recipe(
    id: id,
    title: title,
    ingredients: List.unmodifiable(ingredients),
    instructions: List.unmodifiable(instructions),
    notes: notes,
    imageUrl: imageUrl,
    category: category,
    area: area,
    sourceId: sourceId,
    savedAt: savedAt,
  );

  String? get validationError {
    if ([...ingredients, ...instructions].any((s) => s.contains('\u001f'))) {
      return 'Remova caracteres de controle dos ingredientes e passos.';
    }
    if (title.trim().isEmpty || title.trim().length > 120) {
      return 'O título deve ter entre 1 e 120 caracteres.';
    }
    if (ingredients.isEmpty ||
        ingredients.length > 40 ||
        ingredients.any((s) => s.trim().isEmpty || s.length > 300)) {
      return 'Adicione de 1 a 40 ingredientes, com até 300 caracteres cada.';
    }
    if (instructions.isEmpty ||
        instructions.length > 40 ||
        instructions.any((s) => s.trim().isEmpty || s.length > 5000)) {
      return 'Adicione de 1 a 40 passos, com até 5.000 caracteres cada.';
    }
    if (notes.length > 2000) return 'Use até 2.000 caracteres nas observações.';
    return null;
  }
}
).hasMatch(id) || title.isEmpty) {
      throw const FormatException('Resumo de receita inválido.');
    }
    return Recipe(
      id: 'meal_$id',
      sourceId: id,
      title: title,
      ingredients: const [],
      instructions: const [],
      imageUrl: safeImage(meal['strMealThumb'] as String? ?? ''),
      category: category,
    );
  }

  static String safeImage(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? value
        : '';
  }

  factory Recipe.fromMeal(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    for (var index = 1; index <= 20; index++) {
      final ingredient = (meal['strIngredient$index'] as String? ?? '').trim();
      final measure = (meal['strMeasure$index'] as String? ?? '').trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(
          [measure, ingredient].where((s) => s.isNotEmpty).join(' '),
        );
      }
    }
    final text = (meal['strInstructions'] as String? ?? '').trim();
    final steps = text
        .split(RegExp(r'\r?\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final id = meal['idMeal'] as String? ?? '';
    final title = (meal['strMeal'] as String? ?? '').trim();
    if (id.isEmpty || title.isEmpty || ingredients.isEmpty || steps.isEmpty) {
      throw const FormatException('A API retornou uma receita incompleta.');
    }
    return Recipe(
      id: 'meal_$id',
      sourceId: id,
      title: title,
      ingredients: List.unmodifiable(ingredients),
      instructions: List.unmodifiable(steps),
      imageUrl: safeImage(meal['strMealThumb'] as String? ?? ''),
      category: meal['strCategory'] as String? ?? '',
      area: meal['strArea'] as String? ?? '',
    );
  }

  factory Recipe.fromMap(
    String id,
    Map<String, dynamic> map, {
    DateTime? savedAt,
  }) => Recipe(
    id: id,
    title: map['title'] as String,
    ingredients: List<String>.unmodifiable(map['ingredients'] as List),
    instructions: List<String>.unmodifiable(map['instructions'] as List),
    imageUrl: safeImage(map['imageUrl'] as String? ?? ''),
    category: map['category'] as String? ?? '',
    area: map['area'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    sourceId: map['sourceId'] as String? ?? '',
    savedAt: savedAt,
  );

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'ingredients': ingredients,
    'instructions': instructions,
    'imageUrl': imageUrl,
    'category': category,
    'area': area,
    'notes': notes,
    'sourceId': sourceId,
  };

  Recipe edited({
    required String title,
    required List<String> ingredients,
    required List<String> instructions,
    required String notes,
  }) => Recipe(
    id: id,
    title: title,
    ingredients: List.unmodifiable(ingredients),
    instructions: List.unmodifiable(instructions),
    notes: notes,
    imageUrl: imageUrl,
    category: category,
    area: area,
    sourceId: sourceId,
    savedAt: savedAt,
  );

  String? get validationError {
    if ([...ingredients, ...instructions].any((s) => s.contains('\u001f'))) {
      return 'Remova caracteres de controle dos ingredientes e passos.';
    }
    if (title.trim().isEmpty || title.trim().length > 120) {
      return 'O título deve ter entre 1 e 120 caracteres.';
    }
    if (ingredients.isEmpty ||
        ingredients.length > 40 ||
        ingredients.any((s) => s.trim().isEmpty || s.length > 300)) {
      return 'Adicione de 1 a 40 ingredientes, com até 300 caracteres cada.';
    }
    if (instructions.isEmpty ||
        instructions.length > 40 ||
        instructions.any((s) => s.trim().isEmpty || s.length > 5000)) {
      return 'Adicione de 1 a 40 passos, com até 5.000 caracteres cada.';
    }
    if (notes.length > 2000) return 'Use até 2.000 caracteres nas observações.';
    return null;
  }
}
