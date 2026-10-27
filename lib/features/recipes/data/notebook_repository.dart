import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_failure.dart';
import '../domain/recipe.dart';

abstract interface class NotebookRepository {
  Stream<List<Recipe>> watchAll(String uid);
  Future<bool> save(String uid, Recipe recipe);
  Future<void> update(String uid, Recipe recipe);
  Future<void> delete(String uid, String recipeId);
}

class FirestoreNotebookRepository implements NotebookRepository {
  FirestoreNotebookRepository(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _recipes(String uid) =>
      firestore.collection('users').doc(uid).collection('recipes');

  @override
  Stream<List<Recipe>> watchAll(String uid) => _recipes(uid)
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => Recipe.fromMap(
                doc.id,
                doc.data(),
                savedAt: (doc.data()['savedAt'] as Timestamp?)?.toDate(),
              ),
            )
            .toList(),
      );

  @override
  Future<bool> save(String uid, Recipe recipe) async {
    _validate(recipe);
    final reference = _recipes(uid).doc(recipe.id);
    // Deterministic ID + transaction prevents duplicates and preserves edits.
    return firestore.runTransaction((transaction) async {
      if ((await transaction.get(reference)).exists) return false;
      transaction.set(reference, {
        ...recipe.toMap(),
        'savedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  @override
  Future<void> update(String uid, Recipe recipe) async {
    _validate(recipe);
    final reference = _recipes(uid).doc(recipe.id);
    await firestore.runTransaction<void>((transaction) async {
      if (!(await transaction.get(reference)).exists) {
        throw const AppFailure('Esta receita foi removida do caderno.');
      }
      transaction.update(reference, {
        ...recipe.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> delete(String uid, String recipeId) =>
      firestore.runTransaction<void>((transaction) async {
        final reference = _recipes(uid).doc(recipeId);
        if ((await transaction.get(reference)).exists) {
          transaction.delete(reference);
        }
      });

  void _validate(Recipe recipe) {
    if (recipe.validationError case final String error) throw AppFailure(error);
  }
}
