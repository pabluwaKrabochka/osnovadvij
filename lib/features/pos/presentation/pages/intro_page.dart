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
      subtitle:
          'Класика, авторські холодні напої, десерти та улюблені ігри в одному місці',
      accentTag: 'Кава • Чай • Какао • Снеки',
    ),
    _IdleSlideData(
      icon: Icons.theater_comedy_rounded,
      badge: 'OSNOVA MAFIA CLUB',
      title: 'Спортивна Мафія та Школа Мафії',
      subtitle:
          'Вечірні ігри, турніри, живі емоції та прокачка інтуїції за столом',
      accentTag: 'Класика iMafia • Турніри',
    ),
    _IdleSlideData(
      icon: Icons.sports_esports_rounded,
      badge: 'GAMING ZONE',
      title: 'PlayStation 5 • 100 грн / год',
      subtitle:
          'Великий екран, зручні крісла та топові ігри для компанії друзів',
      accentTag: '4K екран • 2 геймпади',
    ),
    _IdleSlideData(
      icon: Icons.casino_rounded,
      badge: 'НАСТІЛЬНІ ІГРИ ТА КВІЗИ',
      title: 'Ігрові вечори, квізи та літературний клуб',
      subtitle:
          'Десятки настільних ігор, інтелектуальні батли та тематичні зустрічі',
      accentTag: 'Dixit • Alias • Бункер • Квізи',
    ),
    _IdleSlideData(
      icon: Icons.celebration_rounded,
      badge: 'ПОДІЇ ТА СВЯТА',
      title: 'Дні народження, вечірки та BBQ-вечори',
      subtitle:
          'Організація свят під ключ для вашої компанії в самому серці міста',
      accentTag: 'Бронювання простору • Ведучі',
    ),
  ];

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _ambientCtrl;
  late final AnimationController _slideProgressCtrl;
  late final List<_AmbientSpark> _sparks;

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
    _sparks = List.generate(36, (i) {
      return _AmbientSpark(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 1.1 + rng.nextDouble() * 2.2,
        speed: 0.06 + rng.nextDouble() * 0.18,
        drift: (rng.nextDouble() - 0.5) * 0.08,
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
      begin: const Offset(0.035, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
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
    _ambientCtrl.dispose();
    _slideProgressCtrl.dispose();
    super.dispose();
  }

  void _openFullscreenPoster() {
    _resetIdleTimer();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF081410),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: OsnovaTheme.gold.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1D15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: OsnovaTheme.gold.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: OsnovaTheme.goldBright,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'АФІША OSNOVA • НАБЛИЖЕННЯ ДЛЯ QR-КОДІВ',
                        style: TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: OsnovaTheme.creamText,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/CityLight.JPG',
                      fit: BoxFit.contain,
                    ),
                  ),
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
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Єдиний преміальний живий фон із золотими іскрами та орбітами
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _ambientCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _OsnovaAmbientPainter(
                          ambientValue: _ambientCtrl.value,
                          sparks: _sparks,
                          isIdleMode: _isIdleMode,
                        ),
                      );
                    },
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 650),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _isIdleMode
                      ? _buildIdleShowcase()
                      : _buildActiveIntro(cashText),
                ),
              ],
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ЛІВА ПАНЕЛЬ: Галерейна рамка CityLight з інтерактивним QR-зумом
            Expanded(
              flex: 45,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: _openFullscreenPoster,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A3C2E),
                          Color(0xFF0A1914),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: OsnovaTheme.goldBright.withValues(alpha: 0.65),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OsnovaTheme.gold.withValues(alpha: 0.16),
                          blurRadius: 30,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/CityLight.JPG',
                            fit: BoxFit.fill,
                          ),
                          // Верхній бейдж афіші
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1914)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'АФІША ПРОСТОРУ',
                                    style: TextStyle(
                                      color: OsnovaTheme.goldBright,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Нижня скляна панель підказки QR
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1914)
                                    .withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: OsnovaTheme.goldBright
                                      .withValues(alpha: 0.48),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Натисніть для QR-кодів та збільшення',
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    size: 16,
                                    color: OsnovaTheme.gold,
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

            const SizedBox(width: 26),

            // ПРАВА ПАНЕЛЬ: Командний центр OSNOVA POS
            Expanded(
              flex: 55,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. Верхня статусна панель: Логотип + Годинник + Idle-вітрина
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF143126), Color(0xFF091611)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: OsnovaTheme.goldBright
                                    .withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.14),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'OSNOVA',
                                  style: TextStyle(
                                    color: OsnovaTheme.creamText,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Компактний годинник зміни
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF11261F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formattedTime(),
                                  style: TextStyle(
                                    color: OsnovaTheme.goldBright,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formattedDateUa(),
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF11261F),
                              foregroundColor: OsnovaTheme.goldBright,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            onPressed: _enterIdleMode,
                            icon: Icon(
                              Icons.auto_awesome_rounded,
                              size: 17,
                              color: OsnovaTheme.goldBright,
                            ),
                            label: const Text(
                              'Idle-вітрина',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 2. Заголовок та локація
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  OsnovaTheme.liveGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.liveGreen
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: OsnovaTheme.liveGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ТЕРМІНАЛ БАРИСТИ ТА АДМІНІСТРАТОРА',
                                  style: TextStyle(
                                    color: OsnovaTheme.liveGreen,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Простір ігор, кави та подій',
                            style: TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 17,
                                color: OsnovaTheme.gold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Кропивницький • вул. Арсенія Тарковського, 76/3',
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 3. Напрямки клубу
                      const Wrap(
                        spacing: 9,
                        runSpacing: 9,
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

                      // 4. Hero KPI-картка готівки в касі (в єдиному стилі з PurchasesPage)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF143126),
                              Color(0xFF0A1914),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 90,
                              top: -10,
                              child: Icon(
                                Icons.payments_outlined,
                                size: 68,
                                color: OsnovaTheme.gold.withValues(alpha: 0.07),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: OsnovaTheme.goldBright,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'ГОТІВКА В КАСІ НА СТАРТІ ЗМІНИ',
                                          style: TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.9,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cashText,
                                      style: TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFF11261F),
                                    foregroundColor: OsnovaTheme.creamText,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.42),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  label: const Text(
                                    'Вказати розмін',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 5. Головні кнопки входу в систему
                      Row(
                        children: [
                          Expanded(
                            flex: 65,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: OsnovaTheme.goldGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: OsnovaTheme.gold
                                        .withValues(alpha: 0.32),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _enterPos,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.point_of_sale_rounded,
                                        size: 24,
                                        color: OsnovaTheme.bgDark,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'ПЕРЕЙТИ ДО КАСИ',
                                        style: TextStyle(
                                          color: OsnovaTheme.bgDark,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: OsnovaTheme.bgDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 35,
                            child: SizedBox(
                              height: 60,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFF11261F),
                                  foregroundColor: OsnovaTheme.creamText,
                                  side: BorderSide(
                                    color:
                                        OsnovaTheme.gold.withValues(alpha: 0.45),
                                    width: 1.2,
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
                                          builder: (_) => YoutubeChannelPage(),
                                        ),
                                      )
                                      .then((_) => _resetIdleTimer());
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF0033)
                                        .withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Color(0xFFFF0033),
                                    size: 20,
                                  ),
                                ),
                                label: const Text(
                                  'YouTube',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
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
      child: SafeArea(
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF143126), Color(0xFF091611)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OsnovaTheme.goldBright.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                        ),
                        child: Text(
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
                          color: const Color(0xFF11261F).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: OsnovaTheme.liveGreen.withValues(alpha: 0.5),
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
                            Text(
                              'ПРОСТІР ВІДЧИНЕНО',
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
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
                        style: TextStyle(
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
                        style: TextStyle(
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
                        animation: _ambientCtrl,
                        builder: (context, child) {
                          final angle = _ambientCtrl.value * 2 * math.pi;
                          final floatY = math.sin(angle * 2) * 6.0;
                          final scale = 1.0 + 0.016 * math.cos(angle * 2);

                          return Transform.translate(
                            offset: Offset(0, floatY),
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A3C2E), Color(0xFF0A1914)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  OsnovaTheme.goldBright.withValues(alpha: 0.78),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OsnovaTheme.gold.withValues(alpha: 0.28),
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
                            borderRadius: BorderRadius.circular(18),
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
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF143126),
                                    Color(0xFF0A1914),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.48),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    blurRadius: 26,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -10,
                                    bottom: -14,
                                    child: Icon(
                                      activeSlide.icon,
                                      size: 112,
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.07),
                                    ),
                                  ),
                                  Column(
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
                                              color: const Color(0xFF0A1914),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: OsnovaTheme.gold
                                                    .withValues(alpha: 0.45),
                                              ),
                                            ),
                                            child: Text(
                                              activeSlide.badge,
                                              style: TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        activeSlide.title,
                                        style: TextStyle(
                                          color: OsnovaTheme.creamText,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        activeSlide.subtitle,
                                        style: TextStyle(
                                          color: OsnovaTheme.sageMuted,
                                          fontSize: 16,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11261F),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          activeSlide.accentTag,
                                          style: TextStyle(
                                            color: OsnovaTheme.goldBright,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                    final isPast = idx < _currentSlideIndex;
                                    return Expanded(
                                      child: Container(
                                        height: 4.5,
                                        margin: EdgeInsets.only(
                                          right: idx == _idleSlides.length - 1
                                              ? 0
                                              : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11261F),
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
                  color: const Color(0xFF11261F).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: OsnovaTheme.gold.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: OsnovaTheme.goldBright,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Кропивницький • вул. Арсенія Тарковського, 76/3',
                          style: TextStyle(
                            color: OsnovaTheme.creamText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    AnimatedBuilder(
                      animation: _ambientCtrl,
                      builder: (context, _) {
                        final pulse = 0.55 +
                            0.45 * math.sin(_ambientCtrl.value * 4 * math.pi);
                        return Opacity(
                          opacity: pulse,
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 18,
                                color: OsnovaTheme.goldBright,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Торкніться екрана для керування касою',
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
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
    );
  }
}

class _IdleSlideData {
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final String accentTag;

  const _IdleSlideData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accentTag,
  });
}

class _AmbientSpark {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
  final bool isBright;

  const _AmbientSpark({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.isBright,
  });
}

class _OsnovaAmbientPainter extends CustomPainter {
  final double ambientValue;
  final List<_AmbientSpark> sparks;
  final bool isIdleMode;

  _OsnovaAmbientPainter({
    required this.ambientValue,
    required this.sparks,
    required this.isIdleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.68, size.height * 0.5);
    final angle = ambientValue * 2 * math.pi;

    // 1. Глибокий смарагдово-золотий радіальний фон на обох екранах
    final bgGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.28, -0.05),
        radius: 1.2,
        colors: [
          OsnovaTheme.gold.withValues(alpha: isIdleMode ? 0.15 : 0.09),
          const Color(0xFF133326).withValues(alpha: isIdleMode ? 0.58 : 0.42),
          OsnovaTheme.bgDark,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgGlow);

    // 2. Тонкі орбітальні кільця (виразніші в Idle-режимі, делікатні в активному)
    final ringAlpha = isIdleMode ? 0.13 : 0.06;
    final ringPaint = Paint()
      ..color = OsnovaTheme.gold.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 250, ringPaint);

    final dashPaint = Paint()
      ..color = OsnovaTheme.sageMuted.withValues(alpha: ringAlpha)
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
    final sparkOpacityScale = isIdleMode ? 0.44 : 0.24;
    for (final s in sparks) {
      final rawY = (s.y - ambientValue * s.speed) % 1.0;
      final y = rawY < 0 ? rawY + 1.0 : rawY;
      final x = (s.x + math.sin(angle + s.phase) * s.drift) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(angle * 3 + s.phase));

      final paint = Paint()
        ..color = (s.isBright ? OsnovaTheme.goldBright : OsnovaTheme.gold)
            .withValues(alpha: sparkOpacityScale * twinkle);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OsnovaAmbientPainter oldDelegate) {
    return oldDelegate.ambientValue != ambientValue ||
        oldDelegate.isIdleMode != isIdleMode;
  }
}

class _HighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HighlightChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11261F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1914),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: OsnovaTheme.goldBright),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: OsnovaTheme.creamText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}