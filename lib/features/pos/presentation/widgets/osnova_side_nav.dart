import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../controllers/pos_controller.dart';
import 'osnova_toast.dart';

class OsnovaSideNav extends StatefulWidget {
  final VoidCallback onCashOpsTap;
  final VoidCallback onPurchasesTap;
  final VoidCallback onReceiptPreviewTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onXReportTap;
  final VoidCallback onAbcTap;
  final VoidCallback onTelegramTap;
  final VoidCallback onYoutubeTap;
  final VoidCallback onSettingsTap;
  final VoidCallback? onThemeTap;

  const OsnovaSideNav({
    super.key,
    required this.onCashOpsTap,
    required this.onPurchasesTap,
    required this.onReceiptPreviewTap,
    required this.onHistoryTap,
    required this.onXReportTap,
    required this.onAbcTap,
    required this.onTelegramTap,
    required this.onYoutubeTap,
    required this.onSettingsTap,
    this.onThemeTap,
  });

  @override
  State<OsnovaSideNav> createState() => _OsnovaSideNavState();
}

class _OsnovaSideNavState extends State<OsnovaSideNav> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = OsnovaTheme.isNeon;
    final items = <_NavToolItem>[
      _NavToolItem(
        label: 'Каса',
        icon: Icons.point_of_sale_rounded,
        accentColor: OsnovaTheme.goldBright,
        isActive: true,
        onTap: () {},
      ),
      _NavToolItem(
        label: 'Каса ±',
        icon: Icons.swap_vert_rounded,
        accentColor: OsnovaTheme.liveGreen,
        onTap: widget.onCashOpsTap,
      ),
      _NavToolItem(
        label: 'Закупки',
        icon: Icons.inventory_2_outlined,
        accentColor: const Color(0xFFF59E0B),
        onTap: widget.onPurchasesTap,
      ),
      _NavToolItem(
        label: 'Чек',
        icon: Icons.receipt_long_rounded,
        accentColor: OsnovaTheme.gold,
        onTap: widget.onReceiptPreviewTap,
      ),
      _NavToolItem(
        label: 'Журнал',
        icon: Icons.history_rounded,
        accentColor: OsnovaTheme.sageMuted,
        onTap: widget.onHistoryTap,
      ),
      _NavToolItem(
        label: 'X-звіт',
        icon: Icons.analytics_outlined,
        accentColor: OsnovaTheme.goldBright,
        onTap: widget.onXReportTap,
      ),
      _NavToolItem(
        label: 'ABC',
        icon: Icons.bar_chart_rounded,
        accentColor: const Color(0xFF34D399),
        onTap: widget.onAbcTap,
      ),
      _NavToolItem(
        label: 'ТГ Події',
        icon: Icons.campaign_rounded,
        accentColor: const Color(0xFF38BDF8),
        onTap: widget.onTelegramTap,
      ),
      _NavToolItem(
        label: 'YouTube',
        icon: Icons.play_circle_fill_rounded,
        accentColor: const Color(0xFFF87171),
        onTap: widget.onYoutubeTap,
      ),
      _NavToolItem(
        label: 'Тема',
        icon: OsnovaTheme.current.icon,
        accentColor: isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright,
        showPulseDot: true,
        onTap: widget.onThemeTap ??
            () => OsnovaThemePickerDialog.show(context),
      ),
      _NavToolItem(
        label: 'Принтер',
        icon: Icons.settings_rounded,
        accentColor: OsnovaTheme.gold,
        onTap: widget.onSettingsTap,
      ),
    ];

    return Container(
      width: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OsnovaTheme.bgDeep,
            OsnovaTheme.surfaceCard,
            OsnovaTheme.bgDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
              .withValues(alpha: isNeon ? 0.68 : 0.42),
          width: isNeon ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                .withValues(alpha: isNeon ? 0.24 : 0.08),
            blurRadius: isNeon ? 18 : 14,
            spreadRadius: isNeon ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 9, bottom: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                        .withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 1,
                    color: OsnovaTheme.gold.withValues(alpha: 0.45),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      isNeon ? Icons.bolt_rounded : Icons.diamond_outlined,
                      size: 12,
                      color: OsnovaTheme.goldBright,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 1,
                    color: OsnovaTheme.gold.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  setState(() {});
                  return false;
                },
                child: RawScrollbar(
                  controller: _scrollCtrl,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 4,
                  radius: const Radius.circular(6),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2.5,
                  ),
                  thumbColor: OsnovaTheme.goldBright.withValues(alpha: 0.85),
                  trackColor: OsnovaTheme.bgDeep.withValues(alpha: 0.85),
                  trackBorderColor: OsnovaTheme.gold.withValues(alpha: 0.25),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(7, 2, 9, 10),
                    itemCount: items.length,
                    separatorBuilder: (_, index) {
                      if (index == 0 || index == items.length - 3) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  OsnovaTheme.gold.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox(height: 6);
                    },
                    itemBuilder: (_, i) => _SideNavTile(item: items[i]),
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

class _NavToolItem {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final bool showPulseDot;
  final VoidCallback onTap;

  const _NavToolItem({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isActive = false,
    this.showPulseDot = false,
    required this.onTap,
  });
}

class _SideNavTile extends StatefulWidget {
  final _NavToolItem item;

