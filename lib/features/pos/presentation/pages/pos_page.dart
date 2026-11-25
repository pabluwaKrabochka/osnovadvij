import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osnova_pos/features/pos/presentation/pages/purchases_page.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/oplata24_dialogs.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/osnova_side_nav.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/receipt_preview_dialog.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../controllers/pos_controller.dart';
import '../widgets/abc_analytics_dialog.dart';
import '../widgets/animated_product_card.dart';
import '../widgets/botanical_decorations.dart';
import '../widgets/cart_panel.dart';
import '../widgets/cash_operations_z_report.dart';
import '../widgets/osnova_brand_logo.dart';
import '../widgets/osnova_toast.dart';
import '../widgets/pos_dialogs.dart';
import '../widgets/receipt_print_template.dart';
import 'intro_page.dart';
import 'youtube_channel_page.dart';
import 'telegram_events_page.dart';
class PosPage extends StatefulWidget {
  final PosController controller;

  const PosPage({super.key, required this.controller});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.onAutoZReportCompleted = (zReport) {
      if (!mounted) return;
      OsnovaToast.success(
        context,
        'Автоматичний Z-звіт №${zReport.shiftNumber} (23:50)',
        subtitle:
            'Зміну закрито, залишок: ${MoneyFormatter.format(zReport.expectedCashInDrawerCents)}',
      );
    };
    if (widget.controller.currentShift == null) {
      widget.controller.initPos();
    }
  }

  @override
  void dispose() {
    widget.controller.onAutoZReportCompleted = null;
    super.dispose();
  }

  void _showPrintStatus(String? error) {
    if (!mounted) return;
    if (error == null) {
      final ip = widget.controller.connectedPrinterIp ?? '';
      OsnovaToast.success(
        context,
        'Надруковано на Xprinter',
        subtitle: ip.isNotEmpty ? 'Мережевий принтер: $ip' : null,
      );
    } else {
      OsnovaToast.error(
        context,
        'Помилка друку на Xprinter',
        subtitle: error,
      );
    }
  }

  Future<void> _openAbcAnalytics() async {
    final stats = await widget.controller.loadAbcAnalytics(daysBack: 30);
    if (!mounted) return;
    await AbcAnalyticsDialog.show(
      context,
      salesData: stats,
      periodTitle: 'Аналітика продажів за останні 30 днів',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final filteredCount = ctrl.filteredProducts.length;

        return Scaffold(
          backgroundColor: OsnovaTheme.bgDark,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1D15),
                    Color(0xFF0E261C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      titleSpacing: 14,
                      title: Row(
                        children: [
                          Flexible(
                            child: OsnovaBrandLogo(
                              cashInDrawer: ctrl.currentCashInDrawer,
                              printerIp: ctrl.connectedPrinterIp,
                              onEditCashTap: () =>
                                  PosDialogs.showEditCashDialog(context, ctrl),
                              onPrinterTap: () =>
                                  PosDialogs.showPrinterSettingsDialog(
                                context,
                                ctrl,
                                onPrintFinished: _showPrintStatus,
                              ),
                              onLogoTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => IntroPage(controller: ctrl),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: OsnovaTheme.bgDark.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.liveGreen
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: OsnovaTheme.liveGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: OsnovaTheme.liveGreen
                                            .withValues(alpha: 0.8),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'ЗМІНА АКТИВНА',
                                  style: TextStyle(
                                    color: OsnovaTheme.creamText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        // Швидке додавання позиції в меню
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  OsnovaTheme.bgDark.withValues(alpha: 0.65),
                              foregroundColor: OsnovaTheme.goldBright,
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                            ),
                            onPressed: () =>
                                PosDialogs.showAddProductDialog(context, ctrl),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: OsnovaTheme.goldBright,
                              size: 18,
                            ),
                            label: const Text(
                              'Позиція',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),

                        // Оплата24 ПриватБанк
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: ctrl.isOplata24Configured
                                  ? OsnovaTheme.liveGreen
                                      .withValues(alpha: 0.12)
                                  : OsnovaTheme.surfaceCard,
                              foregroundColor: OsnovaTheme.creamText,
                              side: BorderSide(
                                color: ctrl.isOplata24Configured
                                    ? OsnovaTheme.liveGreen
                                        .withValues(alpha: 0.65)
                                    : OsnovaTheme.gold.withValues(alpha: 0.42),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                            ),
                            onPressed: () =>
                                Oplata24Dialogs.showSettingsDialog(
                              context,
                              ctrl,
                            ),
                            icon: Icon(
                              Icons.phone_android_rounded,
                              color: ctrl.isOplata24Configured
                                  ? OsnovaTheme.liveGreen
                                  : OsnovaTheme.sageMuted,
                              size: 18,
                            ),
                            label: Text(
                              ctrl.isOplata24Configured
                                  ? 'Оплата24 ✓'
                                  : 'Оплата24',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),

                        // Z-звіт (стандарт ДПС / Poster)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: OsnovaTheme.gold,
                              foregroundColor: OsnovaTheme.bgDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 13),
                            ),
                            onPressed: () => PosDialogs.showReportDialog(
                              context,
                              ctrl,
                              isZReport: true,
                              onPrintFinished: _showPrintStatus,
                            ),
                            icon: const Icon(
                              Icons.lock_clock_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Z-звіт',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          OsnovaTheme.gold.withValues(alpha: 0.55),
                          OsnovaTheme.goldBright.withValues(alpha: 0.9),
                          OsnovaTheme.gold.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              const BotanicalBackground(),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PosAmbientFramePainter(),
                  ),
                ),
              ),
              ReceiptPrintTemplate(
                boundaryKey: ctrl.receiptPrintKey,
                data: ctrl.receiptPrintData,
                is80mm: ctrl.is80mmPrinter,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // 1. Ліва панель навігації з усіма інструментами каси
                    Container(
                      decoration: BoxDecoration(
                        color: OsnovaTheme.bgDark.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.34),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.42),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                       child: OsnovaSideNav(
                          onCashOpsTap: () => CashOperationDialog.show(
                            context,
                            onConfirm: ctrl.addCashOperation,
                          ),
                          onPurchasesTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PurchasesPage(),
                              ),
                            );
                          },
                          onReceiptPreviewTap: () {
                            ReceiptPreviewDialog.show(
                              context,
                              currentCart: ctrl.cart,
                              paymentMethod: ctrl.paymentMethod,
                            );
                          },
                          onHistoryTap: () =>
                              PosDialogs.showShiftHistoryDialog(context, ctrl),
                          onXReportTap: () => PosDialogs.showReportDialog(
                            context,
                            ctrl,
                            isZReport: false,
                            onPrintFinished: _showPrintStatus,
                          ),
                          onAbcTap: _openAbcAnalytics,
                          onTelegramTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TelegramEventsPage(),
                              ),
                            );
                          },
                          onYoutubeTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const YoutubeChannelPage(),
                              ),
                            );
                          },
                          onSettingsTap: () =>
                              PosDialogs.showPrinterSettingsDialog(
                            context,
                            ctrl,
                            onPrintFinished: _showPrintStatus,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 2. Центральна вітрина категорій і товарів
                    Expanded(
                      flex: 65,
                      child: Container(
                        decoration: BoxDecoration(
                          color: OsnovaTheme.bgDark.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.32),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Column(
                            children: [
                              Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: OsnovaTheme.surfaceCard
                                      .withValues(alpha: 0.45),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        itemCount: ctrl.categories.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (ctx, i) {
                                          final cat = ctrl.categories[i];
                                          final selected =
                                              cat == ctrl.selectedCategory;

                                          Widget buildCategoryPill({
                                            bool isDragging = false,
                                            bool isHoveredTarget = false,
                                          }) {
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: selected
                                                    ? OsnovaTheme.goldGradient
                                                    : null,
                                                color: selected
                                                    ? null
                                                    : isDragging
                                                        ? OsnovaTheme.gold
                                                            .withValues(
                                                              alpha: 0.08,
                                                            )
                                                        : OsnovaTheme.bgDark
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                border: Border.all(
                                                  color: isHoveredTarget ||
                                                          selected
                                                      ? OsnovaTheme.goldBright
                                                      : OsnovaTheme.gold
                                                          .withValues(
                                                            alpha: 0.28,
                                                          ),
                                                  width: isHoveredTarget ||
                                                          selected
                                                      ? 1.5
                                                      : 1.0,
                                                ),
                                                boxShadow: selected
                                                    ? [
                                                        BoxShadow(
                                                          color: OsnovaTheme
                                                              .gold
                                                              .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                cat,
                                                style: TextStyle(
                                                  color: isDragging
                                                      ? OsnovaTheme.sageMuted
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
                                                      : selected
                                                          ? OsnovaTheme.bgDark
                                                          : OsnovaTheme
                                                              .creamText,
                                                  fontWeight: selected
                                                      ? FontWeight.w900
                                                      : FontWeight.w600,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            );
                                          }

                                          if (cat == 'Усі') {
                                            return GestureDetector(
                                              onTap: () =>
                                                  ctrl.selectCategory(cat),
                                              child: buildCategoryPill(),
                                            );
                                          }

                                          return DragTarget<String>(
                                            onWillAcceptWithDetails: (details) {
                                              final dragged = details.data;
                                              if (dragged != cat) {
                                                HapticFeedback.selectionClick();
                                                ctrl.reorderCategories(
                                                  dragged,
                                                  cat,
                                                );
                                              }
                                              return dragged != cat;
                                            },
                                            builder: (
                                              context,
                                              candidateData,
                                              rejectedData,
                                            ) {
                                              final isTarget =
                                                  candidateData.isNotEmpty;
                                              return LongPressDraggable<String>(
                                                data: cat,
                                                delay: const Duration(
                                                  milliseconds: 240,
                                                ),
                                                axis: Axis.horizontal,
                                                onDragStarted: () =>
                                                    HapticFeedback
                                                        .mediumImpact(),
                                                feedback: Material(
                                                  color: Colors.transparent,
                                                  child: Transform.scale(
                                                    scale: 1.08,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 18,
                                                        vertical: 9,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: OsnovaTheme
                                                            .goldGradient,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(22),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: OsnovaTheme
                                                                .gold
                                                                .withValues(
                                                              alpha: 0.55,
                                                            ),
                                                            blurRadius: 16,
                                                            offset:
                                                                const Offset(
                                                              0,
                                                              4,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        cat,
                                                        style: const TextStyle(
                                                          color: OsnovaTheme
                                                              .bgDark,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging:
                                                    buildCategoryPill(
                                                  isDragging: true,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      ctrl.selectCategory(cat),
                                                  child: buildCategoryPill(
                                                    isHoveredTarget: isTarget,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: OsnovaTheme.bgDark
                                            .withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: OsnovaTheme.gold
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        '$filteredCount поз.',
                                        style: const TextStyle(
                                          color: OsnovaTheme.goldBright,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: filteredCount == 0
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.local_cafe_outlined,
                                              size: 46,
                                              color: OsnovaTheme.gold
                                                  .withValues(alpha: 0.45),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'У цій категорії поки немає позицій',
                                              style: TextStyle(
                                                color: OsnovaTheme.sageMuted,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          14,
                                        ),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 1.18,
                                          crossAxisSpacing: 11,
                                          mainAxisSpacing: 11,
                                        ),
                                        itemCount: filteredCount,
                                        itemBuilder: (ctx, i) {
                                          final p = ctrl.filteredProducts[i];
                                          final qtyInCart = ctrl.cart
                                                  .where(
                                                    (e) => e.product.id == p.id,
                                                  )
                                                  .firstOrNull
                                                  ?.qty ??
                                              0;

                                          return AnimatedProductCard(
                                            product: p,
                                            index: i,
                                            cartQty: qtyInCart,
                                            onTap: () => ctrl.addToCart(p),
                                            onLongPress: () => PosDialogs
                                                .showEditProductDialog(
                                              context,
                                              ctrl,
                                              p,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 3. Права панель кошика
                    Expanded(
                      flex: 35,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: OsnovaTheme.goldBright.withValues(alpha: 0.48),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: OsnovaTheme.gold.withValues(alpha: 0.12),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.5),
                          child: CartPanel(
                            controller: ctrl,
                            onCheckout: () async {
                              CheckoutResult? result;

                              if (ctrl.paymentMethod == 'oplata24') {
                                if (!ctrl.isOplata24Configured) {
                                  OsnovaToast.warning(
                                    context,
                                    'Спочатку налаштуйте Оплата24',
                                    subtitle:
                                        'Вкажіть ключі ПриватБанку та телефон касира',
                                  );
                                  await Oplata24Dialogs.showSettingsDialog(
                                    context,
                                    ctrl,
                                  );
                                  return;
                                }

                                result = await Oplata24Dialogs
                                    .showPaymentWaitingDialog(
                                  context,
                                  ctrl,
                                );
                              } else {
                                result = await ctrl.checkout();
                              }

                              if (result == null || !context.mounted) return;

                              if (result.printed) {
                                _showPrintStatus(result.printError);
                              } else {
                                final txSuffix = result.transactionId != null
                                    ? ' • RRN: ${result.transactionId}'
                                    : '';
                                OsnovaToast.success(
                                  context,
                                  'Чек №${result.receiptNum} успішно оплачено',
                                  subtitle:
                                      'Код: ${result.receiptCode}$txSuffix',
                                );
                              }
                            },
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
      },
    );
  }
}

class _PosAmbientFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.1),
        radius: 1.1,
        colors: [
          OsnovaTheme.gold.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, centerGlow);

    final bracketPaint = Paint()
      ..color = OsnovaTheme.goldBright.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const m = 4.0;
    const len = 18.0;

    canvas.drawPath(
      Path()
        ..moveTo(m, m + len)
        ..lineTo(m, m)
        ..lineTo(m + len, m),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - m - len, m)
        ..lineTo(size.width - m, m)
        ..lineTo(size.width - m, m + len),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(m, size.height - m - len)
        ..lineTo(m, size.height - m)
        ..lineTo(m + len, size.height - m),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - m - len, size.height - m)
        ..lineTo(size.width - m, size.height - m)
        ..lineTo(size.width - m, size.height - m - len),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}