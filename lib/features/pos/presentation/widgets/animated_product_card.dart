import 'dart:math' as math;
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
  Offset? _pointerLocalPos;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    Future.delayed(Duration(milliseconds: (widget.index % 12) * 850), () {
      if (mounted) _ambientCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  Color _categoryAuraColor() {
    if (OsnovaTheme.isNeon) {
      return OsnovaTheme.neonGlow;
    }
    final cat = widget.product.category;
    final name = widget.product.name.toLowerCase();
    if (cat == 'Холодні напої' ||
        name.contains('тонік') ||
        name.contains('ice') ||
        name.contains('айс')) {
      return const Color(0xFF38BDF8);
    }
    if (cat == 'Смаколики') {
      return const Color(0xFFF59E0B);
    }
    if (cat == 'Послуги' ||
        name.contains('мафія') ||
        name.contains('playstation') ||
        name.contains('квіз')) {
      return const Color(0xFFA78BFA);
    }
    if (cat == 'Додатки') {
      return OsnovaTheme.liveGreen;
    }
    return OsnovaTheme.goldBright;
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = OsnovaTheme.isNeon;
    final double scale = _isPressed
        ? 0.945
        : _isHovered
            ? 1.03
            : 1.0;

    final bool hasItems = widget.cartQty > 0;
    final priceText = MoneyFormatter.formatShort(widget.product.price);
    final iconData = OsnovaTheme.iconForCategory(
      widget.product.category,
      widget.product.name,
    );
    final auraColor = _categoryAuraColor();

    final frameColor = _isHovered
        ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright)
        : hasItems
            ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                .withValues(alpha: 0.95)
            : (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                .withValues(alpha: isNeon ? 0.52 : 0.32);

    return MouseRegion(
      onEnter: (e) => setState(() {
        _isHovered = true;
        _pointerLocalPos = e.localPosition;
      }),
      onHover: (e) => setState(() => _pointerLocalPos = e.localPosition),
      onExit: (_) => setState(() {
        _isHovered = false;
        _pointerLocalPos = null;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (details) {
          HapticFeedback.selectionClick();
          setState(() {
            _isPressed = true;
            _pointerLocalPos = details.localPosition;
          });
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() {
          _isPressed = false;
          _pointerLocalPos = null;
        }),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _isPressed = false);
          widget.onLongPress();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: (_isHovered || hasItems)
                  ? OsnovaTheme.cardActiveGradient
                  : OsnovaTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (_isHovered || hasItems)
                    ? (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.goldBright)
                        .withValues(alpha: isNeon ? 0.92 : 0.55)
                    : (isNeon ? OsnovaTheme.neonGlow : Colors.white)
                        .withValues(alpha: isNeon ? 0.36 : 0.08),
                width: isNeon ? 1.3 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                if (isNeon || _isHovered || hasItems)
                  BoxShadow(
                    color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                        .withValues(
                      alpha: (_isHovered || hasItems)
                          ? (isNeon ? 0.42 : 0.28)
                          : (isNeon ? 0.14 : 0.0),
                    ),
                    blurRadius: (_isHovered || hasItems) ? 20 : 11,
                    spreadRadius: (_isHovered || hasItems) ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  final spotAlignment =
                      _pointerLocalPos != null && w > 0 && h > 0
                          ? Alignment(
                              (_pointerLocalPos!.dx / w) * 2 - 1,
                              (_pointerLocalPos!.dy / h) * 2 - 1,
                            )
                          : const Alignment(-0.75, -0.75);

                  return Stack(
                    children: [
                      Positioned(
                        top: -26,
                        left: -26,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                auraColor.withValues(
                                  alpha: (_isHovered || hasItems) ? 0.26 : 0.14,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isHovered || _isPressed)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: spotAlignment,
                                  radius: 0.95,
                                  colors: [
                                    (isNeon
                                            ? OsnovaTheme.neonGlow
                                            : OsnovaTheme.goldBright)
                                        .withValues(
                                      alpha: _isPressed ? 0.24 : 0.15,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _ambientCtrl,
                            builder: (context, _) {
                              final t = _ambientCtrl.value;
                              if (t > 0.14) return const SizedBox.shrink();
                              final progress = t / 0.14;
                              final slide = -1.6 + progress * 3.2;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(slide - 0.6, -1.0),
                                    end: Alignment(slide + 0.6, 1.0),
                                    colors: [
                                      Colors.transparent,
                                      OsnovaTheme.goldBright
                                          .withValues(alpha: 0.10),
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
                        cornerSize: 8.5,
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AnimatedBuilder(
                                  animation: _ambientCtrl,
                                  builder: (context, _) {
                                    final t = _ambientCtrl.value;
                                    final pulse = t < 0.08
                                        ? math.sin((t / 0.08) * math.pi)
                                        : 0.0;
                                    final activeBoost =
                                        (_isHovered || hasItems) ? 1.0 : pulse;

                                    return Transform.translate(
                                      offset: Offset(0, -1.8 * activeBoost),
                                      child: Transform.rotate(
                                        angle: 0.07 * activeBoost,
                                        child: Transform.scale(
                                          scale: 1.0 + 0.08 * activeBoost,
                                          child: Container(
                                            padding: const EdgeInsets.all(8.5),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  OsnovaTheme.gold.withValues(
                                                    alpha: 0.26 +
                                                        0.14 * activeBoost,
                                                  ),
                                                  OsnovaTheme.bgDeep
                                                      .withValues(alpha: 0.88),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              border: Border.all(
                                                color: OsnovaTheme.goldBright
                                                    .withValues(
                                                  alpha: 0.34 +
                                                      0.32 * activeBoost,
                                                ),
                                                width: 1.1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: auraColor.withValues(
                                                    alpha: (isNeon
                                                            ? 0.25
                                                            : 0.16) *
                                                        activeBoost,
                                                  ),
                                                  blurRadius: 10,
                                                ),
                                              ],
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
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutBack,
                                    ),
                                    child: child,
                                  ),
                                  child: hasItems
                                      ? Container(
                                          key: ValueKey('qty_${widget.cartQty}'),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: OsnovaTheme.goldGradient,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: OsnovaTheme.gold
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '×${widget.cartQty}',
                                            style: TextStyle(
                                              color: OsnovaTheme.bgDark,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          key: const ValueKey('cat_pill'),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.5,
                                            vertical: 3.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: OsnovaTheme.bgDeep
                                                .withValues(alpha: 0.72),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: OsnovaTheme.gold
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Text(
                                            widget.product.category,
                                            style: TextStyle(
                                              color: OsnovaTheme.sageMuted
                                                  .withValues(alpha: 0.9),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                color: (_isHovered || hasItems)
                                    ? Colors.white
                                    : OsnovaTheme.creamText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
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
                                  decoration: BoxDecoration(
                                    color: OsnovaTheme.gold.withValues(
                                      alpha: (_isHovered || hasItems)
                                          ? 0.18
                                          : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: OsnovaTheme.gold.withValues(
                                        alpha: (_isHovered || hasItems)
                                            ? 0.45
                                            : 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    priceText,
                                    style: TextStyle(
                                      color: OsnovaTheme.goldBright,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 29,
                                  height: 29,
                                  decoration: BoxDecoration(
                                    gradient: (_isHovered || hasItems)
                                        ? OsnovaTheme.goldGradient
                                        : null,
                                    color: (_isHovered || hasItems)
                                        ? null
                                        : OsnovaTheme.bgDeep
                                            .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: (_isHovered || hasItems)
                                          ? OsnovaTheme.goldBright
                                          : OsnovaTheme.gold
                                              .withValues(alpha: 0.36),
                                    ),
                                    boxShadow: (_isHovered || hasItems)
                                        ? [
                                            BoxShadow(
                                              color: OsnovaTheme.gold
                                                  .withValues(alpha: 0.42),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 17,
                                    color: (_isHovered || hasItems)
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}