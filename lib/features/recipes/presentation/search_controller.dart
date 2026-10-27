import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/app_failure.dart';
import '../data/meal_api.dart';
import '../domain/recipe.dart';

class RecipeSearchController extends ChangeNotifier {
  RecipeSearchController(this.api);
  final MealApi api;
  List<Recipe> recipes = [];
  bool loading = false;
  String? error;
  String query = 'frango';
  int _generation = 0;
  bool _disposed = false;
  Timer? _debounce;

  void schedule(String value) {
    _debounce?.cancel();
    _generation++; // Ignore an older request even during the debounce interval.
    query = value.trim();
    loading = true;
    error = null;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 450), () => search(query));
  }

  Future<void> search(String value) async {
    _debounce?.cancel();
    final generation = ++_generation;
    query = value.trim();
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.search(query);
      if (_disposed || generation != _generation) return;
      recipes = result;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure is AppFailure
          ? failure.message
          : 'Não foi possível buscar. Tente novamente.';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
