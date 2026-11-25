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
  final ScrollController _categoryScrollCtrl = ScrollController();
  final ScrollController _gridScrollCtrl = ScrollController();

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
    _categoryScrollCtrl.dispose();
    _gridScrollCtrl.dispose();
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
      listenable: Listenable.merge([ctrl, OsnovaTheme.themeNotifier]),
      builder: (context, _) {
        final filteredCount = ctrl.filteredProducts.length;
        final isNeon = OsnovaTheme.isNeon;

        return Scaffold(
          backgroundColor: OsnovaTheme.bgDark,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OsnovaTheme.bgDeep,
                    OsnovaTheme.surfaceCard,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  if (isNeon)
                    BoxShadow(
                      color: OsnovaTheme.neonGlow.withValues(alpha: 0.2),
                      blurRadius: 14,
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
                              color: OsnovaTheme.bgDark.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.liveGreen
                                    .withValues(alpha: isNeon ? 0.75 : 0.45),
                              ),
                              boxShadow: isNeon
                                  ? [
                                      BoxShadow(
                                        color: OsnovaTheme.liveGreen
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
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
                                            .withValues(alpha: 0.85),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  OsnovaTheme.bgDark.withValues(alpha: 0.68),
                              foregroundColor: OsnovaTheme.goldBright,
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                            ),
                            onPressed: () =>
                                PosDialogs.showAddProductDialog(context, ctrl),
                            icon: Icon(
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
                                    : OsnovaTheme.gold.withValues(alpha: 0.45),
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
                    height: isNeon ? 2.0 : 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                              .withValues(alpha: 0.65),
                          OsnovaTheme.goldBright,
                          (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
                              .withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: isNeon
                          ? [
                              BoxShadow(
                                color: OsnovaTheme.neonGlow
                                    .withValues(alpha: 0.65),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
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
                    painter: _PosAmbientFramePainter(
                      palette: OsnovaTheme.current,
                    ),
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
                    // 1. Ліва панель навігації із кнопкою вибору теми
                    OsnovaSideNav(
                      onCashOpsTap: () => CashOperationDialog.show(
                        context,
                        onConfirm: ctrl.addCashOperation,
                      ),
                      onPurchasesTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PurchasesPage(),
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
                            builder: (_) => TelegramEventsPage(),
                          ),
                        );
                      },
                      onYoutubeTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>  YoutubeChannelPage(),
                          ),
                        );
                      },
                      onThemeTap: () =>
                          OsnovaThemePickerDialog.show(context, ctrl),
                      onSettingsTap: () =>
                          PosDialogs.showPrinterSettingsDialog(
                        context,
                        ctrl,
                        onPrintFinished: _showPrintStatus,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 2. Центральна вітрина категорій і товарів
                    Expanded(
                      flex: 65,
                      child: Container(
                        decoration: BoxDecoration(
                          color: OsnovaTheme.bgDark.withValues(alpha: 0.64),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: (isNeon
                                    ? OsnovaTheme.neonGlow
                                    : OsnovaTheme.gold)
                                .withValues(alpha: isNeon ? 0.62 : 0.34),
                            width: isNeon ? 1.4 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.38),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            if (isNeon)
                              BoxShadow(
                                color: OsnovaTheme.neonGlow
                                    .withValues(alpha: 0.16),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Column(
                            children: [
                              Container(
                                height: 62,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      OsnovaTheme.surfaceCard
                                          .withValues(alpha: 0.78),
                                      OsnovaTheme.bgDark
                                          .withValues(alpha: 0.88),
                                    ],
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: (isNeon
                                              ? OsnovaTheme.neonGlow
                                              : OsnovaTheme.gold)
                                          .withValues(
                                        alpha: isNeon ? 0.42 : 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: NotificationListener<
                                                ScrollMetricsNotification>(
                                              onNotification: (_) {
                                                setState(() {});
                                                return false;
                                              },
                                              child: ListView.separated(
                                                controller:
                                                    _categoryScrollCtrl,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  12,
                                                  9,
                                                  12,
                                                  7,
                                                ),
                                                itemCount:
                                                    ctrl.categories.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(width: 8),
                                                itemBuilder: (ctx, i) {
                                                  final cat =
                                                      ctrl.categories[i];
                                                  final selected = cat ==
                                                      ctrl.selectedCategory;

                                                  Widget buildCategoryPill({
                                                    bool isDragging = false,
                                                    bool isHoveredTarget =
                                                        false,
                                                  }) {
                                                    return AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      curve:
                                                          Curves.easeOutCubic,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16,
                                                        vertical: 7,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: selected
                                                            ? OsnovaTheme
                                                                .goldGradient
                                                            : null,
                                                        color: selected
                                                            ? null
                                                            : isDragging
                                                                ? OsnovaTheme
                                                                    .gold
                                                                    .withValues(
                                                                    alpha: 0.08,
                                                                  )
                                                                : OsnovaTheme
                                                                    .bgDark
                                                                    .withValues(
                                                                    alpha: 0.84,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(22),
                                                        border: Border.all(
                                                          color:
                                                              isHoveredTarget ||
                                                                      selected
                                                                  ? OsnovaTheme
                                                                      .goldBright
                                                                  : (isNeon
                                                                          ? OsnovaTheme
                                                                              .neonGlow
                                                                          : OsnovaTheme
                                                                              .gold)
                                                                      .withValues(
                                                                      alpha: isNeon
                                                                          ? 0.42
                                                                          : 0.28,
                                                                    ),
                                                          width:
                                                              isHoveredTarget ||
                                                                      selected
                                                                  ? 1.5
                                                                  : 1.0,
                                                        ),
                                                        boxShadow: selected
                                                            ? [
                                                                BoxShadow(
                                                                  color: (isNeon
                                                                          ? OsnovaTheme
                                                                              .neonGlow
                                                                          : OsnovaTheme
                                                                              .gold)
                                                                      .withValues(
                                                                    alpha: isNeon
                                                                        ? 0.52
                                                                        : 0.35,
                                                                  ),
                                                                  blurRadius:
                                                                      isNeon
                                                                          ? 15
                                                                          : 12,
                                                                  offset:
                                                                      const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        cat,
                                                        style: TextStyle(
                                                          color: isDragging
                                                              ? OsnovaTheme
                                                                  .sageMuted
                                                                  .withValues(
                                                                  alpha: 0.4,
                                                                )
                                                              : selected
                                                                  ? OsnovaTheme
                                                                      .bgDark
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
                                                      onTap: () => ctrl
                                                          .selectCategory(cat),
                                                      child:
                                                          buildCategoryPill(),
                                                    );
                                                  }

                                                  return DragTarget<String>(
                                                    onWillAcceptWithDetails:
                                                        (details) {
                                                      final dragged =
                                                          details.data;
                                                      if (dragged != cat) {
                                                        HapticFeedback
                                                            .selectionClick();
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
                                                          candidateData
                                                              .isNotEmpty;
                                                      return LongPressDraggable<
                                                          String>(
                                                        data: cat,
                                                        delay: const Duration(
                                                          milliseconds: 240,
                                                        ),
                                                        axis: Axis.horizontal,
                                                        onDragStarted: () =>
                                                            HapticFeedback
                                                                .mediumImpact(),
                                                        feedback: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child:
                                                              Transform.scale(
                                                            scale: 1.08,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 18,
                                                                vertical: 9,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    OsnovaTheme
                                                                        .goldGradient,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  22,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: OsnovaTheme
                                                                        .gold
                                                                        .withValues(
                                                                      alpha:
                                                                          0.55,
                                                                    ),
                                                                    blurRadius:
                                                                        16,
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
                                                                style:
                                                                    TextStyle(
                                                                  color: OsnovaTheme
                                                                      .bgDark,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
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
                                                              ctrl.selectCategory(
                                                            cat,
                                                          ),
                                                          child:
                                                              buildCategoryPill(
                                                            isHoveredTarget:
                                                                isTarget,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OsnovaTheme.bgDark
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: OsnovaTheme.gold
                                                    .withValues(alpha: 0.32),
                                              ),
                                            ),
                                            child: Text(
                                              '$filteredCount поз.',
                                              style: TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _HorizontalGoldSliderBar(
                                      controller: _categoryScrollCtrl,
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
                                            Text(
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
                                    : RawScrollbar(
                                        controller: _gridScrollCtrl,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        interactive: true,
                                        thickness: 5.5,
                                        radius: const Radius.circular(8),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 3,
                                        ),
                                        thumbColor: OsnovaTheme.gold
                                            .withValues(alpha: 0.82),
                                        trackColor: OsnovaTheme.bgDeep
                                            .withValues(alpha: 0.65),
                                        trackBorderColor: OsnovaTheme.gold
                                            .withValues(alpha: 0.25),
                                        child: GridView.builder(
                                          controller: _gridScrollCtrl,
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            15,
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
                                                      (e) =>
                                                          e.product.id == p.id,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 3. Права панель кошика з неоновим обрамленням у нічній темі
                    Expanded(
                      flex: 35,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: (isNeon
                                    ? OsnovaTheme.neonGlow
                                    : OsnovaTheme.goldBright)
                                .withValues(alpha: isNeon ? 0.85 : 0.48),
                            width: isNeon ? 1.6 : 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isNeon
                                      ? OsnovaTheme.neonGlow
                                      : OsnovaTheme.gold)
                                  .withValues(alpha: isNeon ? 0.28 : 0.12),
                              blurRadius: isNeon ? 24 : 22,
                              spreadRadius: isNeon ? 1.5 : 1,
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

class _HorizontalGoldSliderBar extends StatelessWidget {
  final ScrollController controller;

  const _HorizontalGoldSliderBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasClients) return const SizedBox(height: 4);
        final pos = controller.position;
        if (!pos.hasContentDimensions || pos.maxScrollExtent <= 1.0) {
          return const SizedBox(height: 4);
        }

        final viewport = pos.viewportDimension;
        final totalContent = viewport + pos.maxScrollExtent;
        final thumbFraction = (viewport / totalContent).clamp(0.18, 0.85);
        final scrollFraction =
            (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 74, 3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbWidth = trackWidth * thumbFraction;
              final maxOffset = trackWidth - thumbWidth;
              final leftOffset = maxOffset * scrollFraction;

              return Container(
                height: 3.5,
                decoration: BoxDecoration(
                  color: OsnovaTheme.bgDeep.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: OsnovaTheme.gold.withValues(alpha: 0.18),
                    width: 0.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: leftOffset,
                      top: 0,
                      bottom: 0,
                      width: thumbWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: OsnovaTheme.goldGradient,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: OsnovaTheme.gold.withValues(alpha: 0.55),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PosAmbientFramePainter extends CustomPainter {
  final OsnovaPalette palette;

  _PosAmbientFramePainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final centerGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.1),
        radius: 1.1,
        colors: [
          palette.neonGlow.withValues(alpha: palette.isNeon ? 0.14 : 0.07),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, centerGlow);

    const m = 4.0;
    const len = 22.0;

    final path = Path()
      ..moveTo(m, m + len)
      ..lineTo(m, m)
      ..lineTo(m + len, m)
      ..moveTo(size.width - m - len, m)
      ..lineTo(size.width - m, m)
      ..lineTo(size.width - m, m + len)
      ..moveTo(m, size.height - m - len)
      ..lineTo(m, size.height - m)
      ..lineTo(m + len, size.height - m)
      ..moveTo(size.width - m - len, size.height - m)
      ..lineTo(size.width - m, size.height - m)
      ..lineTo(size.width - m, size.height - m - len);

    if (palette.isNeon) {
      final glowPaint = Paint()
        ..color = palette.neonGlow.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(path, glowPaint);
    }

    final bracketPaint = Paint()
      ..color =
          (palette.isNeon ? palette.neonGlow : palette.goldBright).withValues(
        alpha: palette.isNeon ? 0.92 : 0.38,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = palette.isNeon ? 1.8 : 1.4;

    canvas.drawPath(path, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _PosAmbientFramePainter oldDelegate) =>
      oldDelegate.palette != palette;
}