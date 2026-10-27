import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Static vector paper texture: no image download, animation or hit targets.
class KitchenBackdrop extends StatelessWidget {
  const KitchenBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _KitchenPaperPainter(),
    child: child,
  );
}

class _KitchenPaperPainter extends CustomPainter {
  const _KitchenPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ShelfColors.background);
    final grain = Paint()..color = ShelfColors.ink.withValues(alpha: .035);
    for (var y = 8.0; y < size.height; y += 24) {
      for (var x = 9.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x + (y.toInt() % 7), y), .65, grain);
      }
    }
    _herb(canvas, Offset(size.width - 18, 110), -.55, 1);
    _herb(canvas, Offset(18, size.height - 160), 2.55, .8);
  }

  void _herb(Canvas canvas, Offset origin, double rotation, double scale) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    final stroke = Paint()
      ..color = ShelfColors.olive.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(Path()..moveTo(0, 0)..quadraticBezierTo(-24, 90, 0, 210), stroke);
    for (var index = 0; index < 6; index++) {
      final y = 28.0 + index * 29;
      for (final direction in [-1.0, 1.0]) {
        final leaf = Path()
          ..moveTo(-9, y)
          ..quadraticBezierTo(direction * 70, y - 30, direction * 61, y + 6)
          ..quadraticBezierTo(direction * 32, y + 25, -9, y);
        canvas.drawPath(leaf, stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KitchenPaperPainter oldDelegate) => false;
}

class NotebookPaper extends StatelessWidget {
  const NotebookPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ShelfColors.paper,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ShelfColors.line),
      boxShadow: [
        BoxShadow(
          color: ShelfColors.ink.withValues(alpha: .04),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(painter: const _RuledPaperPainter(), child: child),
  );
}

class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ShelfColors.line.withValues(alpha: .32)
      ..strokeWidth = .6;
    for (var y = 132.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(16, y), Offset(math.max(16.0, size.width - 16), y), paint);
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, 5, 80), Paint()..color = ShelfColors.olive);
  }

  @override
  bool shouldRepaint(_RuledPaperPainter oldDelegate) => false;
}
