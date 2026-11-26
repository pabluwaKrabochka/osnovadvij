import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';

/// Живий ботанічний фон із м'яким дихаючим світлом та неоновим / золотим пилком
class BotanicalBackground extends StatefulWidget {
  const BotanicalBackground({super.key});

  @override
  State<BotanicalBackground> createState() => _BotanicalBackgroundState();
}

class _BotanicalBackgroundState extends State<BotanicalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_ambientCtrl, OsnovaTheme.themeNotifier]),
        builder: (context, _) {
          return CustomPaint(
            painter: _BotanicalLeavesPainter(
              progress: _ambientCtrl.value,
              palette: OsnovaTheme.current,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _BotanicalLeavesPainter extends CustomPainter {
  final double progress;
  final OsnovaPalette palette;

  _BotanicalLeavesPainter({
    required this.progress,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final breath = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);

    final spotlightRect = Rect.fromLTWH(0, 0, size.width * 0.68, size.height);
    final spotlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.1),
        radius: 0.95 + 0.08 * breath,
        colors: [
          palette.surfaceElevated.withValues(
            alpha: palette.isNeon ? 0.32 + 0.10 * breath : 0.24 + 0.08 * breath,
          ),
          palette.neonGlow.withValues(
            alpha: palette.isNeon ? 0.06 + 0.04 * breath : 0.03 + 0.02 * breath,
          ),
          Colors.transparent,
        ],
      ).createShader(spotlightRect);
    canvas.drawRect(spotlightRect, spotlightPaint);

    final leafFill = Paint()
      ..color = palette.surfaceCard.withValues(alpha: palette.isNeon ? 0.44 : 0.36)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = (palette.isNeon ? palette.neonGlow : palette.gold)
          .withValues(alpha: (palette.isNeon ? 0.22 : 0.11) + 0.05 * breath)
      ..style = PaintingStyle.stroke
      ..strokeWidth = palette.isNeon ? 1.15 : 1.0;

    final sway = math.sin(progress * 2 * math.pi) * 0.025;

    _drawSprig(
      canvas: canvas,
      origin: Offset(-18, size.height + 10),
      angle: -0.68 + sway,
      length: 235,
      leafCount: 7,
      fill: leafFill,
      stroke: leafStroke,
    );

    _drawSprig(
      canvas: canvas,
      origin: const Offset(-10, -10),
      angle: 0.65 - sway,
      length: 170,
      leafCount: 5,
      fill: leafFill,
      stroke: leafStroke,
    );

    _drawSprig(
      canvas: canvas,
      origin: Offset(size.width * 0.64, size.height + 12),
      angle: -2.25 + sway,
      length: 185,
      leafCount: 6,
      fill: leafFill,
      stroke: leafStroke,
    );

    final dustPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final seed = i * 1.6180339;
      final px = ((seed * 0.37) % 0.64) * size.width;
      final basePy = ((seed * 0.73) % 1.0) * size.height;
      final floatY = basePy - ((progress + seed) % 1.0) * 45;
      final twinkle = 0.5 + 0.5 * math.sin((progress * 2 * math.pi) + i * 1.3);

      dustPaint.color = (palette.isNeon ? palette.neonGlow : palette.goldBright)
          .withValues(alpha: (palette.isNeon ? 0.12 : 0.05) + 0.14 * twinkle);
      canvas.drawCircle(
        Offset(px + math.sin(progress * 2 * math.pi + i) * 6, floatY),
        1.3 + (i % 2) * 0.7,
        dustPaint,
      );
    }
  }

  void _drawSprig({
    required Canvas canvas,
    required Offset origin,
    required double angle,
    required double length,
    required int leafCount,
    required Paint fill,
    required Paint stroke,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final stemPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -14, length, 0);
    canvas.drawPath(stemPath, stroke);

    for (int i = 1; i <= leafCount; i++) {
      final t = i / (leafCount + 0.5);
      final x = length * t;
      final y = -14 * 2 * t * (1 - t);
      final leafLen = (1.0 - (t - 0.45).abs() * 0.7) * 58;

      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(side * 0.62);

        final petal = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(leafLen * 0.45, -leafLen * 0.28, leafLen, 0)
          ..quadraticBezierTo(leafLen * 0.45, leafLen * 0.28, 0, 0)
          ..close();

        canvas.drawPath(petal, fill);
        canvas.drawPath(petal, stroke);
        canvas.restore();
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeavesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.palette != palette;
  }
}

/// Подвійна фірмова рамка: ступінчаста для класики або зі скосом 45° для Cyberpunk
class OsnovaMenuFrame extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double cornerSize;
  final EdgeInsetsGeometry padding;

  const OsnovaMenuFrame({
    super.key,
    required this.child,
    this.borderColor,
    this.cornerSize = 9.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DoubleVintageFramePainter(
        color: borderColor ?? OsnovaTheme.gold.withValues(alpha: 0.34),
        cornerSize: cornerSize,
        isNeon: OsnovaTheme.isNeon,
        isCyberpunk: OsnovaTheme.isCyberpunk,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DoubleVintageFramePainter extends CustomPainter {
  final Color color;
  final double cornerSize;
  final bool isNeon;
  final bool isCyberpunk;

  _DoubleVintageFramePainter({
    required this.color,
    required this.cornerSize,
    required this.isNeon,
    required this.isCyberpunk,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= cornerSize * 3 || size.height <= cornerSize * 3) return;

    final outerRect = Rect.fromLTWH(2.0, 2.0, size.width - 4.0, size.height - 4.0);
    final innerRect = Rect.fromLTWH(5.2, 5.2, size.width - 10.4, size.height - 10.4);

    final outerPath = isCyberpunk
        ? _buildChamferedRectPath(outerRect, cornerSize)
        : _buildSteppedRectPath(outerRect, cornerSize);

    final innerCorner = math.max(4.0, cornerSize - 2.2);
    final innerPath = isCyberpunk
        ? _buildChamferedRectPath(innerRect, innerCorner)
        : _buildSteppedRectPath(innerRect, innerCorner);

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isNeon ? 1.15 : 0.95;

    final innerPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 0.55).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawPath(outerPath, outerPaint);
    canvas.drawPath(innerPath, innerPaint);
  }

  /// Скошені 45° кути для стилю Cyberpunk
  Path _buildChamferedRectPath(Rect r, double c) {
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  /// Класичні ступінчасті кути клубного меню
  Path _buildSteppedRectPath(Rect r, double c) {
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right - c, r.top + c)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left + c, r.bottom - c)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..lineTo(r.left + c, r.top + c)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DoubleVintageFramePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerSize != cornerSize ||
        oldDelegate.isNeon != isNeon ||
        oldDelegate.isCyberpunk != isCyberpunk;
  }
}

/// Розділювач із ботанічною гілочкою по центру
class GoldLeafDivider extends StatelessWidget {
  final double height;

  const GoldLeafDivider({super.key, this.height = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GoldLeafDividerPainter(
          primary: OsnovaTheme.gold,
          bright: OsnovaTheme.goldBright,
        ),
      ),
    );
  }
}

class _GoldLeafDividerPainter extends CustomPainter {
  final Color primary;
  final Color bright;

  _GoldLeafDividerPainter({
    required this.primary,
    required this.bright,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = primary.withValues(alpha: 0.42)
      ..strokeWidth = 1.0;

    final leafPaint = Paint()
      ..color = bright.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(12, center.dy),
      Offset(center.dx - 26, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 26, center.dy),
      Offset(size.width - 12, center.dy),
      linePaint,
    );

    canvas.drawLine(
      Offset(center.dx - 16, center.dy + 1),
      Offset(center.dx + 16, center.dy - 1),
      linePaint..strokeWidth = 1.2,
    );

    for (final dx in [-9.0, 0.0, 9.0]) {
      for (final dir in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(center.dx + dx, center.dy);
        canvas.rotate(dir * 0.65);
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(4, -2.5, 8.5, 0)
          ..quadraticBezierTo(4, 2.5, 0, 0)
          ..close();
        canvas.drawPath(leaf, leafPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GoldLeafDividerPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.bright != bright;
}