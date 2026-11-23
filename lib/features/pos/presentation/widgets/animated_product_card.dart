import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import 'botanical_decorations.dart';

class AnimatedProductCard extends StatefulWidget {
  final ProductEntity product;
  final int index;
  final int cartQty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimatedProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.cartQty,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientCtrl;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    Future.delayed(Duration(milliseconds: (widget.index % 12) * 950), () {
      if (mounted) _ambientCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed
        ? 0.95
        : _isHovered
            ? 1.025
            : 1.0;

    final bool hasItems = widget.cartQty > 0;
    final priceText = MoneyFormatter.formatShort(widget.product.price);
    final iconData =
        OsnovaTheme.iconForCategory(widget.product.category, widget.product.name);

    final frameColor = _isHovered
        ? OsnovaTheme.goldBright
        : hasItems
            ? OsnovaTheme.gold.withValues(alpha: 0.88)
            : OsnovaTheme.gold.withValues(alpha: 0.28);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: () {
          setState(() => _isPressed = false);
          widget.onLongPress();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: _isHovered || hasItems
                  ? OsnovaTheme.cardActiveGradient
                  : OsnovaTheme.cardGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                if (_isHovered || hasItems)
                  BoxShadow(
                    color: OsnovaTheme.gold.withValues(alpha: _isHovered ? 0.24 : 0.14),
                    blurRadius: _isHovered ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: OsnovaMenuFrame(
              borderColor: frameColor,
              cornerSize: 7.5,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: _ambientCtrl,
                        builder: (context, child) {
                          final t = _ambientCtrl.value;
                          final pulse = t < 0.08 ? math.sin((t / 0.08) * math.pi) : 0.0;
                          final activeBoost = _isHovered ? 1.0 : pulse;

                          return Transform.translate(
                            offset: Offset(0, -1.8 * activeBoost),
                            child: Transform.rotate(
                              angle: 0.08 * activeBoost,
                              child: Transform.scale(
                                scale: 1.0 + 0.08 * activeBoost,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        OsnovaTheme.gold
                                            .withValues(alpha: 0.2 + 0.12 * activeBoost),
                                        OsnovaTheme.gold.withValues(alpha: 0.07),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.28 + 0.25 * activeBoost),
                                    ),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 19,
                                    color: Color.lerp(
                                      OsnovaTheme.gold,
                                      OsnovaTheme.goldBright,
                                      activeBoost,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (hasItems)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            gradient: OsnovaTheme.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: OsnovaTheme.gold.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            '×${widget.cartQty}',
                            style: const TextStyle(
                              color: OsnovaTheme.bgDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: OsnovaTheme.bgDark.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.product.category,
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted.withValues(alpha: 0.8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OsnovaTheme.creamText,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceText,
                        style: const TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _isHovered || hasItems
                              ? OsnovaTheme.gold.withValues(alpha: 0.22)
                              : OsnovaTheme.bgDark.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isHovered || hasItems
                                ? OsnovaTheme.goldBright
                                : OsnovaTheme.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: _isHovered || hasItems
                              ? OsnovaTheme.goldBright
                              : OsnovaTheme.sageMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}