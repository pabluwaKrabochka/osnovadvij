import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/osnova_toast.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../controllers/pos_controller.dart';
import 'botanical_decorations.dart';

class _CartRowSnapshot {
  final int productId;
  final String name;
  final String category;
  final int unitPrice;
  final int qty;
  final int totalPrice;

  const _CartRowSnapshot({
    required this.productId,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.qty,
    required this.totalPrice,
  });
}

class CartPanel extends StatefulWidget {
  final PosController controller;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.controller,
    required this.onCheckout,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollCtrl = ScrollController();

  late final AnimationController _scrollHintBounceCtrl;
  late final AnimationController _ctaSheenCtrl;

  List<_CartRowSnapshot> _items = [];
  int? _highlightedProductId;
  bool _canScrollDown = false;
  bool _canScrollUp = false;

  @override
  void initState() {
    super.initState();
    _items = _takeSnapshot();
    widget.controller.addListener(_syncAnimatedList);
    _scrollCtrl.addListener(_updateScrollIndicators);

    _scrollHintBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _ctaSheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAnimatedList);
    _scrollCtrl.removeListener(_updateScrollIndicators);
    _scrollCtrl.dispose();
    _scrollHintBounceCtrl.dispose();
    _ctaSheenCtrl.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!mounted) return;
    if (!_scrollCtrl.hasClients || _items.isEmpty) {
      if (_canScrollDown || _canScrollUp) {
        setState(() {
          _canScrollDown = false;
          _canScrollUp = false;
        });
      }
      return;
    }

    final pos = _scrollCtrl.position;
    final nextDown = pos.maxScrollExtent > 6 && pos.pixels < pos.maxScrollExtent - 8;
    final nextUp = pos.pixels > 8;

    if (nextDown != _canScrollDown || nextUp != _canScrollUp) {
      setState(() {
        _canScrollDown = nextDown;
        _canScrollUp = nextUp;
      });
    }
  }

  List<_CartRowSnapshot> _takeSnapshot() {
    return widget.controller.cart
        .map(
          (e) => _CartRowSnapshot(
            productId: e.product.id,
            name: e.product.name,
            category: e.product.category,
            unitPrice: e.product.price,
            qty: e.qty,
            totalPrice: e.totalPrice,
          ),
        )
        .toList();
  }

  void _flashProduct(int productId) {
    setState(() => _highlightedProductId = productId);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted && _highlightedProductId == productId) {
        setState(() => _highlightedProductId = null);
      }
    });
  }

  void _syncAnimatedList() {
    if (!mounted) return;
    final incoming = _takeSnapshot();

    // 1. Повне очищення або оплата чека
    if (incoming.isEmpty && _items.isNotEmpty) {
      for (int i = _items.length - 1; i >= 0; i--) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, anim) => _buildAnimatedRow(removed, anim, isRemoving: true),
          duration: const Duration(milliseconds: 220),
        );
      }
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
      return;
    }

    // 2. Додано нову позицію
    if (incoming.length > _items.length) {
      int insertIdx = incoming.length - 1;
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].productId != incoming[i].productId) {
          insertIdx = i;
          break;
        }
      }
      final added = incoming[insertIdx];
      _items.insert(insertIdx, added);
      _listKey.currentState?.insertItem(
        insertIdx,
        duration: const Duration(milliseconds: 280),
      );
      _flashProduct(added.productId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
      return;
    }

    // 3. Видалено одну позицію
    if (incoming.length < _items.length) {
      int removeIdx = _items.length - 1;
      for (int i = 0; i < incoming.length; i++) {
        if (_items[i].productId != incoming[i].productId) {
          removeIdx = i;
          break;
        }
      }
      final removed = _items.removeAt(removeIdx);
      _listKey.currentState?.removeItem(
        removeIdx,
        (ctx, anim) => _buildAnimatedRow(removed, anim, isRemoving: true),
        duration: const Duration(milliseconds: 230),
      );
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
      return;
    }

    // 4. Змінилась кількість у наявній позиції
    for (int i = 0; i < incoming.length; i++) {
      if (_items[i].qty != incoming[i].qty ||
          _items[i].name != incoming[i].name ||
          _items[i].totalPrice != incoming[i].totalPrice) {
        if (incoming[i].qty > _items[i].qty) {
          _flashProduct(incoming[i].productId);
        }
      }
    }
    setState(() => _items = incoming);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
  }

  Widget _buildAnimatedRow(
    _CartRowSnapshot item,
    Animation<double> animation, {
    bool isRemoving = false,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: isRemoving ? Curves.easeInCubic : Curves.easeOutCubic,
    );
    final isHighlighted = !isRemoving && _highlightedProductId == item.productId;
    final iconData = OsnovaTheme.iconForCategory(item.category, item.name);

    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.18, 0),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? OsnovaTheme.cardActiveGradient
                    : OsnovaTheme.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHighlighted
                      ? OsnovaTheme.goldBright
                      : OsnovaTheme.gold.withValues(alpha: 0.24),
                  width: isHighlighted ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  if (isHighlighted)
                    BoxShadow(
                      color: OsnovaTheme.gold.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ліва золота акцентна смужка
                      Container(
                        width: 3.5,
                        decoration: BoxDecoration(
                          gradient: isHighlighted
                              ? OsnovaTheme.goldGradient
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    OsnovaTheme.gold.withValues(alpha: 0.7),
                                    OsnovaTheme.gold.withValues(alpha: 0.2),
                                  ],
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
                          child: Row(
                            children: [
                              // Іконка категорії товару
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: OsnovaTheme.gold.withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: OsnovaTheme.gold.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Icon(
                                  iconData,
                                  size: 17,
                                  color: OsnovaTheme.goldBright,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Назва та розрахунок суми
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: OsnovaTheme.creamText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          MoneyFormatter.format(item.totalPrice),
                                          style: const TextStyle(
                                            color: OsnovaTheme.goldBright,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (item.qty > 1) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${MoneyFormatter.formatShort(item.unitPrice)} × ${item.qty})',
                                            style: TextStyle(
                                              color: OsnovaTheme.sageMuted
                                                  .withValues(alpha: 0.8),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Кнопки - / кількість / +
                              _QtyStepperButton(
                                icon: Icons.remove_rounded,
                                isAccent: false,
                                onTap: () {
                                  final idx = widget.controller.cart.indexWhere(
                                      (e) => e.product.id == item.productId);
                                  if (idx != -1) {
                                    HapticFeedback.selectionClick();
                                    widget.controller.decrementCartItem(idx);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 32,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: Text(
                                    '${item.qty}',
                                    key: ValueKey('${item.productId}_${item.qty}'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.5,
                                    ),
                                  ),
                                ),
                              ),
                              _QtyStepperButton(
                                icon: Icons.add_rounded,
                                isAccent: true,
                                onTap: () {
                                  final existing = widget.controller.cart
                                      .where((e) => e.product.id == item.productId)
                                      .firstOrNull;
                                  if (existing != null) {
                                    HapticFeedback.selectionClick();
                                    widget.controller.addToCart(existing.product);
                                  }
                                },
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final totalItemsCount = ctrl.cart.fold<int>(0, (sum, e) => sum + e.qty);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OsnovaTheme.surfaceCard.withValues(alpha: 0.52),
            OsnovaTheme.bgDeep.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: OsnovaMenuFrame(
        borderColor: OsnovaTheme.gold.withValues(alpha: 0.32),
        cornerSize: 10,
        child: Column(
          children: [
            // Шапка чека з лічильником позицій
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'ПОТОЧНЕ ЗАМОВЛЕННЯ',
                        style: TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          fontSize: 13,
                        ),
                      ),
                      if (totalItemsCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: OsnovaTheme.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: OsnovaTheme.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            '$totalItemsCount шт',
                            style: const TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (ctrl.cart.isNotEmpty)
                    Material(
                      color: OsnovaTheme.surfaceElevated.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ctrl.clearCart();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OsnovaTheme.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 17,
                                color: OsnovaTheme.sageMuted,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Очистити',
                                style: TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const GoldLeafDivider(),

            // Анімований список позицій + індикатори скролу (верхній/нижній)
            Expanded(
              child: Stack(
                children: [
                  if (_items.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: OsnovaTheme.gold.withValues(alpha: 0.07),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 38,
                              color: OsnovaTheme.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Оберіть позиції з меню OSNOVA',
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  RawScrollbar(
                    controller: _scrollCtrl,
                    thumbColor: OsnovaTheme.gold.withValues(alpha: 0.45),
                    radius: const Radius.circular(6),
                    thickness: 3.5,
                    child: AnimatedList(
                      key: _listKey,
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        14,
                        4,
                        14,
                        _canScrollDown ? 42 : 10,
                      ),
                      initialItemCount: _items.length,
                      itemBuilder: (ctx, i, animation) {
                        return _buildAnimatedRow(_items[i], animation);
                      },
                    ),
                  ),

                  // Верхній м'який градієнт, коли список прокручений вниз
                  if (_canScrollUp)
                    Positioned(
                      top: 0,
                      left: 6,
                      right: 6,
                      height: 20,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                OsnovaTheme.bgDark.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Нижній градієнт + інтерактивний індикатор "Ще позиції ↓"
                  Positioned(
                    bottom: 0,
                    left: 6,
                    right: 6,
                    child: IgnorePointer(
                      ignoring: !_canScrollDown,
                      child: AnimatedOpacity(
                        opacity: _canScrollDown ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                OsnovaTheme.bgDeep.withValues(alpha: 0.92),
                                OsnovaTheme.bgDeep,
                              ],
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _scrollCtrl.animateTo(
                                (_scrollCtrl.offset + 180).clamp(
                                  0.0,
                                  _scrollCtrl.position.maxScrollExtent,
                                ),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedBuilder(
                              animation: _scrollHintBounceCtrl,
                              builder: (context, child) {
                                final dy = -2.5 * _scrollHintBounceCtrl.value;
                                return Transform.translate(
                                  offset: Offset(0, dy),
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: OsnovaTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: OsnovaTheme.gold.withValues(alpha: 0.55),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.keyboard_double_arrow_down_rounded,
                                      size: 16,
                                      color: OsnovaTheme.goldBright,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Гортайте вниз',
                                      style: TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Нижній блок оплати з градієнтом
            Container(
              margin: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    OsnovaTheme.surfaceCard.withValues(alpha: 0.92),
                    OsnovaTheme.bgDeep.withValues(alpha: 0.96),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: OsnovaTheme.gold.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'card',
                        label: Text('Картка (Термінал)'),
                        icon: Icon(Icons.nfc),
                      ),
                      ButtonSegment(
                        value: 'cash',
                        label: Text('Готівка'),
                        icon: Icon(Icons.payments_outlined),
                      ),
                    ],
                    selected: {ctrl.paymentMethod},
                    onSelectionChanged: (v) => ctrl.setPaymentMethod(v.first),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final isConnected = ctrl.isPrinterConnected;
                      final isPrintOn = ctrl.canPrintReceipt;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (!isConnected) {
                            HapticFeedback.heavyImpact();
                            OsnovaToast.warning(
                              context,
                              'Xprinter не підключено',
                              subtitle: 'Оберіть принтер по Wi-Fi у налаштуваннях (⚙)',
                            );
                            return;
                          }
                          HapticFeedback.selectionClick();
                          ctrl.setPrintReceipt(!ctrl.printReceipt);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? OsnovaTheme.surfaceCard.withValues(alpha: 0.85)
                                : OsnovaTheme.bgDark.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPrintOn
                                  ? OsnovaTheme.gold.withValues(alpha: 0.45)
                                  : OsnovaTheme.sageMuted.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                !isConnected
                                    ? Icons.print_disabled_rounded
                                    : isPrintOn
                                        ? Icons.print_rounded
                                        : Icons.print_outlined,
                                size: 20,
                                color: !isConnected
                                    ? OsnovaTheme.sageMuted.withValues(alpha: 0.45)
                                    : isPrintOn
                                        ? OsnovaTheme.goldBright
                                        : OsnovaTheme.sageMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Друкувати паперовий чек',
                                      style: TextStyle(
                                        color: !isConnected
                                            ? OsnovaTheme.sageMuted.withValues(alpha: 0.55)
                                            : isPrintOn
                                                ? OsnovaTheme.creamText
                                                : OsnovaTheme.sageMuted,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!isConnected)
                                      Text(
                                        'Доступно після підключення Xprinter',
                                        style: TextStyle(
                                          color: OsnovaTheme.sageMuted.withValues(alpha: 0.45),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isPrintOn,
                                activeThumbColor: OsnovaTheme.bgDark,
                                activeTrackColor: OsnovaTheme.gold,
                                onChanged: isConnected
                                    ? (v) {
                                        HapticFeedback.selectionClick();
                                        ctrl.setPrintReceipt(v);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Головна кнопка оплати з золотим градієнтом та світловим відблиском
                  _ShimmerCheckoutButton(
                    enabled: ctrl.cart.isNotEmpty,
                    sheenAnimation: _ctaSheenCtrl,
                    label: ctrl.canPrintReceipt
                        ? 'ОПЛАТИТИ ${MoneyFormatter.format(ctrl.cartTotal)} + ЧЕК'
                        : 'ОПЛАТИТИ ${MoneyFormatter.format(ctrl.cartTotal)}',
                    animationKey: '${ctrl.cartTotal}_${ctrl.canPrintReceipt}',
                    onTap: widget.onCheckout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCheckoutButton extends StatelessWidget {
  final bool enabled;
  final Animation<double> sheenAnimation;
  final String label;
  final String animationKey;
  final VoidCallback onTap;

  const _ShimmerCheckoutButton({
    required this.enabled,
    required this.sheenAnimation,
    required this.label,
    required this.animationKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: enabled ? OsnovaTheme.goldGradient : null,
        color: enabled ? null : OsnovaTheme.surfaceCard.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: OsnovaTheme.gold.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (enabled)
              AnimatedBuilder(
                animation: sheenAnimation,
                builder: (context, _) {
                  final t = sheenAnimation.value;
                  // Відблиск пробігає на перших 35% циклу, далі пауза
                  final sweep = t < 0.35 ? (t / 0.35) * 2.6 - 1.3 : -2.0;
                  if (sweep < -1.5) return const SizedBox.shrink();

                  return FractionallySizedBox(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(sweep - 0.35, -0.4),
                          end: Alignment(sweep + 0.35, 0.4),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.32),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onTap : null,
                splashColor: Colors.white.withValues(alpha: 0.25),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      label,
                      key: ValueKey(animationKey),
                      style: TextStyle(
                        color: enabled
                            ? OsnovaTheme.bgDark
                            : OsnovaTheme.sageMuted.withValues(alpha: 0.45),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
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

class _QtyStepperButton extends StatelessWidget {
  final IconData icon;
  final bool isAccent;
  final VoidCallback onTap;

  const _QtyStepperButton({
    required this.icon,
    required this.isAccent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAccent
          ? OsnovaTheme.gold.withValues(alpha: 0.16)
          : OsnovaTheme.bgDark.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: OsnovaTheme.gold.withValues(alpha: 0.28),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAccent
                  ? OsnovaTheme.gold.withValues(alpha: 0.65)
                  : OsnovaTheme.sageMuted.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: isAccent ? OsnovaTheme.goldBright : OsnovaTheme.creamText,
          ),
        ),
      ),
    );
  }
}