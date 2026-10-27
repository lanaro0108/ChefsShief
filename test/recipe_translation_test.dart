import 'dart:convert';
import 'package:chefs_shelf/core/app_failure.dart';
import 'package:chefs_shelf/features/recipes/data/recipe_translator.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const source = Recipe(
  id: 'meal_999', sourceId: '999', title: 'Example dish',
  ingredients: ['3 cloves garlic', '1/4 cup olive oil'],
  instructions: ['Heat for 2 minutes.'], notes: 'Minha anotação privada',
);

http.Response translated(String text) => http.Response.bytes(
  utf8.encode(jsonEncode({
    'responseStatus': 200,
    'responseData': {'translatedText': text},
  })),
  200,
);

void main() {
  test('translates a complete snapshot, preserves measures, caches and never sends notes', () async {
    final sent = <String>[];
    final translator = RecipeTranslator(MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.mymemory.translated.net');
      expect(request.url.queryParameters['langpair'], 'en|pt-BR');
      final text = request.url.queryParameters['q']!;
      sent.add(text);
      return translated(text == source.title ? 'Prato de exemplo' : 'Aqueça por 2 minutos.');
    }));
    final results = await Future.wait([translator.translate(source), translator.translate(source)]);
    expect(results.first.title, 'Prato de exemplo');
    expect(results.first.ingredients, ['3 dentes de alho', '1/4 xícara de azeite']);
    expect(results.first.instructions, ['Aqueça por 2 minutos.']);
    expect(results.first.notes, source.notes);
    expect(results.first.sourceId, source.sourceId);
    expect(sent, ['Example dish', 'Heat for 2 minutes.']);
    final withNewNotes = source.edited(
      title: source.title, ingredients: source.ingredients,
      instructions: source.instructions, notes: 'Outra anotação privada',
    );
    expect((await translator.translate(withNewNotes)).notes, withNewNotes.notes);
    expect(sent.length, 2);
    expect(sent.any((text) => text.contains('privada')), isFalse);
  });

  test('quota and malformed responses keep the original intact and can be retried', () async {
    var available = false;
    final translator = RecipeTranslator(MockClient((request) async {
      if (!available) return http.Response('{"responseStatus":429,"quotaFinished":true}', 200);
      return translated(request.url.queryParameters['q'] == source.title
          ? 'Prato de exemplo' : 'Aqueça por 2 minutos.');
    }));
    await expectLater(translator.translate(source), throwsA(isA<AppFailure>()));
    expect(source.title, 'Example dish');
    expect(source.instructions, ['Heat for 2 minutes.']);
    available = true;
    expect((await translator.translate(source)).title, 'Prato de exemplo');
  });

  test('a changed quantity is rejected instead of saving an unsafe translation', () async {
    final translator = RecipeTranslator(MockClient((request) async => translated(
      request.url.queryParameters['q'] == source.title
          ? 'Prato de exemplo' : 'Aqueça por 20 minutos.',
    )));
    await expectLater(translator.translate(source), throwsA(isA<AppFailure>()));
    expect(source.instructions.single, 'Heat for 2 minutes.');
  });

  test('long UTF-8 text stays within provider limits and content changes invalidate cache', () async {
    var calls = 0;
    final translator = RecipeTranslator(MockClient((request) async {
      calls++;
      final text = request.url.queryParameters['q']!;
      expect(utf8.encode(text).length, lessThanOrEqualTo(450));
      return translated(text == source.title ? 'Prato de exemplo' : 'Misture delicadamente.');
    }));
    final long = source.edited(
      title: source.title, ingredients: source.ingredients,
      instructions: [List.filled(180, 'Sauté gently.').join(' ')], notes: '',
    );
    final result = await translator.translate(long);
    expect(calls, greaterThan(2));
    expect(result.instructions.single, contains('Misture delicadamente.'));
    final previous = calls;
    await translator.translate(long);
    expect(calls, previous);
    final changed = long.edited(
      title: 'Another dish', ingredients: long.ingredients,
      instructions: long.instructions, notes: '',
    );
    await translator.translate(changed);
    expect(calls, previous + 1);
  });

  test('previews cannot be translated or saved as complete recipes', () async {
    final preview = Recipe.fromMealSummary({'idMeal': '123', 'strMeal': 'Dish'});
    expect(preview.isPreview, isTrue);
    expect(preview.validationError, isNotNull);
    final translator = RecipeTranslator(MockClient((_) async => throw StateError('Unexpected network')));
    await expectLater(translator.translate(preview), throwsA(isA<AppFailure>()));
  });
}