  const _SideNavTile({required this.item});

  @override
  State<_SideNavTile> createState() => _SideNavTileState();
}

class _SideNavTileState extends State<_SideNavTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final active = item.isActive;
    final highlighted = active || _hovered;
    final isNeon = OsnovaTheme.isNeon;

    final scale = _pressed
        ? 0.93
        : _hovered
            ? 1.04
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          item.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: active
                  ? OsnovaTheme.cardActiveGradient
                  : _hovered
                      ? OsnovaTheme.cardGradient
                      : null,
              color: highlighted
                  ? null
                  : OsnovaTheme.bgDeep.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright)
                    : _hovered
                        ? OsnovaTheme.gold.withValues(alpha: 0.72)
                        : OsnovaTheme.gold
                            .withValues(alpha: isNeon ? 0.28 : 0.16),
                width: active ? 1.4 : 1.0,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (isNeon
                                ? OsnovaTheme.neonGlow
                                : OsnovaTheme.gold)
                            .withValues(alpha: isNeon ? 0.42 : 0.28),
                        blurRadius: isNeon ? 14 : 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: item.accentColor.withValues(alpha: 0.24),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (active)
                  Positioned(
                    left: -4,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: OsnovaTheme.goldGradient,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: (isNeon
                                    ? OsnovaTheme.neonGlow
                                    : OsnovaTheme.goldBright)
                                .withValues(alpha: 0.95),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.showPulseDot)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.accentColor.withValues(alpha: 0.9),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: active
                              ? OsnovaTheme.goldGradient
                              : RadialGradient(
                                  colors: [
                                    item.accentColor.withValues(
                                      alpha: _hovered ? 0.30 : 0.18,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                          border: Border.all(
                            color: active
                                ? OsnovaTheme.goldBright
                                : item.accentColor.withValues(
                                    alpha: _hovered ? 0.6 : 0.28,
                                  ),
                            width: 0.9,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 17,
                          color: active
                              ? OsnovaTheme.bgDark
                              : item.accentColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active
                              ? OsnovaTheme.goldBright
                              : _hovered
                                  ? OsnovaTheme.creamText
                                  : OsnovaTheme.creamText.withValues(
                                      alpha: 0.88,
                                    ),
                          fontSize: 10.5,
                          fontWeight:
                              active ? FontWeight.w900 : FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Модальне вікно вибору кольорової гами та атмосфери OSNOVA POS
class OsnovaThemePickerDialog extends StatelessWidget {
  final PosController? controller;

  const OsnovaThemePickerDialog({super.key, this.controller});

  static Future<void> show(
    BuildContext context, [
    PosController? controller,
  ]) {
    return showDialog<void>(
      context: context,
      builder: (_) => OsnovaThemePickerDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OsnovaThemeId>(
      valueListenable: OsnovaTheme.themeNotifier,
      builder: (context, activeId, _) {
        final isNeon = OsnovaTheme.isNeon;

        return Dialog(
          backgroundColor: OsnovaTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                  .withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: isNeon
                  ? [
                      BoxShadow(
                        color: OsnovaTheme.neonGlow.withValues(alpha: 0.22),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: OsnovaTheme.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: OsnovaTheme.bgDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'АТМОСФЕРА ТА ТЕМА OSNOVA',
                            style: TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Оберіть кольорову гаму під настрій зміни',
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: OsnovaTheme.sageMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.62,
                  children: OsnovaTheme.palettes.values.map((palette) {
                    final selected = palette.id == activeId;

                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        if (controller != null) {
                          await controller!.setTheme(palette.id);
                        } else {
                          await OsnovaTheme.setTheme(palette.id);
                        }
                        if (context.mounted) {
                          OsnovaToast.success(
                            context,
                            'Тему змінено: ${palette.title}',
                            subtitle: palette.subtitle,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.cardActiveGradientColors,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? (palette.isNeon
                                    ? palette.neonGlow
                                    : palette.goldBright)
                                : palette.gold.withValues(alpha: 0.35),
                            width: selected ? 2.0 : 1.1,
                          ),
                          boxShadow: [
                            if (palette.isNeon || selected)
                              BoxShadow(
                                color: (palette.isNeon
                                        ? palette.neonGlow
                                        : palette.gold)
                                    .withValues(alpha: selected ? 0.38 : 0.16),
                                blurRadius: selected ? 18 : 10,
                                spreadRadius: selected ? 1 : 0,
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: palette.bgDeep,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: palette.gold.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Icon(
                                    palette.icon,
                                    size: 18,
                                    color: palette.goldBright,
                                  ),
                                ),
                                // Прев'ю кольорових точок палітри
                                Row(
                                  children: [
                                    _ColorDot(color: palette.bgDark),
                                    const SizedBox(width: 4),
                                    _ColorDot(color: palette.gold),
                                    const SizedBox(width: 4),
                                    _ColorDot(
                                      color: palette.neonGlow,
                                      glow: palette.isNeon,
                                    ),
                                    if (selected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: palette.goldBright,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  palette.title,
                                  style: TextStyle(
                                    color: palette.creamText,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  palette.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.sageMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: OsnovaTheme.gold,
                      foregroundColor: OsnovaTheme.bgDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Готово',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool glow;

  const _ColorDot({required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 0.8),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.85),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}