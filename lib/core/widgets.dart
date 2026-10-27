import 'package:flutter/material.dart';
import '../app/theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: light
              ? Colors.white.withValues(alpha: .15)
              : ShelfColors.green,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        "Chef’s Shelf",
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          color: light ? Colors.white : ShelfColors.green,
        ),
      ),
    ],
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFFEAF0E6),
              child: Icon(icon, size: 34, color: ShelfColors.green),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ShelfColors.muted, height: 1.6),
            ),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    ),
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.url, this.height = 190});
  final String url;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      color: const Color(0xFFE9EBDD),
      alignment: Alignment.center,
      child: const Icon(
        Icons.ramen_dining_rounded,
        size: 58,
        color: ShelfColors.green,
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}
