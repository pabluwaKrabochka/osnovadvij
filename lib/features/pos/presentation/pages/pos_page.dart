import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/presentation/pages/intro_page.dart';
import 'package:osnova_pos/features/pos/presentation/pages/youtube_channel_page.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/botanical_decorations.dart';
import 'package:osnova_pos/features/pos/presentation/widgets/osnova_toast.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../controllers/pos_controller.dart';
import '../widgets/animated_product_card.dart';
import '../widgets/cart_panel.dart';
import '../widgets/osnova_brand_logo.dart';
import '../widgets/pos_dialogs.dart';
import '../widgets/receipt_print_template.dart';

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
    widget.controller.initPos();
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
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final visibleProducts = ctrl.filteredProducts;

        return Scaffold(
         appBar: AppBar(
            title: OsnovaBrandLogo(
              cashInDrawer: ctrl.currentCashInDrawer,
              printerIp: ctrl.connectedPrinterIp,
              onEditCashTap: () => PosDialogs.showEditCashDialog(context, ctrl),
              onPrinterTap: () => PosDialogs.showPrinterSettingsDialog(
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: OsnovaTheme.gold.withValues(alpha: 0.2),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Додати позицію в меню',
                onPressed: () => PosDialogs.showAddProductDialog(context, ctrl),
                icon: const Icon(Icons.add_box_outlined, color: OsnovaTheme.gold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: OsnovaTheme.surfaceCard,
                    foregroundColor: OsnovaTheme.creamText,
                    side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const YoutubeChannelPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFFFF0033),
                    size: 19,
                  ),
                  label: const Text(
                    'YouTube',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => PosDialogs.showShiftHistoryDialog(context, ctrl),
                icon: const Icon(Icons.history_rounded, color: OsnovaTheme.gold),
                label: const Text('Журнал', style: TextStyle(color: OsnovaTheme.creamText)),
              ),
              TextButton.icon(
                onPressed: () => PosDialogs.showExpenseDialog(context, ctrl),
                icon: const Icon(Icons.remove_circle_outline, color: OsnovaTheme.sageMuted),
                label: const Text('Витрата', style: TextStyle(color: OsnovaTheme.creamText)),
              ),
              TextButton.icon(
                onPressed: () => PosDialogs.showReportDialog(
                  context,
                  ctrl,
                  isZReport: false,
                  onPrintFinished: _showPrintStatus,
                ),
                icon: const Icon(Icons.analytics_outlined, color: OsnovaTheme.sageMuted),
                label: const Text('X-звіт', style: TextStyle(color: OsnovaTheme.creamText)),
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: () => PosDialogs.showReportDialog(
                  context,
                  ctrl,
                  isZReport: true,
                  onPrintFinished: _showPrintStatus,
                ),
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text('Z-звіт'),
              ),
              IconButton(
                tooltip: 'Налаштування Xprinter (Wi-Fi)',
                onPressed: () => PosDialogs.showPrinterSettingsDialog(
                  context,
                  ctrl,
                  onPrintFinished: _showPrintStatus,
                ),
                icon: const Icon(Icons.settings_outlined, color: OsnovaTheme.gold),
              ),
              const SizedBox(width: 10),
            ],
          ),
         body: Stack(
            children: [
              const BotanicalBackground(),
              ReceiptPrintTemplate(
                boundaryKey: ctrl.receiptPrintKey,
                title: ctrl.receiptPreviewTitle,
                lines: ctrl.receiptPreviewLines,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 65,
                    child: Column(
                      children: [
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: ctrl.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final cat = ctrl.categories[i];
                            final selected = cat == ctrl.selectedCategory;

                            return GestureDetector(
                              onTap: () => ctrl.selectCategory(cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      selected ? OsnovaTheme.goldGradient : null,
                                  color: selected
                                      ? null
                                      : OsnovaTheme.surfaceCard.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: selected
                                        ? OsnovaTheme.goldBright
                                        : OsnovaTheme.gold.withValues(alpha: 0.28),
                                    width: selected ? 1.3 : 1.0,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: selected
                                        ? OsnovaTheme.bgDark
                                        : OsnovaTheme.creamText,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.38,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: visibleProducts.length,
                            itemBuilder: (ctx, i) {
                              final item = visibleProducts[i];
                            return AnimatedProductCard(
                            key: ValueKey('prod_${item.id}'),
                            product: item,
                            index: i,
                            cartQty: ctrl.getProductCartQty(item.id),
                            onTap: () => ctrl.addToCart(item),
                            onLongPress: () => PosDialogs.showEditProductDialog(
                              context,
                              ctrl,
                              item,
                            ),
                          );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    color: OsnovaTheme.gold.withValues(alpha: 0.2),
                  ),
                Expanded(
                    flex: 35,
                    child: CartPanel(
                      controller: ctrl,
                    onCheckout: () async {
                        final result = await ctrl.checkout();
                        if (result == null || !context.mounted) return;

                        if (result.printed) {
                          _showPrintStatus(result.printError);
                        } else {
                          OsnovaToast.success(
                            context,
                            'Чек №${result.receiptNum} успішно оплачено',
                            subtitle: 'Збережено у журналі зміни (без друку)',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}