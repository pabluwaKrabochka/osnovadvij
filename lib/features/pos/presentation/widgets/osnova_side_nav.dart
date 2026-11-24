import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';

class OsnovaSideNav extends StatelessWidget {
  final VoidCallback onPurchasesTap;
  final VoidCallback onReceiptPreviewTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onXReportTap;
  final VoidCallback onYoutubeTap;
  final VoidCallback onSettingsTap;

  const OsnovaSideNav({
    super.key,
    required this.onPurchasesTap,
    required this.onReceiptPreviewTap,
    required this.onHistoryTap,
    required this.onExpenseTap,
    required this.onXReportTap,
    required this.onYoutubeTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.fromLTRB(12, 6, 0, 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: OsnovaTheme.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OsnovaTheme.gold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SideNavItem(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Каса',
                    isActive: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Закупки',
                    onTap: onPurchasesTap,
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Чек',
                    onTap: onReceiptPreviewTap,
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.history_rounded,
                    label: 'Журнал',
                    onTap: onHistoryTap,
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Витрата',
                    onTap: onExpenseTap,
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.analytics_outlined,
                    label: 'X-звіт',
                    onTap: onXReportTap,
                  ),
                  const SizedBox(height: 6),
                  _SideNavItem(
                    icon: Icons.play_circle_fill_rounded,
                    iconColor: const Color(0xFFFF0033),
                    label: 'YouTube',
                    onTap: onYoutubeTap,
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 16,
            color: OsnovaTheme.gold.withValues(alpha: 0.22),
          ),
          _SideNavItem(
            icon: Icons.settings_outlined,
            label: 'Принтер',
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isActive ? OsnovaTheme.goldBright : OsnovaTheme.gold);

    return Material(
      color: isActive
          ? OsnovaTheme.gold.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.5))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: effectiveIconColor),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive
                      ? OsnovaTheme.goldBright
                      : OsnovaTheme.creamText,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}