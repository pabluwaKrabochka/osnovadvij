import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osnova_pos/features/pos/data/services/fortune_generator.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../../domain/entities/pos_entities.dart';
import 'osnova_toast.dart';
import 'receipt_print_template.dart';

class ReceiptPreviewDialog extends StatefulWidget {
  final List<CartItemEntity> currentCart;
  final String paymentMethod;

  const ReceiptPreviewDialog({
    super.key,
    required this.currentCart,
    required this.paymentMethod,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CartItemEntity> currentCart,
    required String paymentMethod,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(
        currentCart: currentCart,
        paymentMethod: paymentMethod,
      ),
    );
  }

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  bool _fortuneEnabled = true;
  bool _preview80mm = true;
  String _currentFortune = '';
  List _customFortunes = [];
  final _customFortuneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _customFortuneCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final enabled = await PosLocalDataSource.instance.isFortuneEnabled();
    final customs = await PosLocalDataSource.instance.getCustomFortunes();
    final customTexts = customs.map((e) => e['text'] as String).toList();
    if (!mounted) return;
    setState(() {
      _fortuneEnabled = enabled;
      _customFortunes = customs;
      _currentFortune =
          FortuneGenerator.generate(customFortunes: customTexts);
    });
  }

  void _regenerateFortune() {
    final customTexts =
        _customFortunes.map((e) => e['text'] as String).toList();
    setState(() {
      _currentFortune =
          FortuneGenerator.generate(customFortunes: customTexts);
    });
  }

  Future<void> _toggleFortune(bool value) async {
    await PosLocalDataSource.instance.setFortuneEnabled(value);
    setState(() => _fortuneEnabled = value);
  }

  Future<void> _addCustomFortune() async {
    final text = _customFortuneCtrl.text.trim();
    if (text.isEmpty) return;
    await PosLocalDataSource.instance.addCustomFortune(text);
    _customFortuneCtrl.clear();
    final customs = await PosLocalDataSource.instance.getCustomFortunes();
    if (!mounted) return;
    setState(() {
      _customFortunes = customs;
      _currentFortune = text;
    });
    OsnovaToast.success(context, 'Передбачення додано до бази закладу');
  }

  @override
  Widget build(BuildContext context) {
    final hasRealCart = widget.currentCart.isNotEmpty;
    final previewItems = hasRealCart
        ? widget.currentCart
            .map(
              (e) => ReceiptPrintItem(
                name: e.product.name,
                qty: e.qty,
                unitPriceText: MoneyFormatter.format(e.product.price),
                totalPriceText: MoneyFormatter.format(e.totalPrice),
              ),
            )
            .toList()
        : [
            ReceiptPrintItem(
              name: 'Капучіно (L)',
              qty: 1,
              unitPriceText: MoneyFormatter.format(6000),
              totalPriceText: MoneyFormatter.format(6000),
            ),
            ReceiptPrintItem(
              name: 'Спартак',
              qty: 1,
              unitPriceText: MoneyFormatter.format(10000),
              totalPriceText: MoneyFormatter.format(10000),
            ),
          ];

    final totalSum = hasRealCart
        ? widget.currentCart.fold<int>(0, (s, e) => s + e.totalPrice)
        : 16000;

    final payLabel = switch (widget.paymentMethod) {
      'card' => 'Картка (Термінал)',
      'oplata24' => 'Оплата24 (ПриватБанк)',
      _ => 'Готівка',
    };

    final now = DateTime.now();
    final sampleCode =
        '763-${DateFormat('ddMMyy-HHmm').format(now)}-001-7630';

    final previewData = ReceiptPrintData(
      documentTitle: 'ТОВАРНИЙ ЧЕК',
      receiptCode: sampleCode,
      shiftReceiptLabel: 'Чек за зміну: №1',
      dateTimeText: DateFormat('dd.MM.yyyy HH:mm').format(now),
      items: previewItems,
      grandTotalLabel: 'ДО СПЛАТИ:',
      grandTotalValue: MoneyFormatter.format(totalSum),
      paymentMethodText: payLabel,
      fortuneText:
          (_fortuneEnabled && _currentFortune.isNotEmpty) ? _currentFortune : null,
      footerNote: 'Дякуємо, що завітали в OSNOVA!',
      showSocials: true,
    );

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: OsnovaTheme.gold.withValues(alpha: 0.48),
          width: 1.2,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ЛІВА ПАНЕЛЬ: Точна копія термочека, що йде на Xprinter
              Expanded(
                flex: 48,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1914),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: OsnovaTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: OsnovaTheme.goldBright,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasRealCart
                                    ? 'ПОТОЧНИЙ ЧЕК (1:1)'
                                    : 'ЗРАЗОК ЧЕКА (1:1)',
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: OsnovaTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _widthPill(
                                  label: '80 мм',
                                  active: _preview80mm,
                                  onTap: () =>
                                      setState(() => _preview80mm = true),
                                ),
                                _widthPill(
                                  label: '58 мм',
                                  active: !_preview80mm,
                                  onTap: () =>
                                      setState(() => _preview80mm = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ReceiptPaperContent(
                                data: previewData,
                                is80mm: _preview80mm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // ПРАВА ПАНЕЛЬ: Генератор передбачень та налаштування
              Expanded(
                flex: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: OsnovaTheme.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: OsnovaTheme.bgDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ПЕРЕДБАЧЕННЯ НА ЧЕКУ',
                                style: TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Атмосферні побажання для гостей OSNOVA',
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

                    const SizedBox(height: 14),

                    Material(
                      color: const Color(0xFF11261F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: OsnovaTheme.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Друкувати передбачення на чеку',
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            'Кожен гість отримає рандомне побажання внизу чека',
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 11.5,
                            ),
                          ),
                          value: _fortuneEnabled,
                          activeThumbColor: OsnovaTheme.bgDark,
                          activeTrackColor: OsnovaTheme.gold,
                          onChanged: _toggleFortune,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        gradient: _fortuneEnabled
                            ? OsnovaTheme.goldGradient
                            : null,
                        color: _fortuneEnabled
                            ? null
                            : OsnovaTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _fortuneEnabled ? _regenerateFortune : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.casino_rounded,
                                  size: 20,
                                  color: _fortuneEnabled
                                      ? OsnovaTheme.bgDark
                                      : OsnovaTheme.sageMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Згенерувати інше передбачення',
                                  style: TextStyle(
                                    color: _fortuneEnabled
                                        ? OsnovaTheme.bgDark
                                        : OsnovaTheme.sageMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ВЛАСНІ ПЕРЕДБАЧЕННЯ ЗАКЛАДУ:',
                          style: TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1914),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_customFortunes.length}',
                            style: TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customFortuneCtrl,
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Напр.: Знижка 10% на наступну гру...',
                              hintStyle: TextStyle(
                                color: OsnovaTheme.sageMuted
                                    .withValues(alpha: 0.6),
                                fontSize: 12.5,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0A1914),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.28),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OsnovaTheme.gold,
                            foregroundColor: OsnovaTheme.bgDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _addCustomFortune,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Додати',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1914),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: _customFortunes.isEmpty
                            ? Center(
                                child: Text(
                                  'Працює вбудований генератор (24+ передбачення та конструктор фраз)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _customFortunes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final item = _customFortunes[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF11261F),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 15,
                                          color: OsnovaTheme.goldBright,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item['text'] as String,
                                            style: TextStyle(
                                              color: OsnovaTheme.creamText,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                          onPressed: () async {
                                            await PosLocalDataSource.instance
                                                .deleteCustomFortune(
                                              item['id'] as int,
                                            );
                                            await _initData();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widthPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? OsnovaTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OsnovaTheme.bgDark : OsnovaTheme.creamText,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}