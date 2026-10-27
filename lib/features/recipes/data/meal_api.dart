import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_failure.dart';
import '../domain/recipe.dart';
import '../domain/recipe_language.dart';
import 'recipe_translator.dart';

class MealApi {
  MealApi(this.client, {RecipeTranslator? translator})
    : translator = translator ?? RecipeTranslator(client);
  final http.Client client;
  final RecipeTranslator translator;
  final _details = <String, Recipe>{};
  final _pending = <String, Future<Recipe>>{};

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await client
          .get(Uri.https('www.themealdb.com', '/api/json/v1/1/$path', query))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const AppFailure(
          'O catálogo está indisponível. Tente novamente.',
        );
      }
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (!body.containsKey('meals')) throw const FormatException();
      return body;
    } on AppFailure {
      rethrow;
    } on TimeoutException {
      throw const AppFailure(
        'A busca demorou demais. Confira sua conexão e tente de novo.',
      );
    } on FormatException {
      throw const AppFailure(
        'O catálogo enviou dados inválidos. Tente novamente mais tarde.',
      );
    } on TypeError {
      throw const AppFailure(
        'O catálogo enviou dados inválidos. Tente novamente mais tarde.',
      );
    } on http.ClientException {
      throw const AppFailure(
        'Não foi possível conectar ao catálogo. Confira sua internet.',
      );
    }
  }

  Future<List<Recipe>> search(String query) async {
    final category = RecipeLanguage.searchCategory(query);
    final body = await _get(
      category == null ? 'search.php' : 'filter.php',
      category == null
          ? {'s': RecipeLanguage.searchName(query)}
          : {'c': category},
    );
    try {
      final meals = body['meals'] as List?;
      final recipes =
          meals?.map((item) {
            final meal = item as Map<String, dynamic>;
            return category == null
                ? Recipe.fromMeal(meal)
                : Recipe.fromMealSummary(meal, category: category);
          }).toList() ??
          <Recipe>[];
      for (final recipe in recipes.where((recipe) => !recipe.isPreview)) {
        _remember(recipe);
      }
      return recipes;
    } on FormatException {
      throw const AppFailure(
        'O catálogo enviou uma receita incompleta. Tente novamente.',
      );
    } on TypeError {
      throw const AppFailure(
        'O catálogo enviou dados inválidos. Tente novamente mais tarde.',
      );
    }
  }

  void _remember(Recipe recipe) {
    if (_details.length >= 100) _details.remove(_details.keys.first);
    _details[recipe.sourceId] = recipe;
  }

  Future<Recipe> complete(Recipe recipe) =>
      recipe.isPreview ? original(recipe.sourceId) : Future.value(recipe);

  Future<Recipe> original(String sourceId) async {
    if (!RegExp(r'^[0-9]{1,32}$').hasMatch(sourceId)) {
      throw const AppFailure('A receita não tem uma origem válida.');
    }
    if (_details[sourceId] case final Recipe recipe) return recipe;
    if (_pending[sourceId] case final Future<Recipe> request) return request;
    final request = _lookup(sourceId);
    _pending[sourceId] = request;
    try {
      return await request;
    } finally {
      _pending.remove(sourceId);
    }
  }

  Future<Recipe> _lookup(String sourceId) async {
    final body = await _get('lookup.php', {'i': sourceId});
    try {
      final meals = body['meals'] as List?;
      if (meals == null || meals.length != 1) throw const FormatException();
      final recipe = Recipe.fromMeal(meals.single as Map<String, dynamic>);
      if (recipe.sourceId != sourceId) throw const FormatException();
      _remember(recipe);
      return recipe;
    } on FormatException {
      throw const AppFailure('Não foi possível carregar a receita completa.');
    } on TypeError {
      throw const AppFailure(
        'O catálogo enviou dados inválidos. Tente novamente.',
      );
    }
  }
}
