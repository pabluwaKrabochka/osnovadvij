import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import 'osnova_toast.dart';

enum CashOpType { serviceIn, serviceOut }

class CashOperationRecord {
  final int id;
  final CashOpType type;
  final int amountCents;
  final String reason;
  final DateTime createdAt;

  const CashOperationRecord({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.reason,
    required this.createdAt,
  });
}

class StandardZReportData {
  final int shiftNumber;
  final DateTime openedAt;
  final DateTime closedAt;
  final bool isAutoClosed;
  final int openingCashCents;
  final int cashSalesCents;
  final int cardTerminalSalesCents;
  final int receiptsCount;
  final int serviceInTotalCents;
  final int serviceOutTotalCents;
  final int expensesTotalCents;
  final List<CashOperationRecord> operations;

  const StandardZReportData({
    required this.shiftNumber,
    required this.openedAt,
    required this.closedAt,
    required this.isAutoClosed,
    required this.openingCashCents,
    required this.cashSalesCents,
    required this.cardTerminalSalesCents,
    required this.receiptsCount,
    required this.serviceInTotalCents,
    required this.serviceOutTotalCents,
    required this.expensesTotalCents,
    required this.operations,
  });

  int get totalTurnoverCents => cashSalesCents + cardTerminalSalesCents;

  /// Розрахунковий залишок готівки в шухляді за формулою ДПС / Poster
  int get expectedCashInDrawerCents =>
      openingCashCents +
      cashSalesCents +
      serviceInTotalCents -
      serviceOutTotalCents -
      expensesTotalCents;
}

/// Планувальник автоматичного закриття зміни о 23:50 (і при відновленні живлення)
class ShiftAutoCloseScheduler {
  Timer? _timer;
  bool _triggeredToday = false;

