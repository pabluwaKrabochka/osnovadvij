import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../controllers/pos_controller.dart';
import 'intro_page.dart';

class SplashPage extends StatefulWidget {
  final PosController controller;

  const SplashPage({super.key, required this.controller});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _ambientCtrl;

  late final Animation<double> _ringsDrawAnim;
  late final Animation<double> _hudFadeAnim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _letterSpacingAnim;
  late final Animation<double> _shockwaveAnim;
  late final Animation<double> _glintSweepAnim;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _progressAnim;

  late final List<_GoldenParticle> _particles;

  @override
  void initState() {
    super.initState();

    final rng = math.Random(42);
    _particles = List.generate(38, (index) {
      return _GoldenParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 1.0 + rng.nextDouble() * 2.2,
        speed: 0.12 + rng.nextDouble() * 0.28,
        drift: (rng.nextDouble() - 0.5) * 0.08,
        phase: rng.nextDouble() * math.pi * 2,
        isBright: index % 4 == 0,
      );
    });

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _ringsDrawAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
    );

    _hudFadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.10, 0.45, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.12, 0.50, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.10, 0.38, curve: Curves.easeOut),
    );

    _letterSpacingAnim = Tween<double>(begin: 18.0, end: 8.5).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.12, 0.54, curve: Curves.easeOutCubic),
      ),
    );

    _shockwaveAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.36, 0.72, curve: Curves.easeOutQuart),
    );

    _glintSweepAnim = Tween<double>(begin: -1.4, end: 2.4).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.46, 0.86, curve: Curves.easeInOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.38, 0.70, curve: Curves.easeOut),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.38, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.14, 0.96, curve: Curves.easeInOutCubic),
    );

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    await Future.wait([
      _mainCtrl.forward().orCancel.catchError((_) {}),
      widget.controller.initPos(),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, __, ___) => IntroPage(controller: widget.controller),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _bootStatusText(double progress) {
    if (progress < 0.32) return 'ІНІЦІАЛІЗАЦІЯ СИСТЕМИ OSNOVA...';
    if (progress < 0.65) return 'ПІДКЛЮЧЕННЯ БАЗИ ДАНИХ ТА КАСИ...';
    if (progress < 0.92) return 'СИНХРОНІЗАЦІЯ МЕНЮ І ЗАКУПОК...';
    return 'СИСТЕМА ГОТОВА ДО РОБОТИ';
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OsnovaTheme.bgDark,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Кінематографічний Canvas-фон: іскри, астролябія, імпульс та HUD-кути
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_mainCtrl, _ambientCtrl]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OsnovaSplashPainter(
                        ambientValue: _ambientCtrl.value,
                        ringsProgress: _ringsDrawAnim.value,
                        shockwaveProgress: _shockwaveAnim.value,
                        hudOpacity: _hudFadeAnim.value,
                        particles: _particles,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Верхній та нижній HUD-рядки телеметрії
            Positioned(
              top: 26,
              left: 34,
              right: 34,
              child: FadeTransition(
                opacity: _hudFadeAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: OsnovaTheme.liveGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: OsnovaTheme.liveGreen.withValues(alpha: 0.7),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OSNOVA TERMINAL • ONLINE',
                          style: TextStyle(
                            color: OsnovaTheme.sageMuted.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '48°30\'N  32°16\'E • UA',
                      style: TextStyle(
                        color: OsnovaTheme.gold.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Центральна композиція: емблема OSNOVA + слоган + плазмовий прогрес
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _mainCtrl,
                      builder: (context, _) {
                        return _EmblemPlaque(
                          letterSpacing: _letterSpacingAnim.value,
                          glintPosition: _glintSweepAnim.value,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OrnamentLine(leftToRight: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'ПРОСТІР ІГОР, КАВИ ТА ПОДІЙ',
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ),
                            _OrnamentLine(leftToRight: false),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'КРОПИВНИЦЬКИЙ  •  SMART POS SYSTEM',
                          style: TextStyle(
                            color: OsnovaTheme.sageMuted.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 42),

                // Високоточний прогрес-бар з відсотками і статусом
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    final val = _progressAnim.value;
                    final percent = (val * 100).round();

                    return SizedBox(
                      width: 310,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _bootStatusText(val),
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted
                                      .withValues(alpha: 0.9),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: OsnovaTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.2),
                                width: 0.6,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: val.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      OsnovaTheme.gold,
                                      OsnovaTheme.goldBright,
                                      Colors.white,
                                    ],
                                    stops: const [0.0, 0.82, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: OsnovaTheme.goldBright
                                          .withValues(alpha: 0.75),
                                      blurRadius: 10,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmblemPlaque extends StatelessWidget {
  final double letterSpacing;
  final double glintPosition;

  const _EmblemPlaque({
    required this.letterSpacing,
    required this.glintPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: OsnovaTheme.gold.withValues(alpha: 0.28),
            blurRadius: 42,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Глибока обсидіаново-смарагдова основа
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1B14),
                    Color(0xFF040B08),
                    Color(0xFF0D2219),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: OsnovaTheme.goldBright.withValues(alpha: 0.85),
                  width: 1.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Внутрішня тонка рамка
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      'OSNOVA',
                      style: TextStyle(
                        color: OsnovaTheme.creamText,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: letterSpacing,
                        shadows: [
                          Shadow(
                            color: OsnovaTheme.gold.withValues(alpha: 0.45),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4 декоративні золоті заклепки по кутах плашки
            const Positioned(top: 9, left: 9, child: _GoldRivet()),
            const Positioned(top: 9, right: 9, child: _GoldRivet()),
            const Positioned(bottom: 9, left: 9, child: _GoldRivet()),
            const Positioned(bottom: 9, right: 9, child: _GoldRivet()),

            // Металічний діагональний блік, що пробігає по логотипу
            Positioned.fill(
              child: IgnorePointer(
                child: FractionalTranslation(
                  translation: Offset(glintPosition, 0),
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Container(
                      width: 75,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            OsnovaTheme.goldBright.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.30),
                            OsnovaTheme.goldBright.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldRivet extends StatelessWidget {
  const _GoldRivet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.5,
      height: 4.5,
      decoration: BoxDecoration(
        color: OsnovaTheme.goldBright,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: OsnovaTheme.goldBright.withValues(alpha: 0.7),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  final bool leftToRight;

  const _OrnamentLine({required this.leftToRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 1.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: leftToRight
              ? [Colors.transparent, OsnovaTheme.goldBright]
              : [OsnovaTheme.goldBright, Colors.transparent],
        ),
      ),
    );
  }
}

class _GoldenParticle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
  final bool isBright;

  const _GoldenParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.isBright,
  });
}

class _OsnovaSplashPainter extends CustomPainter {
  final double ambientValue;
  final double ringsProgress;
  final double shockwaveProgress;
  final double hudOpacity;
  final List<_GoldenParticle> particles;

  _OsnovaSplashPainter({
    required this.ambientValue,
    required this.ringsProgress,
    required this.shockwaveProgress,
    required this.hudOpacity,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = ambientValue * 2 * math.pi;

    // 1. Глибока смарагдово-темна віньєтка та центральне дихаюче сяйво
    final bgRect = Offset.zero & size;
    final pulse = 0.90 + 0.10 * math.sin(angle * 2);
    final ambientGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          OsnovaTheme.gold.withValues(alpha: 0.15 * pulse),
          const Color(0xFF143528).withValues(alpha: 0.45),
          OsnovaTheme.bgDark,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.longestSide * 0.52),
      );
    canvas.drawRect(bgRect, ambientGlow);

    // 2. Тонка фонова геометрія (діагональні промені з центру)
    if (ringsProgress > 0) {
      final rayPaint = Paint()
        ..color = OsnovaTheme.gold.withValues(alpha: 0.05 * ringsProgress)
        ..strokeWidth = 1.0;
      for (int i = 0; i < 8; i++) {
        final rayAngle = (i * math.pi / 4) + angle * 0.08;
        final p1 = Offset(
          center.dx + math.cos(rayAngle) * 140,
          center.dy + math.sin(rayAngle) * 140,
        );
        final p2 = Offset(
          center.dx + math.cos(rayAngle) * (140 + 220 * ringsProgress),
          center.dy + math.sin(rayAngle) * (140 + 220 * ringsProgress),
        );
        canvas.drawLine(p1, p2, rayPaint);
      }
    }

    // 3. Летючі золоті іскри / пилок
    for (final p in particles) {
      final yPos = (p.y - ambientValue * p.speed) % 1.0;
      final wrappedY = yPos < 0 ? yPos + 1.0 : yPos;
      final xPos = (p.x + math.sin(angle + p.phase) * p.drift) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(angle * 3 + p.phase));

      final dotPaint = Paint()
        ..color = (p.isBright ? OsnovaTheme.goldBright : OsnovaTheme.gold)
            .withValues(alpha: 0.45 * twinkle * hudOpacity.clamp(0.2, 1.0));

      canvas.drawCircle(
        Offset(xPos * size.width, wrappedY * size.height),
        p.radius,
        dotPaint,
      );
    }

    // 4. Астролябія: концентричні кільця з градусними поділками
    if (ringsProgress > 0) {
      final sweep = 2 * math.pi * ringsProgress;

      // Зовнішнє тонке кільце
      final outerRadius = 215.0;
      final outerPaint = Paint()
        ..color = OsnovaTheme.gold.withValues(alpha: 0.22 * ringsProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2 + angle * 0.2,
        sweep,
        false,
        outerPaint,
      );

      // Градусні риски на зовнішньому кільці
      final tickPaint = Paint()
        ..color = OsnovaTheme.goldBright.withValues(alpha: 0.28 * ringsProgress)
        ..strokeWidth = 1.2;
      const tickCount = 36;
      for (int i = 0; i < tickCount; i++) {
        final tAngle = (i * 2 * math.pi / tickCount) + angle * 0.2;
        final isMajor = i % 3 == 0;
        final innerR = outerRadius - (isMajor ? 9.0 : 4.5);
        final outerR = outerRadius + (isMajor ? 3.0 : 0.0);
        canvas.drawLine(
          Offset(
            center.dx + math.cos(tAngle) * innerR,
            center.dy + math.sin(tAngle) * innerR,
          ),
          Offset(
            center.dx + math.cos(tAngle) * outerR,
            center.dy + math.sin(tAngle) * outerR,
          ),
          tickPaint,
        );
      }

      // Внутрішнє пунктирне орбітальне кільце (обертається у зворотний бік)
      final innerOrbitR = 172.0;
      final dashPaint = Paint()
        ..color = OsnovaTheme.sageMuted.withValues(alpha: 0.24 * ringsProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      const dashCount = 24;
      const dashArc = (2 * math.pi / dashCount) * 0.45;
      for (int i = 0; i < dashCount; i++) {
        final startA = (i * 2 * math.pi / dashCount) - angle * 0.35;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerOrbitR),
          startA,
          dashArc * ringsProgress,
          false,
          dashPaint,
        );
      }

      // 4 золотих ромби на кардинальних точках зовнішнього кільця
      final diamondPaint = Paint()
        ..color = OsnovaTheme.goldBright.withValues(alpha: 0.65 * ringsProgress)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        final dAngle = (i * math.pi / 2) + angle * 0.2;
        final dx = center.dx + math.cos(dAngle) * outerRadius;
        final dy = center.dy + math.sin(dAngle) * outerRadius;
        _drawDiamond(canvas, Offset(dx, dy), 4.5, diamondPaint);
      }
    }

    // 5. Світлова ударна хвиля (Shockwave) при фіксації логотипа
    if (shockwaveProgress > 0 && shockwaveProgress < 1) {
      final waveRadius = 110 + 230 * shockwaveProgress;
      final waveAlpha = (1.0 - shockwaveProgress) * 0.45;
      final wavePaint = Paint()
        ..color = OsnovaTheme.goldBright.withValues(alpha: waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockwaveProgress * 0.6);
      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // 6. Архітектурні HUD-кути по периметру екрана
    if (hudOpacity > 0) {
      final bracketPaint = Paint()
        ..color = OsnovaTheme.gold.withValues(alpha: 0.38 * hudOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      const margin = 18.0;
      const len = 26.0;

      // Лівий верхній
      canvas.drawPath(
        Path()
          ..moveTo(margin, margin + len)
          ..lineTo(margin, margin)
          ..lineTo(margin + len, margin),
        bracketPaint,
      );
      // Правий верхній
      canvas.drawPath(
        Path()
          ..moveTo(size.width - margin - len, margin)
          ..lineTo(size.width - margin, margin)
          ..lineTo(size.width - margin, margin + len),
        bracketPaint,
      );
      // Лівий нижній
      canvas.drawPath(
        Path()
          ..moveTo(margin, size.height - margin - len)
          ..lineTo(margin, size.height - margin)
          ..lineTo(margin + len, size.height - margin),
        bracketPaint,
      );
      // Правий нижній
      canvas.drawPath(
        Path()
          ..moveTo(size.width - margin - len, size.height - margin)
          ..lineTo(size.width - margin, size.height - margin)
          ..lineTo(size.width - margin, size.height - margin - len),
        bracketPaint,
      );
    }
  }

  void _drawDiamond(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OsnovaSplashPainter oldDelegate) {
    return oldDelegate.ambientValue != ambientValue ||
        oldDelegate.ringsProgress != ringsProgress ||
        oldDelegate.shockwaveProgress != shockwaveProgress ||
        oldDelegate.hudOpacity != hudOpacity;
  }
}