import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_failure.dart';
import '../domain/recipe.dart';

class MealApi {
  MealApi(this.client);
  final http.Client client;

  Future<List<Recipe>> search(String query) async {
    try {
      final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/search.php', {
        's': query.trim(),
      });
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const AppFailure(
          'O catálogo está indisponível. Tente novamente.',
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!body.containsKey('meals')) throw const FormatException();
      final meals = body['meals'] as List?;
      return meals
              ?.map((item) => Recipe.fromMeal(item as Map<String, dynamic>))
              .toList() ??
          [];
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
}
