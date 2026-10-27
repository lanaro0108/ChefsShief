import 'dart:convert';
import 'dart:io';
import 'package:chefs_shelf/core/app_failure.dart';
import 'package:chefs_shelf/features/recipes/data/recipe_translator.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const source = Recipe(
  id: 'meal_999',
  sourceId: '999',
  title: 'Example dish',
  ingredients: ['3 cloves garlic', '1/4 cup olive oil'],
  instructions: ['Heat for 2 minutes.'],
  notes: 'Minha anotação privada',
);

http.Response translated(String text) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'responseStatus': 200,
      'responseData': {'translatedText': text},
    }),
  ),
  200,
);

void main() {
  test(
    'international names and shared ingredient words may remain unchanged',
    () async {
      const recipe = Recipe(
        id: 'meal_321',
        sourceId: '321',
        title: 'Sushi',
        ingredients: ['100 g tofu'],
        instructions: ['Heat for 2 minutes.'],
      );
      final translator = RecipeTranslator(
        MockClient((request) async {
          final text = request.url.queryParameters['q']!;
          return translated(
            text == 'Heat for 2 minutes.' ? 'Aqueça por 2 minutos.' : text,
          );
        }),
      );
      final result = await translator.translate(recipe);
      expect(result.title, 'Sushi');
      expect(result.ingredients, ['100 g tofu']);
      expect(result.instructions, ['Aqueça por 2 minutos.']);
    },
  );
  test('all catalogue origins have local Portuguese labels', () {
    final body =
        jsonDecode(File('test/fixtures/areas.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final area in body['meals'] as List) {
      expect(
        RecipeLanguage.areas.containsKey(area['strArea']),
        isTrue,
        reason: area['strArea'] as String,
      );
    }
    expect(RecipeLanguage.recipeCount(1), '1 receita');
    expect(RecipeLanguage.recipeCount(2), '2 receitas');
  });
  test(
    'translates a complete snapshot, preserves measures, caches and never sends notes',
    () async {
      final sent = <String>[];
      final translator = RecipeTranslator(
        MockClient((request) async {
          expect(request.url.scheme, 'https');
          expect(request.url.host, 'api.mymemory.translated.net');
          expect(request.url.queryParameters['langpair'], 'en|pt-BR');
          final text = request.url.queryParameters['q']!;
          sent.add(text);
          return translated(
            text == source.title ? 'Prato de exemplo' : 'Aqueça por 2 minutos.',
          );
        }),
      );
      final results = await Future.wait([
        translator.translate(source),
        translator.translate(source),
      ]);
      expect(results.first.title, 'Prato de exemplo');
      expect(results.first.ingredients, [
        '3 dentes de alho',
        '1/4 xícara de azeite',
      ]);
      expect(results.first.instructions, ['Aqueça por 2 minutos.']);
      expect(results.first.notes, source.notes);
      expect(results.first.sourceId, source.sourceId);
      expect(sent, ['Example dish', 'Heat for 2 minutes.']);
      final withNewNotes = source.edited(
        title: source.title,
        ingredients: source.ingredients,
        instructions: source.instructions,
        notes: 'Outra anotação privada',
      );
      expect(
        (await translator.translate(withNewNotes)).notes,
        withNewNotes.notes,
      );
      expect(sent.length, 2);
      expect(sent.any((text) => text.contains('privada')), isFalse);
    },
  );

  test(
    'quota and malformed responses keep the original intact and can be retried',
    () async {
      var available = false;
      final translator = RecipeTranslator(
        MockClient((request) async {
          if (!available) {
            return http.Response(
              '{"responseStatus":429,"quotaFinished":true}',
              200,
            );
          }
          return translated(
            request.url.queryParameters['q'] == source.title
                ? 'Prato de exemplo'
                : 'Aqueça por 2 minutos.',
          );
        }),
      );
      await expectLater(
        translator.translate(source),
        throwsA(isA<AppFailure>()),
      );
      expect(source.title, 'Example dish');
      expect(source.instructions, ['Heat for 2 minutes.']);
      available = true;
      expect((await translator.translate(source)).title, 'Prato de exemplo');
    },
  );

  test(
    'a changed quantity is rejected instead of saving an unsafe translation',
    () async {
      final translator = RecipeTranslator(
        MockClient(
          (request) async => translated(
            request.url.queryParameters['q'] == source.title
                ? 'Prato de exemplo'
                : 'Aqueça por 20 minutos.',
          ),
        ),
      );
      await expectLater(
        translator.translate(source),
        throwsA(isA<AppFailure>()),
      );
      expect(source.instructions.single, 'Heat for 2 minutes.');
    },
  );

  test(
    'long UTF-8 text stays within provider limits and content changes invalidate cache',
    () async {
      var calls = 0;
      final translator = RecipeTranslator(
        MockClient((request) async {
          calls++;
          final text = request.url.queryParameters['q']!;
          expect(utf8.encode(text).length, lessThanOrEqualTo(450));
          return translated(
            text == source.title
                ? 'Prato de exemplo'
                : 'Misture delicadamente.',
          );
        }),
      );
      final long = source.edited(
        title: source.title,
        ingredients: source.ingredients,
        instructions: [List.filled(180, 'Sauté gently.').join(' ')],
        notes: '',
      );
      final result = await translator.translate(long);
      expect(calls, greaterThan(2));
      expect(result.instructions.single, contains('Misture delicadamente.'));
      final previous = calls;
      await translator.translate(long);
      expect(calls, previous);
      final changed = long.edited(
        title: 'Another dish',
        ingredients: long.ingredients,
        instructions: long.instructions,
        notes: '',
      );
      await translator.translate(changed);
      expect(calls, previous + 1);
    },
  );

  test(
    'fraction and temperature changes are rejected while equivalent fractions work',
    () async {
      for (final entry in {
        'Add ½ portion.': 'Adicione ¾ de porção.',
        'Heat to 180°C.': 'Aqueça a 180°F.',
      }.entries) {
        final translator = RecipeTranslator(
          MockClient(
            (request) async => translated(
              request.url.queryParameters['q'] == source.title
                  ? 'Prato de exemplo'
                  : entry.value,
            ),
          ),
        );
        final recipe = source.edited(
          title: source.title,
          ingredients: source.ingredients,
          instructions: [entry.key],
          notes: '',
        );
        await expectLater(
          translator.translate(recipe),
          throwsA(isA<AppFailure>()),
        );
      }
      final translator = RecipeTranslator(
        MockClient(
          (request) async => translated(
            request.url.queryParameters['q'] == source.title
                ? 'Prato de exemplo'
                : 'Adicione 1/2 porção.',
          ),
        ),
      );
      final recipe = source.edited(
        title: source.title,
        ingredients: source.ingredients,
        instructions: ['Add ½ portion.'],
        notes: '',
      );
      expect(
        (await translator.translate(recipe)).instructions.single,
        'Adicione 1/2 porção.',
      );
    },
  );

  test(
    'reviewed catalogue recipe is fully available in Portuguese without a provider request',
    () async {
      final body =
          jsonDecode(File('test/fixtures/arrabiata.json').readAsStringSync())
              as Map<String, dynamic>;
      final original = Recipe.fromMeal(
        (body['meals'] as List).single as Map<String, dynamic>,
      );
      final translator = RecipeTranslator(
        MockClient((_) async => throw StateError('Unexpected network')),
      );
      final result = await translator.translate(original);
      expect(result.title, 'Penne ao molho arrabbiata');
      expect(result.ingredients.length, 8);
      expect(result.ingredients, contains('1/4 xícara de azeite'));
      expect(result.ingredients.last, 'um pouco de queijo parmesão');
      expect(result.instructions.first, contains('9 minutos'));
      expect(result.validationError, isNull);
    },
  );

  test(
    'malformed payloads and network failures produce recoverable errors',
    () async {
      for (final response in [
        http.Response('bad json', 200),
        http.Response('{}', 200),
        http.Response('unavailable', 503),
      ]) {
        final translator = RecipeTranslator(MockClient((_) async => response));
        await expectLater(
          translator.translate(source),
          throwsA(isA<AppFailure>()),
        );
      }
      final translator = RecipeTranslator(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        translator.translate(source),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test('previews cannot be translated or saved as complete recipes', () async {
    final preview = Recipe.fromMealSummary({
      'idMeal': '123',
      'strMeal': 'Dish',
    });
    expect(preview.isPreview, isTrue);
    expect(preview.validationError, isNotNull);
    final translator = RecipeTranslator(
      MockClient((_) async => throw StateError('Unexpected network')),
    );
    await expectLater(
      translator.translate(preview),
      throwsA(isA<AppFailure>()),
    );
  });
}
