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
    final isNeon = OsnovaTheme.isNeon;

    final logoShape = OsnovaTheme.adaptiveShape(
      radius: 10,
      bevel: 7,
      side: BorderSide(
        color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
            .withValues(alpha: isNeon ? 0.85 : 0.65),
        width: isNeon ? 1.4 : 1.2,
      ),
    );

    final badgeShape = OsnovaTheme.adaptiveShape(
      radius: 20,
      bevel: 7,
      side: BorderSide(
        color: OsnovaTheme.gold.withValues(alpha: 0.45),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onLogoTap,
          customBorder: logoShape,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              shape: logoShape,
              color: OsnovaTheme.bgDeep,
              shadows: isNeon
                  ? [
                      BoxShadow(
                        color: OsnovaTheme.neonGlow.withValues(alpha: 0.30),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              'OSNOVA',
              style: TextStyle(
                color: isNeon ? OsnovaTheme.goldBright : OsnovaTheme.creamText,
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
            customBorder: badgeShape,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                shape: badgeShape,
                color: OsnovaTheme.surfaceCard.withValues(alpha: 0.85),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
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
                      style: TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        fontFeatures: OsnovaTheme.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
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
            customBorder: badgeShape,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                shape: OsnovaTheme.adaptiveShape(
                  radius: 20,
                  bevel: 7,
                  side: BorderSide(
                    color: hasPrinter
                        ? OsnovaTheme.liveGreen.withValues(alpha: 0.5)
                        : OsnovaTheme.sageMuted.withValues(alpha: 0.25),
                  ),
                ),
                color: OsnovaTheme.surfaceCard.withValues(alpha: 0.72),
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
                        fontFeatures: OsnovaTheme.tabularFigures,
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