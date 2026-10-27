import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets.dart';
import '../domain/recipe.dart';
import '../domain/recipe_language.dart';

class DiscoveryHero extends StatelessWidget {
  const DiscoveryHero({
    super.key,
    required this.recipe,
    required this.title,
    required this.onOpen,
    this.busy = false,
  });
  final Recipe recipe;
  final String title;
  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ColoredBox(
      color: ShelfColors.olive,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NA COZINHA, HOJE',
                  style: TextStyle(
                    color: ShelfColors.paper,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    color: ShelfColors.paper,
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  recipe.category.isEmpty
                      ? 'Uma inspiração do mundo para a sua mesa.'
                      : RecipeLanguage.category(recipe.category),
                  style: const TextStyle(color: ShelfColors.paper, height: 1.6),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: ShelfColors.paper,
                    foregroundColor: ShelfColors.ink,
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: const Text('Preparar este prato'),
                ),
              ],
            ),
          );
          final image = RecipeImage(
            url: recipe.imageUrl,
            height: constraints.maxWidth < 680 ? 220 : 310,
          );
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [image, copy],
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: copy),
              Expanded(flex: 6, child: image),
            ],
          );
        },
      ),
    ),
  );
}
