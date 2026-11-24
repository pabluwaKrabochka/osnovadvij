import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/presentation/pages/youtube_channel_page.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/pin_lock_dialog.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../controllers/pos_controller.dart';
import '../widgets/pos_dialogs.dart';
import 'pos_page.dart';

class IntroPage extends StatefulWidget {
  final PosController controller;

  const IntroPage({super.key, required this.controller});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  static const Duration _idleTimeout = Duration(seconds: 35);
  static const Duration _slideDuration = Duration(seconds: 6);

  static const List<_IdleSlideData> _idleSlides = [
    _IdleSlideData(
      icon: Icons.local_cafe_rounded,
      badge: 'КАВ’ЯРНЯ ТА ПРОСТІР',
      title: 'Ароматна кава та затишна атмосфера',
      subtitle: 'Класика, авторські холодні напої, десерти та улюблені ігри в одному місці',
    ),
    _IdleSlideData(
      icon: Icons.theater_comedy_rounded,
      badge: 'OSNOVA MAFIA CLUB',
      title: 'Спортивна Мафія та Школа Мафії',
      subtitle: 'Вечірні ігри, турніри, живі емоції та прокачка інтуїції за столом',
    ),
    _IdleSlideData(
      icon: Icons.sports_esports_rounded,
      badge: 'GAMING ZONE',
      title: 'PlayStation 5 • 100 грн / год',
      subtitle: 'Великий екран, зручні крісла та топові ігри для компанії друзів',
    ),
    _IdleSlideData(
      icon: Icons.casino_rounded,
      badge: 'НАСТІЛЬНІ ІГРИ ТА КВІЗИ',
      title: 'Ігрові вечори, квізи та літературний клуб',
      subtitle: 'Десятки настільних ігор, інтелектуальні батли та тематичні зустрічі',
    ),
    _IdleSlideData(
      icon: Icons.celebration_rounded,
      badge: 'ПОДІЇ ТА СВЯТА',
      title: 'Дні народження, вечірки та BBQ-вечори',
      subtitle: 'Організація свят під ключ для вашої компанії в самому серці міста',
    ),
  ];

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Контролери для атмосферного Idle-режиму
  late final AnimationController _idleAmbientCtrl;
  late final AnimationController _slideProgressCtrl;
  late final List<_IdleSpark> _sparks;

  Timer? _idleTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _isIdleMode = false;
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.initPos();

