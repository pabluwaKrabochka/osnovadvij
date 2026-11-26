import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import '../controllers/pos_controller.dart';

class CartPanel extends StatelessWidget {
  final PosController controller;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.controller,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isCartEmpty = controller.cart.isEmpty;
    final totalFormatted = MoneyFormatter.format(controller.cartTotal);
    final isOplata24 = controller.paymentMethod == 'oplata24';
    final isNeon = OsnovaTheme.isNeon;
    final isCyberpunk = OsnovaTheme.isCyberpunk;

    final checkoutShape = OsnovaTheme.adaptiveShape(
      radius: 14,
      bevel: 10,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 12, 12),
      decoration: ShapeDecoration(
        shape: OsnovaTheme.adaptiveShape(
          radius: 18,
          bevel: 12,
          side: BorderSide(
            color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                .withValues(alpha: isNeon ? 0.55 : 0.32),
            width: isNeon ? 1.3 : 1.1,
          ),
        ),
        color: OsnovaTheme.bgDark.withValues(alpha: 0.86),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ПОТОЧНЕ ЗАМОВЛЕННЯ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      if (isCyberpunk) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            shape: OsnovaTheme.adaptiveShape(
                              radius: 4,
                              bevel: 3,
                              side: BorderSide(
                                color:
                                    OsnovaTheme.neonGlow.withValues(alpha: 0.5),
                              ),
                            ),
                            color: OsnovaTheme.bgDeep,
                          ),
                          child: Text(
                            'HUD',
                            style: TextStyle(
                              color: OsnovaTheme.neonGlow,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isCartEmpty)
                  IconButton(
                    tooltip: 'Очистити замовлення',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.clearCart();
                    },
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: OsnovaTheme.sageMuted,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: OsnovaTheme.gold.withValues(alpha: 0.25),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    isNeon ? Icons.bolt_rounded : Icons.eco_outlined,
                    size: 15,
                    color: OsnovaTheme.gold.withValues(alpha: 0.85),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: OsnovaTheme.gold.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isCartEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: ShapeDecoration(
                              shape: OsnovaTheme.adaptiveShape(
                                radius: 29,
                                bevel: 14,
                                side: BorderSide(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              color: OsnovaTheme.surfaceCard
                                  .withValues(alpha: 0.8),
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 28,
                              color: OsnovaTheme.gold.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Оберіть позиції з меню OSNOVA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: controller.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      return _CartItemTile(
                        item: item,
                        onDecrement: () {
                          HapticFeedback.selectionClick();
                          controller.decrementCartItem(index);
                        },
                        onIncrement: () {
                          HapticFeedback.selectionClick();
                          controller.addToCart(item.product);
                        },
                      );
                    },
                  ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              shape: OsnovaTheme.adaptiveShape(
                radius: 16,
                bevel: 10,
                side: BorderSide(
                  color: OsnovaTheme.gold.withValues(alpha: 0.32),
                ),
              ),
              color: OsnovaTheme.surfaceCard.withValues(alpha: 0.92),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: ShapeDecoration(
                    shape: OsnovaTheme.adaptiveShape(
                      radius: 12,
                      bevel: 7,
                      side: BorderSide(
                        color: OsnovaTheme.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    color: OsnovaTheme.bgDark.withValues(alpha: 0.85),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PaymentMethodOption(
                          label: 'Картка',
                          icon: Icons.credit_card_rounded,
                          isSelected: controller.paymentMethod == 'card',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.setPaymentMethod('card');
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _PaymentMethodOption(
                          label: 'Оплата24',
                          icon: Icons.contactless_rounded,
                          isSelected: isOplata24,
                          accentColor: OsnovaTheme.liveGreen,
                          showStatusDot: true,
                          isDotActive: controller.isOplata24Configured,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.setPaymentMethod('oplata24');
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _PaymentMethodOption(
                          label: 'Готівка',
                          icon: Icons.payments_outlined,
                          isSelected: controller.paymentMethod == 'cash',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.setPaymentMethod('cash');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    shape: OsnovaTheme.adaptiveShape(
                      radius: 12,
                      bevel: 7,
                      side: BorderSide(
                        color: OsnovaTheme.gold.withValues(alpha: 0.18),
                      ),
                    ),
                    color: OsnovaTheme.bgDark.withValues(alpha: 0.55),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isPrinterConnected
                            ? Icons.print_rounded
                            : Icons.print_disabled_outlined,
                        size: 18,
                        color: controller.isPrinterConnected
                            ? OsnovaTheme.gold
                            : OsnovaTheme.sageMuted.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Друкувати паперовий чек',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: controller.isPrinterConnected
                                    ? OsnovaTheme.creamText
                                    : OsnovaTheme.sageMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              controller.isPrinterConnected
                                  ? 'Xprinter (${controller.connectedPrinterIp})'
                                  : 'Доступно після підключення Xprinter',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: OsnovaTheme.sageMuted
                                    .withValues(alpha: 0.65),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.canPrintReceipt,
                        activeThumbColor: OsnovaTheme.bgDark,
                        activeTrackColor: OsnovaTheme.gold,
                        onChanged: controller.isPrinterConnected
                            ? (val) => controller.setPrintReceipt(val)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: checkoutShape,
                    gradient: isCartEmpty
                        ? null
                        : isOplata24
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF4ADE80),
                                  Color(0xFF22C55E),
                                ],
                              )
                            : OsnovaTheme.goldGradient,
                    color: isCartEmpty
                        ? OsnovaTheme.surfaceElevated.withValues(alpha: 0.55)
                        : null,
                    shadows: isCartEmpty
                        ? null
                        : [
                            BoxShadow(
                              color: (isOplata24
                                      ? OsnovaTheme.liveGreen
                                      : OsnovaTheme.gold)
                                  .withValues(alpha: isNeon ? 0.42 : 0.26),
                              blurRadius: isNeon ? 14 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: checkoutShape,
                      onTap: isCartEmpty
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              onCheckout();
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isCartEmpty && isOplata24) ...[
                              Icon(
                                Icons.contactless_rounded,
                                color: OsnovaTheme.bgDark,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                !isCartEmpty && isOplata24
                                    ? 'ОПЛАТА24 • $totalFormatted'
                                    : 'ОПЛАТИТИ $totalFormatted',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCartEmpty
                                      ? OsnovaTheme.sageMuted
                                          .withValues(alpha: 0.55)
                                      : OsnovaTheme.bgDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                  letterSpacing: 0.6,
                                  fontFeatures: OsnovaTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? accentColor;
  final bool showStatusDot;
  final bool isDotActive;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.accentColor,
    this.showStatusDot = false,
    this.isDotActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = accentColor ?? OsnovaTheme.sageMuted;
    final optionShape = OsnovaTheme.adaptiveShape(radius: 9, bevel: 5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: ShapeDecoration(
        shape: optionShape,
        color: isSelected ? activeBg : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: optionShape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? OsnovaTheme.bgDark
                      : (accentColor ?? OsnovaTheme.creamText),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? OsnovaTheme.bgDark
                          : OsnovaTheme.creamText,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (showStatusDot) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? OsnovaTheme.bgDark
                          : isDotActive
                              ? OsnovaTheme.liveGreen
                              : OsnovaTheme.gold.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItemTile({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: ShapeDecoration(
        shape: OsnovaTheme.adaptiveShape(
          radius: 12,
          bevel: 7,
          side: BorderSide(
            color: OsnovaTheme.gold.withValues(alpha: 0.24),
          ),
        ),
        color: OsnovaTheme.surfaceCard.withValues(alpha: 0.82),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: OsnovaTheme.creamText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${MoneyFormatter.format(item.product.price)} × ${item.qty} = ${MoneyFormatter.format(item.totalPrice)}',
                  style: TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    fontFeatures: OsnovaTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: ShapeDecoration(
              shape: OsnovaTheme.adaptiveShape(
                radius: 10,
                bevel: 5,
                side: BorderSide(
                  color: OsnovaTheme.gold.withValues(alpha: 0.28),
                ),
              ),
              color: OsnovaTheme.bgDark.withValues(alpha: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onDecrement,
                  icon: Icon(
                    item.qty == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    size: 16,
                    color: item.qty == 1
                        ? Colors.redAccent
                        : OsnovaTheme.creamText,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.qty}',
                    style: TextStyle(
                      color: OsnovaTheme.creamText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      fontFeatures: OsnovaTheme.tabularFigures,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onIncrement,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: OsnovaTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}