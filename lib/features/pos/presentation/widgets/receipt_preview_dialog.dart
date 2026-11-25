import 'package:flutter/material.dart';
import 'package:osnova_pos/features/pos/data/services/fortune_generator.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../../domain/entities/pos_entities.dart';
import 'osnova_toast.dart';

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
              // ЛІВА ПАНЕЛЬ: Сцена термочека
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
                              const Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: OsnovaTheme.goldBright,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasRealCart
                                    ? 'ПОТОЧНИЙ ЧЕК'
                                    : 'ЗРАЗОК ЧЕКА',
                                style: const TextStyle(
                                  color: OsnovaTheme.goldBright,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                          // Перемикач ширини прев'ю 80 / 58 мм
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
                        child: SingleChildScrollView(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: _preview80mm ? 315 : 242,
                            padding: EdgeInsets.symmetric(
                              horizontal: _preview80mm ? 18 : 13,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F6),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Roboto',
                                fontSize: _preview80mm ? 13 : 11.5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'O S N O V A',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Простір ігор, кави та подій\nм. Кропивницький, вул. А. Тарковського, 76/3',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                      thickness: 1.6,
                                      color: Colors.black,
                                    ),
                                  ),
                                  ...previewLines.map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 7),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '  ${line.qty} × ${MoneyFormatter.format(line.price)}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                              Text(
                                                MoneyFormatter.format(
                                                  line.total,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
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
                                    child: Divider(
                                      thickness: 1.6,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ДО СПЛАТИ:',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        MoneyFormatter.format(totalSum),
                                        style: const TextStyle(
                                          fontSize: 17.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Оплата: $payLabel',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (_fortuneEnabled &&
                                      _currentFortune.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F0EA),
                                        border: Border.all(
                                          color: Colors.black87,
                                          width: 1.3,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            '★ ЩАСЛИВЕ ПЕРЕДБАЧЕННЯ ★',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _currentFortune,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w700,
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
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
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
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: OsnovaTheme.bgDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
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
                          icon: const Icon(
                            Icons.close_rounded,
                            color: OsnovaTheme.sageMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Перемикач у преміальній картці (Material замість Container з color для коректного ListTile)
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
                          title: const Text(
                            'Друкувати передбачення на чеку',
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: const Text(
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

                    // Кнопка рандомної генерації
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
                        const Text(
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
                            style: const TextStyle(
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
                            style: const TextStyle(
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
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 15,
                                          color: OsnovaTheme.goldBright,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item['text'] as String,
                                            style: const TextStyle(
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
                                                    item['id'] as int);
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