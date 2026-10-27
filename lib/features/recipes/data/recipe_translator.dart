import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_failure.dart';
import '../domain/recipe.dart';

/// Uses the documented anonymous MyMemory API for public catalogue text only.
/// Personal notes and notebook edits are never submitted to this service.
class RecipeTranslator {
  RecipeTranslator(this.client);
  final http.Client client;
  final _recipes = <String, Future<Recipe>>{};
  final _texts = <String, String>{};
  final _titles = <String, (String, String)>{};

  String titleFor(Recipe recipe) {
    final cached = _titles[recipe.sourceId];
    if (cached != null && cached.$1 == recipe.title) return cached.$2;
    return _phrases[recipe.title.trim().toLowerCase()] ?? recipe.title;
  }

  Future<Recipe> translate(Recipe source) async {
    if (source.isPreview) {
      throw const AppFailure('Abra a receita completa antes de traduzir.');
    }
    final key = jsonEncode([
      source.sourceId,
      source.title,
      source.ingredients,
      source.instructions,
    ]);
    if (!_recipes.containsKey(key)) {
      if (_recipes.length >= 100) _recipes.remove(_recipes.keys.first);
      _recipes[key] = _translateRecipe(source);
    }
    try {
      final translated = await _recipes[key]!;
      return source.edited(
        title: translated.title,
        ingredients: translated.ingredients,
        instructions: translated.instructions,
        notes: source.notes,
      );
    } catch (_) {
      _recipes.remove(key);
      rethrow;
    }
  }

  Future<Recipe> _translateRecipe(Recipe source) async {
    final title = await _text(source.title);
    final ingredients = <String>[];
    for (final ingredient in source.ingredients) {
      ingredients.add(await _text(ingredient));
    }
    final instructions = <String>[];
    for (final step in source.instructions) {
      instructions.add(await _text(step));
    }
    final result = source.edited(
      title: title,
      ingredients: ingredients,
      instructions: instructions,
      notes: source.notes,
    );
    if (result.validationError != null) {
      throw const AppFailure(
        'A tradução não pôde ser validada. A receita original foi mantida.',
      );
    }
    if (_titles.length >= 100) _titles.remove(_titles.keys.first);
    _titles[source.sourceId] = (source.title, result.title);
    return result;
  }

  Future<String> _text(String source) async {
    if (_texts[source] case final String cached) return cached;
    final local = _phrases[source.trim().toLowerCase()] ?? _ingredient(source);
    if (local != null) return local;
    final chunks = _chunks(source);
    final translated = <String>[];
    for (final chunk in chunks) {
      translated.add(await _request(chunk));
    }
    final result = translated.join(' ');
    if (_numbers(source) != _numbers(result)) {
      throw const AppFailure(
        'A tradução alterou uma quantidade. Consulte a receita original.',
      );
    }
    if (_texts.length >= 512) _texts.remove(_texts.keys.first);
    _texts[source] = result;
    return result;
  }

  static String _numbers(String value) => RegExp(
    r'\d+(?:[.,]\d+)?',
  ).allMatches(value).map((match) => match[0]!.replaceAll(',', '.')).join('|');

  /// The provider accepts 500 UTF-8 bytes per request. Split on whitespace
  /// with headroom, preserving quantities, temperatures and step order.
  static List<String> _chunks(String source) {
    final result = <String>[];
    var chunk = '';
    for (final match in RegExp(r'\S+').allMatches(source)) {
      final word = match[0]!;
      if (utf8.encode(word).length > 450) {
        throw const AppFailure(
          'Este texto precisa ser consultado na receita original.',
        );
      }
      final candidate = chunk.isEmpty ? word : '$chunk $word';
      if (utf8.encode(candidate).length > 450) {
        result.add(chunk);
        chunk = word;
      } else {
        chunk = candidate;
      }
    }
    if (chunk.isNotEmpty) result.add(chunk);
    if (result.isEmpty) {
      throw const AppFailure('O texto da receita está vazio.');
    }
    return result;
  }

