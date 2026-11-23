import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';

class OsnovaBrandLogo extends StatelessWidget {
  final int cashInDrawer;
  final String? printerIp;
  final VoidCallback onEditCashTap;
  final VoidCallback onLogoTap;
  final VoidCallback onPrinterTap;

  const OsnovaBrandLogo({
    super.key,
    required this.cashInDrawer,
    required this.printerIp,
    required this.onEditCashTap,
    required this.onLogoTap,
    required this.onPrinterTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrinterConnected = printerIp != null && printerIp!.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onLogoTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: OsnovaTheme.gold.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: OsnovaTheme.gold.withValues(alpha: 0.16),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'OSNOVA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Бейдж балансу каси
        InkWell(
          onTap: onEditCashTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: OsnovaTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: OsnovaTheme.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: OsnovaTheme.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  'Каса: ${MoneyFormatter.format(cashInDrawer)}',
                  style: const TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: OsnovaTheme.sageMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Індикатор статусу підключення Xprinter
        InkWell(
          onTap: onPrinterTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: isPrinterConnected
                  ? const Color(0xFF133326)
                  : OsnovaTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrinterConnected
                    ? OsnovaTheme.liveGreen.withValues(alpha: 0.55)
                    : OsnovaTheme.sageMuted.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPrinterConnected)
                  const LiveShiftBadge(color: OsnovaTheme.liveGreen)
                else
                  Icon(
                    Icons.print_disabled_rounded,
                    size: 14,
                    color: OsnovaTheme.sageMuted.withValues(alpha: 0.75),
                  ),
                const SizedBox(width: 7),
                Text(
                  isPrinterConnected ? 'Xprinter • $printerIp' : 'Принтер офлайн',
                  style: TextStyle(
                    color: isPrinterConnected
                        ? OsnovaTheme.creamText
                        : OsnovaTheme.sageMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LiveShiftBadge extends StatefulWidget {
  final Color color;

  const LiveShiftBadge({super.key, this.color = OsnovaTheme.liveGreen});

  @override
  State<LiveShiftBadge> createState() => _LiveShiftBadgeState();
}

class _LiveShiftBadgeState extends State<LiveShiftBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + 0.45 * _ctrl.value),
                blurRadius: 4 + 6 * _ctrl.value,
                spreadRadius: 1 + 1.5 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}