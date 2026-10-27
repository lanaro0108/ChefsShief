import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets.dart';
import '../domain/recipe.dart';
import '../domain/recipe_language.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.saved,
    required this.onOpen,
    required this.onSave,
    this.busy = false,
    this.displayTitle,
  });
  final Recipe recipe;
  final String? displayTitle;
  final bool saved;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    button: true,
    label: 'Abrir receita ${displayTitle ?? recipe.title}',
    onTap: onOpen,
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RecipeImage(url: recipe.imageUrl, height: 210),
                if (recipe.category.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        RecipeLanguage.category(recipe.category),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle ?? recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!recipe.isPreview)
                    Text(
                      '${recipe.ingredients.length} ingredientes',
                      style: const TextStyle(
                        color: ShelfColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.public_outlined,
                        size: 15,
                        color: ShelfColors.muted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          recipe.area.isEmpty
                              ? 'Cozinha do mundo'
                              : RecipeLanguage.area(recipe.area),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShelfColors.muted,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: saved
                            ? 'Receita no seu caderno'
                            : 'Salvar ${recipe.title}',
                        onPressed: busy || saved ? null : onSave,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                saved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_add_outlined,
                                color: ShelfColors.primary,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
