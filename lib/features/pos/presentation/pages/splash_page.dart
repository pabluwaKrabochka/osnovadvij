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

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.32, 0.65, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.32, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    _mainCtrl.forward();

    // Паралельно чекаємо завершення анімації та ініціалізації SQLite
    await Future.wait([
      _mainCtrl.forward().orCancel.catchError((_) {}),
      widget.controller.initPos(),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => IntroPage(controller: widget.controller),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
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
            // Фонове радіальне золоте сяйво та декоративні кільця
            AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (context, _) {
                final angle = _ambientCtrl.value * 2 * math.pi;
                final pulse = 0.85 + 0.15 * math.sin(angle);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 440 * pulse,
                      height: 440 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            OsnovaTheme.gold.withValues(alpha: 0.14),
                            OsnovaTheme.surfaceElevated.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: angle * 0.25,
                      child: Container(
                        width: 310,
                        height: 310,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -angle * 0.35,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48),
                          border: Border.all(
                            color: OsnovaTheme.sageMuted.withValues(alpha: 0.09),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Центральний логотип OSNOVA + назва простору + індикатор завантаження
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.75),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: OsnovaTheme.gold.withValues(alpha: 0.24),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Text(
                        'OSNOVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 7.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: Column(
                      children: [
                        const Text(
                          'ПРОСТІР ІГОР, КАВИ ТА ПОДІЙ',
                          style: TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'КРОПИВНИЦЬКИЙ • POS SYSTEM',
                          style: TextStyle(
                            color: OsnovaTheme.sageMuted.withValues(alpha: 0.8),
                            fontSize: 12,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Тонка золота лінія прогресу
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    return Container(
                      width: 220,
                      height: 3,
                      decoration: BoxDecoration(
                        color: OsnovaTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressAnim.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [OsnovaTheme.gold, OsnovaTheme.goldBright],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: OsnovaTheme.gold.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
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