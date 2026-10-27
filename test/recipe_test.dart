import 'package:chefs_shelf/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> mealFixture({
  String id = '52771',
  String title = 'Spicy pasta',
}) => {
  'idMeal': id,
  'strMeal': title,
  'strCategory': 'Pasta',
  'strArea': 'Italian',
  'strMealThumb': 'https://www.themealdb.com/images/media/meals/test.jpg',
  'strIngredient1': ' Pasta ',
  'strMeasure1': ' 200 g ',
  'strIngredient2': 'Tomato',
  'strMeasure2': null,
  'strIngredient3': ' ',
  'strMeasure3': '100 g',
  'strInstructions': 'Boil water.\r\n\r\nCook pasta.\nServe.',
};

void main() {
  test(
    'TheMealDB becomes a structured snapshot with ordered steps and measurements',
    () {
      final recipe = Recipe.fromMeal(mealFixture());
      expect(recipe.id, 'meal_52771');
      expect(recipe.sourceId, '52771');
      expect(recipe.ingredients, ['200 g Pasta', 'Tomato']);
      expect(recipe.instructions, ['Boil water.', 'Cook pasta.', 'Serve.']);
      expect(recipe.validationError, isNull);
      expect(() => recipe.ingredients.add('changed'), throwsUnsupportedError);
    },
  );
  test(
    'saved recipe round-trip preserves arrays, notes and source metadata',
    () {
      final recipe = Recipe.fromMeal(mealFixture()).edited(
        title: 'Minha pasta',
        ingredients: ['100 g massa'],
        instructions: ['Cozinhe.'],
        notes: 'Sem pimenta',
      );
      final restored = Recipe.fromMap(recipe.id, recipe.toMap());
      expect(restored.toMap(), recipe.toMap());
      expect(restored.sourceId, '52771');
      expect(restored.imageUrl, recipe.imageUrl);
    },
  );
  test('incomplete API documents are rejected', () {
    for (final override in [
      {'idMeal': ''},
      {'strMeal': ''},
      {'strInstructions': '  '},
      {'strIngredient1': null, 'strIngredient2': null},
    ]) {
      expect(
        () => Recipe.fromMeal({...mealFixture(), ...override}),
        throwsFormatException,
      );
    }
  });
  test('unsafe image protocols are removed', () {
    expect(Recipe.safeImage('http://example.com/image.jpg'), isEmpty);
    expect(Recipe.safeImage('javascript:alert(1)'), isEmpty);
    expect(Recipe.safeImage('https://example.com/image.jpg'), isNotEmpty);
  });
  test('editor validation rejects empty or oversized lists and fields', () {
    final base = Recipe.fromMeal(mealFixture());
    for (final recipe in [
      base.edited(
        title: '',
        ingredients: ['a'],
        instructions: ['b'],
        notes: '',
      ),
      base.edited(title: 'a', ingredients: [], instructions: ['b'], notes: ''),
      base.edited(
        title: 'a',
        ingredients: ['a'],
        instructions: [' '],
        notes: '',
      ),
      base.edited(
        title: 'a',
        ingredients: List.filled(41, 'a'),
        instructions: ['b'],
        notes: '',
      ),
      base.edited(
        title: 'a',
        ingredients: ['a'],
        instructions: ['b'],
        notes: 'n' * 2001,
      ),
    ]) {
      expect(recipe.validationError, isNotNull);
    }
  });
}
