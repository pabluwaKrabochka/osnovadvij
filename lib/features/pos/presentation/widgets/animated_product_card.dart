import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import 'botanical_decorations.dart';

class AnimatedProductCard extends StatefulWidget {
  final ProductEntity product;
  final int index;
  final int cartQty;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;
  final VoidCallback onLongPress;

  const AnimatedProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.cartQty,
    required this.onTap,
    this.onDecrement,
    required this.onLongPress,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.cartQty > 0) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSelected = oldWidget.cartQty > 0;
    final isSelected = widget.cartQty > 0;
    if (isSelected && !wasSelected) {
      _shimmerCtrl.repeat();
    } else if (!isSelected && wasSelected) {
      _shimmerCtrl.stop();
      _shimmerCtrl.reset();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Color _categoryIndicatorColor() {
    final cat = widget.product.category;
    final name = widget.product.name.toLowerCase();
    if (cat == 'Холодні напої' ||
        name.contains('тонік') ||
        name.contains('ice') ||
        name.contains('айс')) {
      return const Color(0xFF38BDF8);
    }
    if (cat == 'Смаколики' ||
        name.contains('тост') ||
        name.contains('сендвіч')) {
      return const Color(0xFFF59E0B);
    }
    if (cat == 'Послуги' ||
        name.contains('мафія') ||
        name.contains('playstation') ||
        name.contains('квіз')) {
      return const Color(0xFFC084FC);
    }
    if (cat == 'Додатки') {
      return OsnovaTheme.liveGreen;
    }
    return OsnovaTheme.goldBright;
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = OsnovaTheme.isNeon;
    final isCyberpunk = OsnovaTheme.isCyberpunk;
    final bool hasItems = widget.cartQty > 0;
    final double scale = _isPressed ? 0.96 : 1.0;

    final priceText = MoneyFormatter.formatShort(widget.product.price);
    final iconData = OsnovaTheme.iconForCategory(
      widget.product.category,
      widget.product.name,
    );
    final categoryColor = _categoryIndicatorColor();

    final borderColor = hasItems
        ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright)
            .withValues(alpha: isNeon ? 0.92 : 0.68)
        : (isNeon ? OsnovaTheme.neonGlow : Colors.white)
            .withValues(alpha: isNeon ? 0.34 : 0.10);

    final frameColor = hasItems
        ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright)
            .withValues(alpha: 0.92)
        : (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
            .withValues(alpha: isNeon ? 0.42 : 0.26);

    final cardShape = OsnovaTheme.adaptiveShape(
      radius: 16,
      bevel: 10,
      side: BorderSide(
        color: borderColor,
        width: hasItems ? 1.45 : (isNeon ? 1.15 : 1.0),
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _isPressed = false);
          widget.onLongPress();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 105),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: ShapeDecoration(
              shape: cardShape,
              gradient: hasItems
                  ? OsnovaTheme.cardActiveGradient
                  : OsnovaTheme.cardGradient,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                if (hasItems)
                  BoxShadow(
                    color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                        .withValues(alpha: isNeon ? 0.32 : 0.22),
                    blurRadius: 14,
                  ),
              ],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: cardShape),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: isCyberpunk ? 12 : 14,
                    bottom: isCyberpunk ? 12 : 14,
                    child: Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(
                          alpha: hasItems ? 0.95 : 0.65,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  if (hasItems)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, _) {
                            final t = _shimmerCtrl.value;
                            if (t > 0.45) return const SizedBox.shrink();
                            final progress = t / 0.45;
                            final slide = -1.6 + progress * 3.2;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(slide - 0.55, -1.0),
                                  end: Alignment(slide + 0.55, 1.0),
                                  colors: [
                                    Colors.transparent,
                                    (isNeon
                                            ? OsnovaTheme.neonGlow
                                            : OsnovaTheme.goldBright)
                                        .withValues(alpha: 0.13),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  OsnovaMenuFrame(
                    borderColor: frameColor,
                    cornerSize: isCyberpunk ? 9.5 : 8.5,
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: ShapeDecoration(
                                shape: OsnovaTheme.adaptiveShape(
                                  radius: 10,
                                  bevel: 6,
                                  side: BorderSide(
                                    color: categoryColor.withValues(
                                      alpha: hasItems ? 0.65 : 0.32,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                color: OsnovaTheme.bgDeep.withValues(alpha: 0.85),
                              ),
                              child: Icon(
                                iconData,
                                size: 18,
                                color: hasItems
                                    ? OsnovaTheme.goldBright
                                    : categoryColor,
                              ),
                            ),
                            if (hasItems)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  shape: OsnovaTheme.adaptiveShape(
                                    radius: 14,
                                    bevel: 6,
                                  ),
                                  gradient: OsnovaTheme.goldGradient,
                                ),
                                child: Text(
                                  '×${widget.cartQty}',
                                  style: TextStyle(
                                    color: OsnovaTheme.bgDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    fontFeatures: OsnovaTheme.tabularFigures,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: ShapeDecoration(
                                  shape: OsnovaTheme.adaptiveShape(
                                    radius: 8,
                                    bevel: 5,
                                    side: BorderSide(
                                      color:
                                          categoryColor.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  color:
                                      OsnovaTheme.bgDeep.withValues(alpha: 0.72),
                                ),
                                child: Text(
                                  widget.product.category,
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted
                                        .withValues(alpha: 0.92),
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
                          style: TextStyle(
                            color: hasItems
                                ? Colors.white
                                : OsnovaTheme.creamText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            height: 1.2,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: ShapeDecoration(
                                shape: OsnovaTheme.adaptiveShape(
                                  radius: 8,
                                  bevel: 5,
                                  side: BorderSide(
                                    color: OsnovaTheme.gold.withValues(
                                      alpha: hasItems ? 0.45 : 0.22,
                                    ),
                                  ),
                                ),
                                color: OsnovaTheme.gold.withValues(
                                  alpha: hasItems ? 0.18 : 0.10,
                                ),
                              ),
                              child: Text(
                                priceText,
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                  fontFeatures: OsnovaTheme.tabularFigures,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                shape: OsnovaTheme.adaptiveShape(
                                  radius: 8,
                                  bevel: 5,
                                  side: BorderSide(
                                    color: hasItems
                                        ? OsnovaTheme.goldBright
                                        : OsnovaTheme.gold
                                            .withValues(alpha: 0.36),
                                  ),
                                ),
                                gradient:
                                    hasItems ? OsnovaTheme.goldGradient : null,
                                color: hasItems
                                    ? null
                                    : OsnovaTheme.bgDeep.withValues(alpha: 0.8),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 17,
                                color: hasItems
                                    ? OsnovaTheme.bgDark
                                    : OsnovaTheme.goldBright,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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