  Future<String> _request(String text) async {
    try {
      final response = await client
          .get(
            Uri.https('api.mymemory.translated.net', '/get', {
              'q': text,
              'langpair': 'en|pt-BR',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw const FormatException();
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (body['responseStatus'].toString() != '200' ||
          body['quotaFinished'] == true) {
        throw const FormatException();
      }
      final data = body['responseData'] as Map<String, dynamic>;
      final translated = _decodeEntities(
        (data['translatedText'] as String).trim(),
      );
      if (translated.isEmpty ||
          translated.toLowerCase() == text.toLowerCase() ||
          translated.contains('\u001f')) {
        throw const FormatException();
      }
      return translated;
    } on TimeoutException {
      throw const AppFailure(
        'A tradução demorou demais. Você pode ler o original ou tentar novamente.',
      );
    } on http.ClientException {
      throw const AppFailure(
        'Não foi possível traduzir agora. Confira a conexão e tente novamente.',
      );
    } on FormatException {
      throw const AppFailure(
        'A tradução está temporariamente indisponível ou atingiu sua cota. A receita original continua disponível.',
      );
    } on TypeError {
      throw const AppFailure(
        'O serviço não enviou uma tradução válida. Consulte o original e tente novamente.',
      );
    }
  }

  static String _decodeEntities(String value) {
    var result = value;
    for (final entry in const {
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&lt;': '<',
      '&gt;': '>',
      '&amp;': '&',
    }.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (
      match,
    ) {
      final token = match[1]!;
      final code = token.startsWith('x')
          ? int.tryParse(token.substring(1), radix: 16)
          : int.tryParse(token);
      return code != null && code > 0 && code <= 0x10ffff
          ? String.fromCharCode(code)
          : match[0]!;
    });
  }

  static String? _ingredient(String source) {
    final normalized = source.trim().toLowerCase();
    // Recognize a complete ingredient and complete measure, never a few words
    // inside an otherwise untranslated sentence.
    final names = _ingredients.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final name in names) {
      if (normalized != name && !normalized.endsWith(' $name')) continue;
      var measure = normalized
          .substring(0, normalized.length - name.length)
          .trim();
      for (final unit in _units.entries) {
        measure = measure.replaceAll(
          RegExp('\\b${RegExp.escape(unit.key)}\\b'),
          unit.value,
        );
      }
      var remainder = measure;
      final units = _units.values.toSet().toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final unit in units) {
        remainder = remainder.replaceAll(unit, '');
      }
      if (remainder
          .replaceAll(RegExp(r'[0-9\s.,/¼½¾⅓⅔⅛⅜⅝⅞()\-–+]+'), '')
          .isNotEmpty) {
        return null;
      }
      final ingredient = _ingredients[name]!;
      if (measure.isEmpty) return ingredient;
      if (measure == 'a gosto') return '$ingredient a gosto';
      return RegExp(r'[a-zà-ÿ]').hasMatch(measure)
          ? '$measure de $ingredient'
          : '$measure $ingredient';
    }
    return null;
  }

  static const _units = {
    'tablespoons': 'colheres de sopa',
    'tablespoon': 'colher de sopa',
    'teaspoons': 'colheres de chá',
    'teaspoon': 'colher de chá',
    'cups': 'xícaras',
    'cup': 'xícara',
    'cloves': 'dentes',
    'clove': 'dente',
    'leaves': 'folhas',
    'leaf': 'folha',
    'pounds': 'libras',
    'pound': 'libra',
    'lbs': 'libras',
    'lb': 'libra',
    'ounces': 'onças',
    'ounce': 'onça',
    'oz': 'onça',
    'tbs': 'colher de sopa',
    'tbsp': 'colher de sopa',
    'tsp': 'colher de chá',
    'pinch': 'pitada',
    'to taste': 'a gosto',
    'tin': 'lata',
    'cans': 'latas',
    'can': 'lata',
    'g': 'g',
    'kg': 'kg',
    'ml': 'ml',
    'l': 'l',
  };

  static const _ingredients = {
    'penne rigate': 'penne rigate',
    'penne': 'penne',
    'olive oil': 'azeite',
    'vegetable oil': 'óleo vegetal',
    'sunflower oil': 'óleo de girassol',
    'sesame oil': 'óleo de gergelim',
    'garlic': 'alho',
    'garlic clove': 'dente de alho',
    'chopped tomatoes': 'tomates picados',
    'tomatoes': 'tomates',
    'tomato': 'tomate',
    'red chilli flakes': 'pimenta calabresa em flocos',
    'italian seasoning': 'ervas italianas',
    'basil': 'manjericão',
    'parmigiano-reggiano': 'queijo parmesão',
    'parmesan cheese': 'queijo parmesão',
    'parmesan': 'queijo parmesão',
    'salt': 'sal',
    'pepper': 'pimenta',
    'black pepper': 'pimenta-do-reino',
    'sugar': 'açúcar',
    'caster sugar': 'açúcar refinado',
    'brown sugar': 'açúcar mascavo',
    'flour': 'farinha de trigo',
    'plain flour': 'farinha de trigo',
    'butter': 'manteiga',
    'milk': 'leite',
    'water': 'água',
    'eggs': 'ovos',
    'egg': 'ovo',
    'onion': 'cebola',
    'onions': 'cebolas',
    'chicken': 'frango',
    'chicken breast': 'peito de frango',
    'chicken breasts': 'peitos de frango',
    'rice': 'arroz',
    'potatoes': 'batatas',
    'potato': 'batata',
    'carrots': 'cenouras',
    'carrot': 'cenoura',
    'lemon': 'limão',
    'lime': 'limão',
    'coriander': 'coentro',
    'parsley': 'salsinha',
    'cream': 'creme de leite',
    'double cream': 'creme de leite fresco',
    'honey': 'mel',
    'soy sauce': 'molho de soja',
    'cumin': 'cominho',
    'paprika': 'páprica',
    'cinnamon': 'canela',
    'ginger': 'gengibre',
    'pasta': 'massa',
  };

  static const _phrases = {
    'spicy arrabiata penne': 'Penne ao molho arrabbiata',
    'boil water.': 'Ferva a água.',
    'cook pasta.': 'Cozinhe a massa.',
    'serve.': 'Sirva.',
    'in a large skillet over medium-high heat, add the olive oil and heat until the oil starts to shimmer. add the garlic and cook, stirring, until fragrant, 1 to 2 minutes. add the chopped tomatoes, red chile flakes, italian seasoning and salt and pepper to taste. bring to a boil and cook for 5 minutes. remove from the heat and add the chopped basil.':
        'Em uma frigideira grande, aqueça o azeite em fogo médio-alto até começar a brilhar. Acrescente o alho e refogue, mexendo, até perfumar, por 1 a 2 minutos. Adicione os tomates picados, a pimenta calabresa, as ervas italianas, o sal e a pimenta a gosto. Deixe ferver e cozinhe por 5 minutos. Retire do fogo e acrescente o manjericão picado.',
    'drain the pasta and add it to the sauce. garnish with parmigiano-reggiano flakes and more basil and serve warm.':
        'Escorra a massa e misture-a ao molho. Finalize com lascas de queijo parmesão e mais manjericão. Sirva quente.',
  };
}
