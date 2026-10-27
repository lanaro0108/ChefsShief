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
  test('Portuguese category search uses filter.php and loads details only on demand', () async {
    final requests = <Uri>[];
    final api = MealApi(MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('filter.php')) {
        expect(request.url.queryParameters['c'], 'Vegetarian');
        return http.Response(jsonEncode({
          'meals': [{'idMeal': '52771', 'strMeal': 'Penne', 'strMealThumb': ''}],
        }), 200);
      }
      expect(request.url.path, endsWith('lookup.php'));
      expect(request.url.queryParameters['i'], '52771');
      return http.Response(jsonEncode({'meals': [mealFixture()]}), 200);
    }));
    final previews = await api.search('vegetariano');
    expect(previews.single.isPreview, isTrue);
    expect(requests.length, 1);
    final full = await Future.wait([api.complete(previews.single), api.complete(previews.single)]);
    expect(full.first.isPreview, isFalse);
    expect(full.first.ingredients, isNotEmpty);
    expect(requests.length, 2);
    await api.complete(previews.single);
    expect(requests.length, 2);
  });

  test('Portuguese dish aliases preserve international names and query encoding', () async {
    final sent = <String?>[];
    final api = MealApi(MockClient((request) async {
      sent.add(request.url.queryParameters['s']);
      return http.Response('{"meals":null}', 200);
    }));
    await api.search('bolo de chocolate');
    await api.search('Arrabiata');
    await api.search('fish & chips');
    expect(sent, ['chocolate cake', 'Arrabiata', 'fish & chips']);
  });

  test('a failed or mismatched detail lookup is not cached', () async {
    var correct = false;
    var calls = 0;
    final api = MealApi(MockClient((_) async {
      calls++;
      return http.Response(jsonEncode({
        'meals': [mealFixture(id: correct ? '52771' : '999')],
      }), 200);
    }));
    await expectLater(api.original('52771'), throwsA(isA<AppFailure>()));
    correct = true;
    expect((await api.original('52771')).sourceId, '52771');
    expect(calls, 2);
  });

}
