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

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    widget.controller.initPos();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openFullscreenPoster() {
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
    );
  }

 Future<void> _enterPos() async {
    final unlocked = await PinLockDialog.show(context, requiredPin: '9375');
    if (!unlocked || !mounted) return;

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
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cashText = MoneyFormatter.format(widget.controller.currentCashInDrawer);

        return Scaffold(
          backgroundColor: OsnovaTheme.bgDark,
          body: SafeArea(
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
                                        color: OsnovaTheme.gold.withValues(alpha: 0.5),
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
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: const [
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
                                      final unlocked = await PinLockDialog.show(
                                        context,
                                        requiredPin: '9375',
                                      );
                                      if (unlocked && context.mounted) {
                                        PosDialogs.showEditCashDialog(
                                          context,
                                          widget.controller,
                                        );
                                      }
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
                                      icon: const Icon(Icons.point_of_sale_rounded, size: 24),
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
                                          color: OsnovaTheme.gold.withValues(alpha: 0.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const YoutubeChannelPage(),
                                          ),
                                        );
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
          ),
        );
      },
    );
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