  void start({
    required DateTime? currentShiftOpenedAt,
    required Future<void> Function({required bool isAuto}) onAutoCloseShift,
  }) {
    _timer?.cancel();

    // 1. Якщо вчора вимкнули світло і зміна лишилась відкритою — закриваємо одразу при старті
    if (currentShiftOpenedAt != null) {
      final now = DateTime.now();
      final isFromPreviousDay = currentShiftOpenedAt.year != now.year ||
          currentShiftOpenedAt.month != now.month ||
          currentShiftOpenedAt.day != now.day;
      if (isFromPreviousDay) {
        onAutoCloseShift(isAuto: true);
        return;
      }
    }

    // 2. Перевіряємо кожні 20 секунд, чи настав час 23:50
    _timer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final now = DateTime.now();
      if (now.hour == 23 && now.minute >= 50 && !_triggeredToday) {
        _triggeredToday = true;
        await onAutoCloseShift(isAuto: true);
      }
      if (now.hour == 0 && now.minute == 0) {
        _triggeredToday = false;
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Діалог «Службове внесення / Службове винесення» як у Poster
class CashOperationDialog extends StatefulWidget {
  final CashOpType initialType;
  final Future<void> Function(CashOpType type, int amountCents, String reason)
      onConfirm;

  const CashOperationDialog({
    super.key,
    required this.initialType,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    CashOpType initialType = CashOpType.serviceIn,
    required Future<void> Function(CashOpType type, int amountCents, String reason)
        onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CashOperationDialog(
        initialType: initialType,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CashOperationDialog> createState() => _CashOperationDialogState();
}

class _CashOperationDialogState extends State<CashOperationDialog> {
  late CashOpType _type;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  static const List<String> _inReasons = [
    'Розмін у касу',
    'Поповнення шухляди',
    'Повернення підзвітних коштів',
  ];

  static const List<String> _outReasons = [
    'Інкасація в сейф',
    'Видача на закупку (вода/розхідники)',
    'Видача зарплати / авансу',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _reasonCtrl.text = _type == CashOpType.serviceIn
        ? _inReasons.first
        : _outReasons.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountUah =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amountUah <= 0) {
      OsnovaToast.warning(
        context,
        'Вкажіть коректну суму',
        subtitle: 'Сума має бути більшою за 0 грн',
      );
      return;
    }

    final reason = _reasonCtrl.text.trim().isEmpty
        ? (_type == CashOpType.serviceIn
            ? 'Службове внесення'
            : 'Службове винесення')
        : _reasonCtrl.text.trim();

    final cents = (amountUah * 100).round();
    setState(() => _saving = true);
    await widget.onConfirm(_type, cents, reason);

    if (!mounted) return;
    OsnovaToast.success(
      context,
      _type == CashOpType.serviceIn
          ? 'Службове внесення проведено'
          : 'Службове винесення проведено',
      subtitle: '${MoneyFormatter.format(cents)} • $reason',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isServiceIn = _type == CashOpType.serviceIn;
    final presets = isServiceIn ? _inReasons : _outReasons;

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.45)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'КАСОВА ОПЕРАЦІЯ (ДПС / POSTER)',
                style: TextStyle(
                  color: OsnovaTheme.goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 14),

              // Перемикач Внесення / Винесення
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          '+ Службове внесення',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      selected: isServiceIn,
                      selectedColor: OsnovaTheme.liveGreen,
                      labelStyle: TextStyle(
                        color: isServiceIn
                            ? OsnovaTheme.bgDark
                            : OsnovaTheme.creamText,
                      ),
                      backgroundColor: OsnovaTheme.bgDark,
                      onSelected: (_) => setState(() {
                        _type = CashOpType.serviceIn;
                        _reasonCtrl.text = _inReasons.first;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          '- Службове винесення',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      selected: !isServiceIn,
                      selectedColor: Colors.orangeAccent,
                      labelStyle: TextStyle(
                        color: !isServiceIn
                            ? OsnovaTheme.bgDark
                            : OsnovaTheme.creamText,
                      ),
                      backgroundColor: OsnovaTheme.bgDark,
                      onSelected: (_) => setState(() {
                        _type = CashOpType.serviceOut;
                        _reasonCtrl.text = _outReasons.first;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(
                  color: OsnovaTheme.goldBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: 'Сума операції (грн)',
                  hintText: '0.00',
                  filled: true,
                  fillColor: OsnovaTheme.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets.map((r) {
                  return ActionChip(
                    backgroundColor: OsnovaTheme.bgDark,
                    label: Text(
                      r,
                      style: const TextStyle(
                        color: OsnovaTheme.creamText,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => setState(() => _reasonCtrl.text = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _reasonCtrl,
                style: const TextStyle(color: OsnovaTheme.creamText),
                decoration: InputDecoration(
                  labelText: 'Коментар / призначення',
                  filled: true,
                  fillColor: OsnovaTheme.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Скасувати'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isServiceIn
                          ? OsnovaTheme.liveGreen
                          : Colors.orangeAccent,
                      foregroundColor: OsnovaTheme.bgDark,
                    ),
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Провести по касі',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Стандартний фіскальний вигляд Z-звіту (ДПС / Poster)
class StandardZReportView extends StatelessWidget {
  final StandardZReportData report;

  const StandardZReportView({super.key, required this.report});

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OsnovaTheme.bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Z-ЗВІТ №${report.shiftNumber}',
                style: const TextStyle(
                  color: OsnovaTheme.goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              if (report.isAutoClosed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: OsnovaTheme.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'АВТО 23:50',
                    style: TextStyle(
                      color: OsnovaTheme.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 18),
          _row('Залишок на початок зміни', report.openingCashCents),
          _row('Виручка готівкою', report.cashSalesCents),
          _row('Безготівка (Термінал / Оплата24)',
              report.cardTerminalSalesCents),
          _row('Загальний обіг (${report.receiptsCount} чеків)',
              report.totalTurnoverCents,
              bold: true),
          const Divider(height: 18),
          _row('+ Службове внесення', report.serviceInTotalCents,
              valueColor: OsnovaTheme.liveGreen),
          _row('- Службове винесення (інкасація)', report.serviceOutTotalCents,
              valueColor: Colors.orangeAccent),
          if (report.expensesTotalCents > 0)
            _row('- Витрати з каси', report.expensesTotalCents,
                valueColor: Colors.redAccent),
          if (report.operations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...report.operations.map((op) {
              final sign = op.type == CashOpType.serviceIn ? '+' : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '  • ${_fmtTime(op.createdAt)} | $sign${MoneyFormatter.format(op.amountCents)} — ${op.reason}',
                  style: const TextStyle(
                    color: OsnovaTheme.sageMuted,
                    fontSize: 11.5,
                  ),
                ),
              );
            }),
          ],
          const Divider(height: 18),
          _row(
            'ГОТІВКА В КАСІ (ЗАЛИШОК)',
            report.expectedCashInDrawerCents,
            bold: true,
            valueColor: OsnovaTheme.goldBright,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int cents, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? OsnovaTheme.creamText : OsnovaTheme.sageMuted,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 13.5 : 12.5,
            ),
          ),
          Text(
            MoneyFormatter.format(cents),
            style: TextStyle(
              color: valueColor ?? OsnovaTheme.creamText,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontSize: bold ? 14.5 : 13,
            ),
          ),
        ],
      ),
    );
  }
}