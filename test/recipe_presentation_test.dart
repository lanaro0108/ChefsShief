import 'dart:convert';
import 'package:chefs_shelf/app/theme.dart';
import 'package:chefs_shelf/core/kitchen_backdrop.dart';
import 'package:chefs_shelf/features/recipes/data/meal_api.dart';
import 'package:chefs_shelf/features/recipes/data/notebook_repository.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe_language.dart';
import 'package:chefs_shelf/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const original = Recipe(
  id: 'meal_999',
  sourceId: '999',
  title: 'Example dish',
  ingredients: ['3 cloves garlic'],
  instructions: ['Heat for 2 minutes.'],
);

class MemoryNotebook implements NotebookRepository {
  MemoryNotebook([this.recipe]);
  Recipe? recipe;
  Recipe? saved;
  @override
  Stream<List<Recipe>> watchAll(String uid) => Stream.value([?recipe]);
  @override
  Future<bool> save(String uid, Recipe recipe) async {
    saved = recipe;
    return true;
  }

  @override
  Future<void> update(String uid, Recipe recipe) async {}
  @override
  Future<void> delete(String uid, String recipeId) async {}
}

void main() {
  testWidgets(
    'mobile detail switches language, clears checklist and saves Portuguese',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final notebook = MemoryNotebook();
      final api = MealApi(
        MockClient(
          (request) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'responseStatus': 200,
                'responseData': {
                  'translatedText':
                      request.url.queryParameters['q'] == 'Example dish'
                      ? 'Prato de exemplo'
                      : 'Aqueça por 2 minutos.',
                },
              }),
            ),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: shelfTheme(),
          builder: (context, child) => KitchenBackdrop(child: child!),
          home: RecipeDetailScreen(
            initial: original,
            initiallySaved: false,
            uid: 'chef',
            notebook: notebook,
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Prato de exemplo'), findsOneWidget);
      final checkbox = find.byType(CheckboxListTile).first;
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      expect(find.text('1 de 1 ingredientes separados'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver original'));
      await tester.tap(find.text('Ver original'));
      await tester.pumpAndSettle();
      expect(find.text('Example dish'), findsOneWidget);
      expect(find.text('0 de 1 ingredientes separados'), findsOneWidget);
      await tester.tap(find.text('Voltar à receita'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar no caderno'));
      await tester.tap(find.text('Salvar no caderno'));
      await tester.pumpAndSettle();
      expect(notebook.saved?.title, 'Prato de exemplo');
      expect(notebook.saved?.ingredients, ['3 dentes de alho']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved personal text is not translated or replaced when consulting source',
    (tester) async {
      final personal = original.edited(
        title: 'Minha receita especial',
        ingredients: ['2 dentes de alho'],
        instructions: ['Refogue lentamente.'],
        notes: 'Meu segredo',
      );
      var requests = 0;
      final api = MealApi(
        MockClient((request) async {
          requests++;
          expect(request.url.host, 'www.themealdb.com');
          return http.Response(
            jsonEncode({
              'meals': [
                {
                  'idMeal': '999',
                  'strMeal': 'Example dish',
                  'strIngredient1': 'Garlic',
                  'strMeasure1': '3 cloves',
                  'strInstructions': 'Heat for 2 minutes.',
                },
              ],
            }),
            200,
          );
        }),
      );
      final notebook = MemoryNotebook(personal);
      await tester.pumpWidget(
        MaterialApp(
          theme: shelfTheme(),
          home: RecipeDetailScreen(
            initial: personal,
            initiallySaved: true,
            uid: 'chef',
            notebook: notebook,
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minha receita especial'), findsOneWidget);
      expect(requests, 0);
      await tester.tap(find.text('Ver original'));
      await tester.pumpAndSettle();
      expect(find.text('Example dish'), findsOneWidget);
      expect(requests, 1);
      await tester.tap(find.text('Voltar para minha receita'));
      await tester.pumpAndSettle();
      expect(find.text('Minha receita especial'), findsOneWidget);
      expect(notebook.recipe?.notes, 'Meu segredo');
      expect(notebook.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'long preparation paragraphs become readable steps without altering storage',
    () {
      final paragraph = List.filled(30, 'Misture com cuidado.').join(' ');
      final stored = [paragraph];
      expect(RecipeLanguage.readableSteps(stored).length, 30);
      expect(stored.single, paragraph);
      expect(RecipeLanguage.area('Italian'), 'Italiana');
      expect(RecipeLanguage.category('Vegetarian'), 'Vegetariano');
    },
  );
}