    final rng = math.Random(763);
    _sparks = List.generate(34, (i) {
      return _IdleSpark(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 1.1 + rng.nextDouble() * 2.3,
        speed: 0.08 + rng.nextDouble() * 0.22,
        drift: (rng.nextDouble() - 0.5) * 0.09,
        phase: rng.nextDouble() * math.pi * 2,
        isBright: i % 3 == 0,
      );
    });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _idleAmbientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _slideProgressCtrl = AnimationController(
      vsync: this,
      duration: _slideDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _isIdleMode && mounted) {
          setState(() {
            _currentSlideIndex = (_currentSlideIndex + 1) % _idleSlides.length;
          });
          _slideProgressCtrl.forward(from: 0.0);
        }
      });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _animCtrl.forward();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isIdleMode) return;
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted && !_isIdleMode) {
        _enterIdleMode();
      }
    });
  }

  void _enterIdleMode() {
    _idleTimer?.cancel();
    setState(() {
      _isIdleMode = true;
      _currentSlideIndex = 0;
    });
    _slideProgressCtrl.forward(from: 0.0);
  }

  void _exitIdleMode() {
    if (!_isIdleMode) {
      _resetIdleTimer();
      return;
    }
    _slideProgressCtrl.stop();
    setState(() {
      _isIdleMode = false;
    });
    _resetIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _clockTimer?.cancel();
    _animCtrl.dispose();
    _idleAmbientCtrl.dispose();
    _slideProgressCtrl.dispose();
    super.dispose();
  }

  void _openFullscreenPoster() {
    _resetIdleTimer();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/CityLight.JPG',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: OsnovaTheme.bgDark.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(Icons.close, color: OsnovaTheme.gold),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _resetIdleTimer());
  }

  Future<void> _enterPos() async {
    _idleTimer?.cancel();
    final unlocked = await PinLockDialog.show(context, requiredPin: '9375');
    if (!unlocked || !mounted) {
      _resetIdleTimer();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => PosPage(controller: widget.controller),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _formattedTime() {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formattedDateUa() {
    const months = [
      'січня',
      'лютого',
      'березня',
      'квітня',
      'травня',
      'червня',
      'липня',
      'серпня',
      'вересня',
      'жовтня',
      'листопада',
      'грудня',
    ];
    const weekdays = [
      'Понеділок',
      'Вівторок',
      'Середа',
      'Четвер',
      'П’ятниця',
      'Субота',
      'Неділя',
    ];
    return '${weekdays[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cashText =
            MoneyFormatter.format(widget.controller.currentCashInDrawer);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_isIdleMode) {
              _resetIdleTimer();
            }
          },
          child: Scaffold(
            backgroundColor: OsnovaTheme.bgDark,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 650),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isIdleMode
                  ? _buildIdleShowcase()
                  : _buildActiveIntro(cashText),
            ),
          ),
        );
      },
    );
  }

  // ==================== АКТИВНИЙ ЕКРАН ВХОДУ ====================
  Widget _buildActiveIntro(String cashText) {
    return SafeArea(
      key: const ValueKey('active_intro'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Ліва половина: CityLight афіша зі світловою рамкою та зумом QR
            Expanded(
              flex: 46,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: _openFullscreenPoster,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: OsnovaTheme.gold.withValues(alpha: 0.65),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OsnovaTheme.gold.withValues(alpha: 0.16),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/CityLight.JPG',
                            fit: BoxFit.fill,
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 16,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Натисніть для QR та збільшення',
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 28),

            // Права половина: Брендинг, локації простору та вхід у касу
            Expanded(
              flex: 54,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.6),
                                width: 1.4,
                              ),
                            ),
                            child: const Text(
                              'OSNOVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.5,
                              ),
                            ),
                          ),

                          // Кнопка миттєвого запуску красивої вітрини / Idle-режиму
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: OsnovaTheme.surfaceCard,
                              foregroundColor: OsnovaTheme.goldBright,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _enterIdleMode,
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: OsnovaTheme.goldBright,
                            ),
                            label: const Text(
                              'Idle-вітрина',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Простір ігор, кави та подій',
                        style: TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: OsnovaTheme.sageMuted,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Кропивницький • вул. Арсенія Тарковського, 76/3',
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Напрямки з CityLight
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HighlightChip(
                            icon: Icons.theater_comedy_rounded,
                            label: 'Школа Мафії',
                          ),
                          _HighlightChip(
                            icon: Icons.sports_esports_rounded,
                            label: 'PlayStation 5 • 100 грн/год',
                          ),
                          _HighlightChip(
                            icon: Icons.casino_rounded,
                            label: 'Настільні ігри',
                          ),
                          _HighlightChip(
                            icon: Icons.menu_book_rounded,
                            label: 'Літературний клуб',
                          ),
                          _HighlightChip(
                            icon: Icons.celebration_rounded,
                            label: 'Свята та BBQ-вечори',
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Швидка перевірка готівки в касі перед роботою
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OsnovaTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Готівка в касі на старті',
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cashText,
                                  style: const TextStyle(
                                    color: OsnovaTheme.creamText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                _idleTimer?.cancel();
                                final unlocked = await PinLockDialog.show(
                                  context,
                                  requiredPin: '9375',
                                );
                                if (unlocked && context.mounted) {
                                  await PosDialogs.showEditCashDialog(
                                    context,
                                    widget.controller,
                                  );
                                }
                                _resetIdleTimer();
                              },
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: OsnovaTheme.gold,
                              ),
                              label: const Text('Вказати розмін'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            flex: 65,
                            child: SizedBox(
                              height: 58,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: OsnovaTheme.gold,
                                  foregroundColor: OsnovaTheme.bgDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _enterPos,
                                icon: const Icon(
                                  Icons.point_of_sale_rounded,
                                  size: 24,
                                ),
                                label: const Text(
                                  'ПЕРЕЙТИ ДО КАСИ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 35,
                            child: SizedBox(
                              height: 58,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: OsnovaTheme.surfaceCard,
                                  foregroundColor: OsnovaTheme.creamText,
                                  side: BorderSide(
                                    color:
                                        OsnovaTheme.gold.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  _idleTimer?.cancel();
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const YoutubeChannelPage(),
                                        ),
                                      )
                                      .then((_) => _resetIdleTimer());
                                },
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Color(0xFFFF0033),
                                  size: 24,
                                ),
                                label: const Text(
                                  'YouTube',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== КІНЕМАТОГРАФІЧНИЙ IDLE-РЕЖИМ ====================
  Widget _buildIdleShowcase() {
    final activeSlide = _idleSlides[_currentSlideIndex];

    return GestureDetector(
      key: const ValueKey('idle_showcase'),
      behavior: HitTestBehavior.opaque,
      onTap: _exitIdleMode,
      onPanDown: (_) => _exitIdleMode(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Живий Canvas-фон з астролябією, іскрами та світловим диханням
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _idleAmbientCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _IdleAmbientPainter(
                    ambientValue: _idleAmbientCtrl.value,
                    sparks: _sparks,
                  ),
                );
              },
            ),
          ),

          // 2. Основний контент вітрини
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 22, 32, 22),
              child: Column(
                children: [
                  // Верхній статус-бар з годинником та брендом
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    OsnovaTheme.goldBright.withValues(alpha: 0.7),
                                width: 1.4,
                              ),
                            ),
                            child: const Text(
                              'OSNOVA',
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                                letterSpacing: 3.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  OsnovaTheme.surfaceCard.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.liveGreen
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: OsnovaTheme.liveGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: OsnovaTheme.liveGreen
                                            .withValues(alpha: 0.8),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ПРОСТІР ВІДЧИНЕНО',
                                  style: TextStyle(
                                    color: OsnovaTheme.creamText,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Великий естетичний годинник
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formattedTime(),
                            style: const TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formattedDateUa(),
                            style: const TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Центральна композиція: Левітуюча афіша зліва + Слайдер подій справа
                  Expanded(
                    child: Row(
                      children: [
                        // Левітуючий постер CityLight з плавним масштабуванням
                        Expanded(
                          flex: 42,
                          child: AnimatedBuilder(
                            animation: _idleAmbientCtrl,
                            builder: (context, child) {
                              final angle =
                                  _idleAmbientCtrl.value * 2 * math.pi;
                              final floatY = math.sin(angle * 2) * 6.0;
                              final scale =
                                  1.0 + 0.018 * math.cos(angle * 2);

                              return Transform.translate(
                                offset: Offset(0, floatY),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: OsnovaTheme.goldBright
                                      .withValues(alpha: 0.75),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        OsnovaTheme.gold.withValues(alpha: 0.28),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  'assets/CityLight.JPG',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 34),

                        // Права частина: Анімована презентація напрямків простору
                        Expanded(
                          flex: 58,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 550),
                                transitionBuilder: (child, animation) {
                                  final curved = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  );
                                  return FadeTransition(
                                    opacity: curved,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.08),
                                        end: Offset.zero,
                                      ).animate(curved),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey(_currentSlideIndex),
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        OsnovaTheme.surfaceCard
                                            .withValues(alpha: 0.92),
                                        const Color(0xFF0A1D15)
                                            .withValues(alpha: 0.95),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.42),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.42),
                                        blurRadius: 26,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  OsnovaTheme.goldGradient,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              activeSlide.icon,
                                              color: OsnovaTheme.bgDark,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OsnovaTheme.gold
                                                  .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: OsnovaTheme.gold
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              activeSlide.badge,
                                              style: const TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 22),
                                      Text(
                                        activeSlide.title,
                                        style: const TextStyle(
                                          color: OsnovaTheme.creamText,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        activeSlide.subtitle,
                                        style: const TextStyle(
                                          color: OsnovaTheme.sageMuted,
                                          fontSize: 16,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Індикатори слайдів із живим заповненням
                              AnimatedBuilder(
                                animation: _slideProgressCtrl,
                                builder: (context, _) {
                                  return Row(
                                    children: List.generate(
                                      _idleSlides.length,
                                      (idx) {
                                        final isCurrent =
                                            idx == _currentSlideIndex;
                                        final isPast =
                                            idx < _currentSlideIndex;
                                        return Expanded(
                                          child: Container(
                                            height: 4,
                                            margin: EdgeInsets.only(
                                              right:
                                                  idx == _idleSlides.length - 1
                                                      ? 0
                                                      : 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OsnovaTheme.surfaceCard,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: isPast
                                                  ? 1.0
                                                  : isCurrent
                                                      ? _slideProgressCtrl.value
                                                      : 0.0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      OsnovaTheme.goldGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Нижня підказка виходу з Idle-режиму + адреса
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: OsnovaTheme.surfaceCard.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: OsnovaTheme.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: OsnovaTheme.gold,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Кропивницький • вул. Арсенія Тарковського, 76/3',
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        AnimatedBuilder(
                          animation: _idleAmbientCtrl,
                          builder: (context, _) {
                            final pulse = 0.55 +
                                0.45 *
                                    math.sin(
                                      _idleAmbientCtrl.value * 4 * math.pi,
                                    );
                            return Opacity(
                              opacity: pulse,
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 18,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Торкніться екрана для керування касою',
                                    style: TextStyle(
                                      color: OsnovaTheme.goldBright,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleSlideData {
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;

  const _IdleSlideData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
  });
}

class _IdleSpark {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
  final bool isBright;

  const _IdleSpark({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.isBright,
  });
}

class _IdleAmbientPainter extends CustomPainter {
  final double ambientValue;
  final List<_IdleSpark> sparks;

  _IdleAmbientPainter({
    required this.ambientValue,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.65, size.height * 0.5);
    final angle = ambientValue * 2 * math.pi;

    // 1. Глибокий смарагдово-золотий радіальний фон
    final bgGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.25, 0.0),
        radius: 1.15,
        colors: [
          OsnovaTheme.gold.withValues(alpha: 0.14),
          const Color(0xFF133326).withValues(alpha: 0.55),
          OsnovaTheme.bgDark,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgGlow);

    // 2. Обертові орбітальні кільця позаду правого блоку
    final ringPaint = Paint()
      ..color = OsnovaTheme.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 250, ringPaint);

    final dashPaint = Paint()
      ..color = OsnovaTheme.sageMuted.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashCount = 32;
    const dashStep = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 315),
        i * dashStep + angle * 0.25,
        dashStep * 0.45,
        false,
        dashPaint,
      );
    }

    // 3. Золоті іскри, що плавно піднімаються вгору
    for (final s in sparks) {
      final rawY = (s.y - ambientValue * s.speed) % 1.0;
      final y = rawY < 0 ? rawY + 1.0 : rawY;
      final x = (s.x + math.sin(angle + s.phase) * s.drift) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(angle * 3 + s.phase));

      final paint = Paint()
        ..color = (s.isBright ? OsnovaTheme.goldBright : OsnovaTheme.gold)
            .withValues(alpha: 0.42 * twinkle);
      canvas.drawCircle(Offset(x * size.width, y * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IdleAmbientPainter oldDelegate) {
    return oldDelegate.ambientValue != ambientValue;
  }
}

class _HighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HighlightChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: OsnovaTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: OsnovaTheme.gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: OsnovaTheme.creamText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}