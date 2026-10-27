import 'package:chefs_shelf/app/app.dart';
import 'package:chefs_shelf/app/theme.dart';
import 'package:chefs_shelf/features/recipes/data/notebook_repository.dart';
import 'package:chefs_shelf/features/recipes/domain/recipe.dart';
import 'package:chefs_shelf/features/recipes/presentation/recipe_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'recipe_test.dart' show mealFixture;

class RecordingNotebook implements NotebookRepository {
  Recipe? updated;
  @override
  Future<void> update(String uid, Recipe recipe) async {
    updated = recipe;
  }

  @override
  Stream<List<Recipe>> watchAll(String uid) => Stream.value([]);
  @override
  Future<bool> save(String uid, Recipe recipe) async => true;
  @override
  Future<void> delete(String uid, String recipeId) async {}
}

void main() {
  testWidgets(
    'unconfigured app explains how to start without pretending Firebase works',
    (tester) async {
      await tester.pumpWidget(const SetupApp());
      expect(find.text('Vamos preparar a cozinha?'), findsOneWidget);
      expect(
        find.textContaining('config/firebase.android.json'),
        findsOneWidget,
      );
      expect(find.textContaining('--dart-define-from-file='), findsOneWidget);
    },
  );
  testWidgets(
    'mobile editor rejects a blank title and preserves structured ingredients',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = RecordingNotebook();
      await tester.pumpWidget(
        MaterialApp(
          theme: shelfTheme(),
          home: RecipeEditorScreen(
            recipe: Recipe.fromMeal(mealFixture()),
            uid: 'alice',
            notebook: repository,
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('edit-title')), '');
      await tester.ensureVisible(find.byKey(const Key('edit-save')));
      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pump();
      expect(repository.updated, isNull);
      await tester.ensureVisible(find.byKey(const Key('edit-title')));
      expect(find.text('Dê um nome para a receita.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('edit-title')),
        'Minha massa',
      );
      final ingredient = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Ingrediente 1',
      );
      final step = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Passo 1',
      );
      await tester.ensureVisible(ingredient);
      await tester.enterText(ingredient, '300 g massa');
      await tester.ensureVisible(step);
      await tester.enterText(step, 'Cozinhe em água salgada.');
      await tester.ensureVisible(find.byKey(const Key('edit-notes')));
      await tester.enterText(
        find.byKey(const Key('edit-notes')),
        'Servir com manjericão.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();
      expect(repository.updated?.title, 'Minha massa');
      expect(repository.updated?.ingredients, ['300 g massa', 'Tomato']);
      expect(repository.updated?.instructions.length, 3);
      expect(
        repository.updated?.instructions.first,
        'Cozinhe em água salgada.',
      );
      expect(repository.updated?.notes, 'Servir com manjericão.');
      expect(tester.takeException(), isNull);
    },
  );
}
