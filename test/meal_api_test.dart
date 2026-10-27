import 'dart:async';
import 'dart:convert';
import 'package:chefs_shelf/core/app_failure.dart';
import 'package:chefs_shelf/features/recipes/data/meal_api.dart';
import 'package:chefs_shelf/features/recipes/presentation/search_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'recipe_test.dart' show mealFixture;

void main() {
  test('search uses HTTPS and safely encodes the query', () async {
    final api = MealApi(
      MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'www.themealdb.com');
        expect(request.url.queryParameters['s'], 'fish & chips');
        return http.Response(
          jsonEncode({
            'meals': [mealFixture()],
          }),
          200,
        );
      }),
    );
    expect((await api.search(' fish & chips ')).single.title, 'Spicy pasta');
  });
  test('null results represent an empty search, not a crash', () async {
    final api = MealApi(
      MockClient((_) async => http.Response('{"meals":null}', 200)),
    );
    expect(await api.search('nothing'), isEmpty);
  });
  test(
    'HTTP, malformed payload and network failures produce useful errors',
    () async {
      for (final response in [
        http.Response('unavailable', 503),
        http.Response('not json', 200),
        http.Response('{"meals":[42]}', 200),
        http.Response('{}', 200),
      ]) {
        final api = MealApi(MockClient((_) async => response));
        await expectLater(api.search('pasta'), throwsA(isA<AppFailure>()));
      }
      final offline = MealApi(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(offline.search('pasta'), throwsA(isA<AppFailure>()));
    },
  );
  test('older responses cannot overwrite a more recent search', () async {
    final older = Completer<http.Response>();
    final newer = Completer<http.Response>();
    final controller = RecipeSearchController(
      MealApi(
        MockClient(
          (request) => request.url.queryParameters['s'] == 'old'
              ? older.future
              : newer.future,
        ),
      ),
    );
    final first = controller.search('old');
    final second = controller.search('new');
    newer.complete(
      http.Response(
        jsonEncode({
          'meals': [mealFixture(title: 'New recipe')],
        }),
        200,
      ),
    );
    await second;
    older.complete(
      http.Response(
        jsonEncode({
          'meals': [mealFixture(title: 'Old recipe')],
        }),
        200,
      ),
    );
    await first;
    expect(controller.recipes.single.title, 'New recipe');
    expect(controller.loading, isFalse);
    controller.dispose();
  });
  test(
    'a request finishing after disposal does not notify listeners',
    () async {
      final response = Completer<http.Response>();
      final controller = RecipeSearchController(
        MealApi(MockClient((_) => response.future)),
      );
      final pending = controller.search('pasta');
      controller.dispose();
      response.complete(http.Response('{"meals":null}', 200));
      await pending;
    },
  );
}
