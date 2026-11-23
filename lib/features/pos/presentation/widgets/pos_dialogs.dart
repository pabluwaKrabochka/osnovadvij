import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/domain/entities/pos_entities.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../controllers/pos_controller.dart';

class PosDialogs {
  /// 1. Ручне редагування суми готівки в касі
  static Future<void> showEditCashDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final initialGrn = (controller.currentCashInDrawer / 100).toStringAsFixed(2);
    final cashCtrl = TextEditingController(text: initialGrn);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редагувати суму в касі'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Впишіть фактичну суму готівки, яка зараз є в касовій шухляді (розмін + виручка):',
              style: TextStyle(color: OsnovaTheme.sageMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: cashCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Сума в касі (грн)',
                suffixText: 'грн',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Оновити касу'),
            onPressed: () async {
              final newKopecks = MoneyFormatter.parseToKopecks(cashCtrl.text);
              await controller.updateCashInDrawer(newKopecks);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
static Future<void> showShiftHistoryDialog(
    BuildContext context,
    PosController controller,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) => DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: const Text('Журнал поточної зміни'),
            content: SizedBox(
              width: 520,
              height: 400,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: OsnovaTheme.gold,
                    labelColor: OsnovaTheme.goldBright,
                    unselectedLabelColor: OsnovaTheme.sageMuted,
                    tabs: [
                      Tab(text: 'Чеки (${controller.shiftOrders.length})'),
                      Tab(text: 'Витрати (${controller.shiftExpenses.length})'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Вкладка 1: Оплачені чеки
                        controller.shiftOrders.isEmpty
                            ? const Center(
                                child: Text(
                                  'За цю зміну ще немає пробитих чеків',
                                  style: TextStyle(color: OsnovaTheme.sageMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: controller.shiftOrders.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final order = controller.shiftOrders[i];
                                  final time = order.createdAt.length >= 16
                                      ? order.createdAt.substring(11, 16)
                                      : '';
                                  final payType =
                                      order.paymentMethod == 'cash' ? 'Готівка' : 'Картка';
                                  return ListTile(
                                    tileColor: OsnovaTheme.bgDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text(
                                      'Чек №${order.receiptNum} • ${MoneyFormatter.format(order.totalAmount)} ($payType)',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '[$time] ${order.itemsSummary}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Скасувати помилковий чек',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => controller.deleteOrder(order.id),
                                    ),
                                  );
                                },
                              ),

                        // Вкладка 2: Витрати
                        controller.shiftExpenses.isEmpty
                            ? const Center(
                                child: Text(
                                  'Витрат за цю зміну немає',
                                  style: TextStyle(color: OsnovaTheme.sageMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: controller.shiftExpenses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final exp = controller.shiftExpenses[i];
                                  final time = exp.createdAt.length >= 16
                                      ? exp.createdAt.substring(11, 16)
                                      : '';
                                  final src =
                                      exp.source == 'cash_drawer' ? 'З каси' : 'З картки';
                                  return ListTile(
                                    tileColor: OsnovaTheme.bgDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text(
                                      '${exp.title} • -${MoneyFormatter.format(exp.amount)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('[$time] Джерело: $src'),
                                    trailing: IconButton(
                                      tooltip: 'Видалити помилкову витрату',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => controller.deleteExpense(exp.id),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// 2. Додавання позиції в меню
  static Future<void> showAddProductDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Основне меню';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Додати позицію в меню'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Назва товару / послуги'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Ціна (грн)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: OsnovaTheme.surfaceElevated,
                items: controller.categories
                    .where((c) => c != 'Усі')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v!),
                decoration: const InputDecoration(labelText: 'Категорія'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            FilledButton(
              onPressed: () async {
                final price = MoneyFormatter.parseToKopecks(priceCtrl.text);
                if (nameCtrl.text.isNotEmpty && price > 0) {
                  await controller.addProduct(nameCtrl.text.trim(), category, price);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Додати'),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Внесення витрати (закупівля продуктів, розхідники)
  static Future<void> showExpenseDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String source = 'cash_drawer';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Нова витрата / закупівля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'На що витрачено (напр. Тости, Сир, Молоко)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Сума (грн)'),
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash_drawer', label: Text('З каси')),
                  ButtonSegment(value: 'external', label: Text('З картки')),
                ],
                selected: {source},
                onSelectionChanged: (v) => setDialogState(() => source = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            FilledButton(
              onPressed: () async {
                final amount = MoneyFormatter.parseToKopecks(amountCtrl.text);
                if (titleCtrl.text.isNotEmpty && amount > 0) {
                  await controller.addExpense(titleCtrl.text.trim(), amount, source);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. X-звіт та Z-звіт із відправкою файлу в Telegram власнику та друком на Xprinter
 static Future<void> showReportDialog(
    BuildContext context,
    PosController controller, {
    required bool isZReport,
    required void Function(String? error) onPrintFinished,
  }) async {
    final report = await controller.buildReport(isZReport: isZReport);
    if (report == null || !context.mounted) return;

    final lines = controller.buildReportReceiptLines(report);
    final hasPrinter = controller.connectedPrinterIp != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZReport ? 'Z-звіт (Зміну закрито)' : 'X-звіт поточної зміни'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lines.join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              if (!hasPrinter) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OsnovaTheme.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.print_disabled_outlined, color: OsnovaTheme.gold, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Принтер не підключено — друк недоступний, але звіт можна надіслати файлом у Telegram.',
                          style: TextStyle(fontSize: 12, color: OsnovaTheme.creamText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрити'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.send_rounded, color: OsnovaTheme.gold),
            label: const Text('Файл у Telegram'),
            onPressed: () async {
              await controller.exportReportToTelegram(report);
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Друк (Xprinter)'),
            onPressed: !hasPrinter
                ? null
                : () async {
                    final err = await controller.printCurrentReceipt();
                    onPrintFinished(err);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
          ),
        ],
      ),
    );

    if (isZReport) {
      await controller.initPos();
    }
  }
/// Редагування характеристик або видалення позиції (по затисканню на картку)
  static Future<void> showEditProductDialog(
    BuildContext context,
    PosController controller,
    ProductEntity product,
  ) async {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(
      text: (product.price / 100).toStringAsFixed(2),
    );
    final costCtrl = TextEditingController(
      text: product.costPrice > 0 ? (product.costPrice / 100).toStringAsFixed(2) : '',
    );

    final availableCategories =
        controller.categories.where((c) => c != 'Усі').toList();
    String category = availableCategories.contains(product.category)
        ? product.category
        : availableCategories.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Редагувати позицію'),
              IconButton(
                tooltip: 'Видалити з меню',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  await controller.deleteProduct(product.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Назва позиції',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Ціна продажу (грн)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Собівартість (грн)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: OsnovaTheme.surfaceElevated,
                  items: availableCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                  decoration: const InputDecoration(
                    labelText: 'Категорія',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Зберегти зміни'),
              onPressed: () async {
                final newPrice = MoneyFormatter.parseToKopecks(priceCtrl.text);
                final newCost = MoneyFormatter.parseToKopecks(costCtrl.text);
                if (nameCtrl.text.trim().isNotEmpty && newPrice > 0) {
                  await controller.updateProduct(
                    id: product.id,
                    name: nameCtrl.text.trim(),
                    category: category,
                    priceKopecks: newPrice,
                    costPriceKopecks: newCost,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
 static Future<void> showPrinterSettingsDialog(
    BuildContext context,
    PosController controller, {
    required void Function(String? error) onPrintFinished,
  }) async {
    final current = await controller.loadPrinterSettings();
    String selectedIp = current.ip;
    bool is80mm = current.is80mm;
    bool isScanning = true;
    List<String> foundPrinters = [];
    bool scanStarted = false;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> runScan() async {
            setDialogState(() => isScanning = true);
            final printers = await controller.discoverPrinters();
            if (!ctx.mounted) return;
            setDialogState(() {
              foundPrinters = printers;
              isScanning = false;
            });
          }

          if (!scanStarted) {
            scanStarted = true;
            Future.microtask(runScan);
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Вибір принтера (Wi-Fi)'),
                IconButton(
                  tooltip: 'Оновити пошук',
                  onPressed: isScanning ? null : runScan,
                  icon: const Icon(Icons.refresh, color: OsnovaTheme.gold),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isScanning)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(width: 14),
                          Text('Пошук Xprinter у локальній мережі...'),
                        ],
                      ),
                    )
                  else if (foundPrinters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OsnovaTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Принтерів у мережі не знайдено.\n'
                        'Перевір, чи увімкнений Xprinter, чи вставлений кабель у роутер і чи планшет на тому ж Wi-Fi.',
                        style: TextStyle(fontSize: 13),
                      ),
                    )
                  else ...[
                    const Text(
                      'Знайдені принтери (натисни для вибору):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...foundPrinters.map((ip) {
                      final isSelected = ip == selectedIp;
                      return Card(
                        color: isSelected
                            ? OsnovaTheme.surfaceElevated
                            : OsnovaTheme.bgDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? OsnovaTheme.gold
                                : OsnovaTheme.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.print, color: OsnovaTheme.gold),
                          title: Text(
                            'Xprinter ($ip)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Локальна мережа • Порт 9100'),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: OsnovaTheme.liveGreen)
                              : null,
                          onTap: () => setDialogState(() => selectedIp = ip),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Широка стрічка (80 мм)'),
                    subtitle: Text(
                      is80mm ? 'Увімкнено: 80 мм' : 'Вимкнено: стандартна 58 мм',
                    ),
                    value: is80mm,
                    onChanged: (v) => setDialogState(() => is80mm = v),
                  ),
                ],
              ),
            ),
            actions: [
              if (selectedIp.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await controller.clearPrinterSettings();
                    setDialogState(() => selectedIp = '');
                  },
                  child: const Text(
                    'Відключити',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              TextButton(
                onPressed: selectedIp.isEmpty
                    ? null
                    : () async {
                        await controller.savePrinterSettings(
                          ip: selectedIp,
                          is80mm: is80mm,
                        );
                        controller.prepareTestReceipt(selectedIp);
                        final err = await controller.printCurrentReceipt();
                        onPrintFinished(err);
                      },
                child: const Text('Тестовий друк'),
              ),
              FilledButton(
                onPressed: selectedIp.isEmpty
                    ? null
                    : () async {
                        await controller.savePrinterSettings(
                          ip: selectedIp,
                          is80mm: is80mm,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: const Text('Обрати'),
              ),
            ],
          );
        },
      ),
    );
  }
}