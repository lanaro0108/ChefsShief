import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Vector rendition of the supplied mark: three slanted red capsules.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.width = 52});
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, width * .64),
    painter: const _BrandMarkPainter(),
  );
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 350, size.height / 220);
    final paint = Paint()..color = ShelfColors.primary;
    for (final (x, y, height) in [
      (68.0, 125.0, 184.0),
      (177.0, 116.0, 210.0),
      (281.0, 91.0, 190.0),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.436332313);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 88, height: height),
          const Radius.circular(44),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) => false;
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    label: "Chef’s Shelf",
    image: true,
    excludeSemantics: true,
    child: SizedBox(
      width: 224,
      height: 44,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(),
            const SizedBox(width: 8),
            Text(
              "Chef’s Shelf",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: light ? ShelfColors.white : ShelfColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
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
              backgroundColor: ShelfColors.subtle,
              child: Icon(icon, size: 34, color: ShelfColors.primary),
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
      color: ShelfColors.subtle,
      alignment: Alignment.center,
      child: const Icon(
        Icons.ramen_dining_rounded,
        size: 58,
        color: ShelfColors.primary,
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
