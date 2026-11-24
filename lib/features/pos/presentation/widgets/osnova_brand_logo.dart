import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';

class OsnovaBrandLogo extends StatelessWidget {
  final int cashInDrawer;
  final String? printerIp;
  final VoidCallback onEditCashTap;
  final VoidCallback onPrinterTap;
  final VoidCallback onLogoTap;

  const OsnovaBrandLogo({
    super.key,
    required this.cashInDrawer,
    required this.printerIp,
    required this.onEditCashTap,
    required this.onPrinterTap,
    required this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrinter = printerIp != null && printerIp!.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onLogoTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OsnovaTheme.bgDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: OsnovaTheme.gold.withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: const Text(
              'OSNOVA',
              style: TextStyle(
                color: OsnovaTheme.creamText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: InkWell(
            onTap: onEditCashTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: OsnovaTheme.surfaceCard.withValues(alpha: 0.85),
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
                    size: 14,
                    color: OsnovaTheme.gold,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Каса: ${MoneyFormatter.format(cashInDrawer)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: OsnovaTheme.sageMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: InkWell(
            onTap: onPrinterTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: OsnovaTheme.surfaceCard.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasPrinter
                      ? OsnovaTheme.liveGreen.withValues(alpha: 0.5)
                      : OsnovaTheme.sageMuted.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasPrinter
                        ? Icons.print_rounded
                        : Icons.print_disabled_outlined,
                    size: 14,
                    color: hasPrinter
                        ? OsnovaTheme.liveGreen
                        : OsnovaTheme.sageMuted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      hasPrinter ? printerIp! : 'Принтер не підключено',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasPrinter
                            ? OsnovaTheme.creamText
                            : OsnovaTheme.sageMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}