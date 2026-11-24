import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/data/services/fortune_generator.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../../domain/entities/pos_entities.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final hasRealCart = widget.currentCart.isNotEmpty;
    final previewLines = hasRealCart
        ? widget.currentCart
            .map((e) => (
                  name: e.product.name,
                  qty: e.qty,
                  price: e.product.price,
                  total: e.totalPrice,
                ))
            .toList()
        : [
            (name: 'Капучіно (L)', qty: 1, price: 6000, total: 6000),
            (name: 'Спартак', qty: 1, price: 10000, total: 10000),
          ];

    final totalSum = previewLines.fold<int>(0, (s, e) => s + e.total);
    final payLabel = switch (widget.paymentMethod) {
      'card' => 'Картка (Термінал)',
      'oplata24' => 'Оплата24 (ПриватБанк)',
      _ => 'Готівка',
    };

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.45)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ліва частина: Візуальний макет термочека 80 мм
              Expanded(
                flex: 48,
                child: Column(
                  children: [
                    Text(
                      hasRealCart
                          ? 'ПЕРЕГЛЯД ПОТОЧНОГО ЧЕКА'
                          : 'ЗРАЗОК ЧЕКА ГОСТЯ (80 мм)',
                      style: const TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: 310,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F6),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Roboto',
                              fontSize: 13,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'OSNOVA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Простір ігор, кави та подій\nм. Кропивницький, вул. А. Тарковського, 76/3',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '====================================',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                ...previewLines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '  ${line.qty} × ${MoneyFormatter.format(line.price)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              MoneyFormatter.format(line.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    '====================================',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ДО СПЛАТИ:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      MoneyFormatter.format(totalSum),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Оплата: $payLabel',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (_fortuneEnabled &&
                                    _currentFortune.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black87,
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          '★ ЩАСЛИВЕ ПЕРЕДБАЧЕННЯ ★',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _currentFortune,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Text(
                                  'Дякуємо, що завітали в OSNOVA!\nInstagram: @osnova_76.3',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
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

              const SizedBox(width: 20),

              // Права частина: Генератор передбачень та налаштування
              Expanded(
                flex: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ГЕНЕРАТОР ПЕРЕДБАЧЕНЬ',
                          style: TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: OsnovaTheme.sageMuted,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Друкувати передбачення на чеку',
                        style: TextStyle(
                          color: OsnovaTheme.creamText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Кожен гість отримає рандомне побажання внизу чека',
                        style: TextStyle(
                          color: OsnovaTheme.sageMuted,
                          fontSize: 12,
                        ),
                      ),
                      value: _fortuneEnabled,
                      activeThumbColor: OsnovaTheme.bgDark,
                      activeTrackColor: OsnovaTheme.gold,
                      onChanged: _toggleFortune,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: OsnovaTheme.gold,
                        foregroundColor: OsnovaTheme.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _fortuneEnabled ? _regenerateFortune : null,
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text(
                        'Згенерувати інше передбачення',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Власні передбачення закладу (додаються до бази генератора):',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customFortuneCtrl,
                            style:
                                const TextStyle(color: OsnovaTheme.creamText),
                            decoration: const InputDecoration(
                              hintText: 'Напр.: Знижка 10% на наступну гру...',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addCustomFortune,
                          child: const Text('Додати'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _customFortunes.isEmpty
                          ? const Center(
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
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _customFortunes[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    item['text'] as String,
                                    style: const TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      await PosLocalDataSource.instance
                                          .deleteCustomFortune(
                                              item['id'] as int);
                                      await _initData();
                                    },
                                  ),
                                );
                              },
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
}