import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osnova_pos/features/pos/data/services/osnova_telegram_services.dart';
import 'package:osnova_pos/features/pos/domain/entities/pos_entities.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../controllers/pos_controller.dart';
import 'cash_operations_z_report.dart';
import 'osnova_toast.dart';

class PosDialogs {
  static InputDecoration _premiumInput({
    required String label,
    String? hint,
    String? suffixText,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      labelStyle: const TextStyle(color: OsnovaTheme.sageMuted, fontSize: 12.5),
      hintStyle: TextStyle(
        color: OsnovaTheme.sageMuted.withValues(alpha: 0.55),
        fontSize: 12.5,
      ),
      suffixStyle: const TextStyle(
        color: OsnovaTheme.goldBright,
        fontWeight: FontWeight.w800,
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: OsnovaTheme.goldBright)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0A1914),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.28)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: OsnovaTheme.goldBright, width: 1.5),
      ),
    );
  }

  static Widget _dialogHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onClose,
    Color? accentColor,
    Widget? trailing,
  }) {
    final badgeColor = accentColor ?? OsnovaTheme.goldBright;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: accentColor == null
                ? OsnovaTheme.goldGradient
                : LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.78),
                    ],
                  ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: OsnovaTheme.bgDark, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16.5,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: OsnovaTheme.sageMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          trailing,
          const SizedBox(width: 6),
        ],
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: OsnovaTheme.sageMuted),
        ),
      ],
    );
  }

  static Widget _goldPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? solidColor,
  }) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        gradient: !enabled
            ? null
            : solidColor != null
                ? LinearGradient(
                    colors: [solidColor, solidColor.withValues(alpha: 0.85)],
                  )
                : OsnovaTheme.goldGradient,
        color: !enabled ? OsnovaTheme.surfaceElevated : null,
        borderRadius: BorderRadius.circular(13),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: (solidColor ?? OsnovaTheme.gold)
                      .withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: enabled ? OsnovaTheme.bgDark : OsnovaTheme.sageMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? OsnovaTheme.bgDark : OsnovaTheme.sageMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Ручне редагування суми готівки в касі
  static Future<void> showEditCashDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final initialGrn = (controller.currentCashInDrawer / 100).toStringAsFixed(2);
    final cashCtrl = TextEditingController(text: initialGrn);

    void addQuickDelta(int deltaUah) {
      final currentKopecks = MoneyFormatter.parseToKopecks(cashCtrl.text);
      final updated = (currentKopecks + deltaUah * 100).clamp(0, 99999999);
      cashCtrl.text = (updated / 100).toStringAsFixed(2);
    }

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: OsnovaTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: OsnovaTheme.gold.withValues(alpha: 0.48),
            width: 1.2,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  icon: Icons.payments_rounded,
                  title: 'КОРЕГУВАННЯ ГОТІВКИ В КАСІ',
                  subtitle: 'Фактичний залишок у шухляді (розмін + виручка)',
                  onClose: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF143126), Color(0xFF0A1914)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: OsnovaTheme.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Поточний баланс у системі:',
                        style: TextStyle(
                          color: OsnovaTheme.sageMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        MoneyFormatter.format(controller.currentCashInDrawer),
                        style: const TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: cashCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: const TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: _premiumInput(
                    label: 'Нова сума в касі',
                    suffixText: 'грн',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [100, 200, 500, 1000].map((delta) {
                    return ActionChip(
                      backgroundColor: const Color(0xFF11261F),
                      side: BorderSide(
                        color: OsnovaTheme.gold.withValues(alpha: 0.35),
                      ),
                      label: Text(
                        '+$delta грн',
                        style: const TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => addQuickDelta(delta),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Скасувати',
                        style: TextStyle(color: OsnovaTheme.sageMuted),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _goldPrimaryButton(
                      icon: Icons.check_circle_rounded,
                      label: 'Оновити касу',
                      onPressed: () async {
                        final newKopecks =
                            MoneyFormatter.parseToKopecks(cashCtrl.text);
                        await controller.updateCashInDrawer(newKopecks);
                        if (ctx.mounted) {
                          OsnovaToast.success(
                            ctx,
                            'Готівку в касі оновлено',
                            subtitle: MoneyFormatter.format(newKopecks),
                          );
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Журнал поточної зміни (Чеки, Журнал витрат, Касові операції)
  static Future<void> showShiftHistoryDialog(
    BuildContext context,
    PosController controller,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
          final totalSales = controller.shiftOrders
              .fold<int>(0, (sum, o) => sum + o.totalAmount);
          final totalExpenses = controller.shiftExpenses
              .fold<int>(0, (sum, e) => sum + e.amount);

          return DefaultTabController(
            length: 3,
            child: Dialog(
              backgroundColor: OsnovaTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: OsnovaTheme.gold.withValues(alpha: 0.48),
                  width: 1.2,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720, maxHeight: 590),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        icon: Icons.history_edu_rounded,
                        title: 'ЖУРНАЛ ПОТОЧНОЇ ЗМІНИ',
                        subtitle:
                            'Оплачені чеки, витрати зміни та службові рухи готівки',
                        onClose: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(height: 14),

                      // Зведена KPI-стрічка зміни
                      Row(
                        children: [
                          _miniKpiBox(
                            label: 'Виручка за чеками',
                            value: MoneyFormatter.format(totalSales),
                            valueColor: OsnovaTheme.goldBright,
                            icon: Icons.receipt_long_rounded,
                          ),
                          const SizedBox(width: 10),
                          _miniKpiBox(
                            label: 'Витрати за зміну',
                            value: '-${MoneyFormatter.format(totalExpenses)}',
                            valueColor: Colors.redAccent,
                            icon: Icons.trending_down_rounded,
                          ),
                          const SizedBox(width: 10),
                          _miniKpiBox(
                            label: 'В касі зараз',
                            value: MoneyFormatter.format(
                              controller.currentCashInDrawer,
                            ),
                            valueColor: OsnovaTheme.liveGreen,
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Преміальний перемикач вкладок
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1914),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            gradient: OsnovaTheme.goldGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: OsnovaTheme.bgDark,
                          unselectedLabelColor: OsnovaTheme.creamText,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                          tabs: [
                            Tab(
                              text: 'Чеки (${controller.shiftOrders.length})',
                            ),
                            Tab(
                              text:
                                  'Витрати (${controller.shiftExpenses.length})',
                            ),
                            Tab(
                              text:
                                  'Каса (${controller.shiftCashOperations.length})',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: TabBarView(
                          children: [
                            // Вкладка 1: Оплачені чеки
                            controller.shiftOrders.isEmpty
                                ? _emptyJournalState(
                                    icon: Icons.receipt_outlined,
                                    text: 'За цю зміну ще немає пробитих чеків',
                                  )
                                : ListView.separated(
                                    itemCount: controller.shiftOrders.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final order = controller.shiftOrders[i];
                                      final time = order.createdAt.length >= 16
                                          ? order.createdAt.substring(11, 16)
                                          : '';
                                      final payType = switch (
                                          order.paymentMethod) {
                                        'cash' => 'Готівка',
                                        'oplata24' => 'Оплата24',
                                        _ => 'Картка',
                                      };
                                      final payColor = switch (
                                          order.paymentMethod) {
                                        'cash' => OsnovaTheme.goldBright,
                                        'oplata24' => OsnovaTheme.liveGreen,
                                        _ => const Color(0xFF4FC3F7),
                                      };

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11261F),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A1914),
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                                border: Border.all(
                                                  color: OsnovaTheme.gold
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                '№${order.receiptNum}',
                                                style: const TextStyle(
                                                  color: OsnovaTheme.goldBright,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        time,
                                                        style: const TextStyle(
                                                          color: OsnovaTheme
                                                              .sageMuted,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: payColor
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          payType,
                                                          style: TextStyle(
                                                            color: payColor,
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    order.itemsSummary,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color:
                                                          OsnovaTheme.creamText,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              MoneyFormatter.format(
                                                order.totalAmount,
                                              ),
                                              style: const TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              tooltip:
                                                  'Скасувати помилковий чек',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              onPressed: () => controller
                                                  .deleteOrder(order.id),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            // Вкладка 2: Журнал витрат зміни
                            controller.shiftExpenses.isEmpty
                                ? _emptyJournalState(
                                    icon: Icons.savings_outlined,
                                    text: 'Витрат за цю зміну ще немає',
                                  )
                                : ListView.separated(
                                    itemCount: controller.shiftExpenses.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final exp = controller.shiftExpenses[i];
                                      final time = exp.createdAt.length >= 16
                                          ? exp.createdAt.substring(11, 16)
                                          : '';
                                      final isCash =
                                          exp.source == 'cash_drawer';
                                      final src = isCash
                                          ? 'З касової шухляди'
                                          : 'З картки / зовнішні';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11261F),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.redAccent
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.outbound_outlined,
                                                color: Colors.redAccent,
                                                size: 19,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exp.title,
                                                    style: const TextStyle(
                                                      color:
                                                          OsnovaTheme.creamText,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        time,
                                                        style: const TextStyle(
                                                          color: OsnovaTheme
                                                              .sageMuted,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: (isCash
                                                                  ? OsnovaTheme
                                                                      .gold
                                                                  : const Color(
                                                                      0xFF4FC3F7))
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          src,
                                                          style: TextStyle(
                                                            color: isCash
                                                                ? OsnovaTheme
                                                                    .goldBright
                                                                : const Color(
                                                                    0xFF4FC3F7),
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '-${MoneyFormatter.format(exp.amount)}',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              tooltip:
                                                  'Видалити помилкову витрату',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              onPressed: () => controller
                                                  .deleteExpense(exp.id),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            // Вкладка 3: Службові внесення / винесення
                            controller.shiftCashOperations.isEmpty
                                ? _emptyJournalState(
                                    icon: Icons.swap_vert_rounded,
                                    text:
                                        'Службових внесень та винесень за зміну немає',
                                  )
                                : ListView.separated(
                                    itemCount:
                                        controller.shiftCashOperations.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final op =
                                          controller.shiftCashOperations[i];
                                      final isIn =
                                          op.type == CashOpType.serviceIn;
                                      final hh = op.createdAt.hour
                                          .toString()
                                          .padLeft(2, '0');
                                      final mm = op.createdAt.minute
                                          .toString()
                                          .padLeft(2, '0');
                                      final color = isIn
                                          ? OsnovaTheme.liveGreen
                                          : Colors.orangeAccent;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11261F),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                isIn
                                                    ? Icons
                                                        .add_circle_outline_rounded
                                                    : Icons
                                                        .remove_circle_outline_rounded,
                                                color: color,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isIn
                                                        ? 'Службове внесення'
                                                        : 'Службове винесення',
                                                    style: const TextStyle(
                                                      color:
                                                          OsnovaTheme.creamText,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '[$hh:$mm] ${op.reason}',
                                                    style: const TextStyle(
                                                      color:
                                                          OsnovaTheme.sageMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${isIn ? '+' : '-'}${MoneyFormatter.format(op.amountCents)}',
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OsnovaTheme.goldBright,
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showExpenseDialog(context, controller);
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Додати витрату'),
                          ),
                          _goldPrimaryButton(
                            icon: Icons.check_rounded,
                            label: 'Готово',
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _miniKpiBox({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF143126), Color(0xFF0A1914)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: OsnovaTheme.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: OsnovaTheme.gold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OsnovaTheme.sageMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _emptyJournalState({
    required IconData icon,
    required String text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1914).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.16)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: OsnovaTheme.gold.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: OsnovaTheme.sageMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Додавання позиції в меню (з живим прев'ю картки та маржею)
  static Future<void> showAddProductDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    final availableCats =
        controller.categories.where((c) => c != 'Усі').toList();
    String category = availableCats.contains('Основне меню')
        ? 'Основне меню'
        : (availableCats.isNotEmpty ? availableCats.first : 'Основне меню');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final previewPrice = MoneyFormatter.parseToKopecks(priceCtrl.text);
          final previewCost = MoneyFormatter.parseToKopecks(costCtrl.text);
          final marginKopecks =
              previewPrice > 0 && previewCost > 0 ? previewPrice - previewCost : 0;

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
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dialogHeader(
                      icon: Icons.add_business_rounded,
                      title: 'НОВА ПОЗИЦІЯ В МЕНЮ',
                      subtitle:
                          'Додайте напій, десерт, ігрову годину або подію на вітрину каси',
                      onClose: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ліва частина: форма
                        Expanded(
                          flex: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: nameCtrl,
                                autofocus: true,
                                onChanged: (_) => setDialogState(() {}),
                                style: const TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: _premiumInput(
                                  label: 'Назва товару / послуги',
                                  hint: 'Напр. Лате Солона Карамель / PS5 (1 год)',
                                  icon: Icons.local_cafe_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceCtrl,
                                      onChanged: (_) => setDialogState(() {}),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.,]'),
                                        ),
                                      ],
                                      style: const TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                      decoration: _premiumInput(
                                        label: 'Ціна продажу',
                                        suffixText: 'грн',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: costCtrl,
                                      onChanged: (_) => setDialogState(() {}),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.,]'),
                                        ),
                                      ],
                                      style: const TextStyle(
                                        color: OsnovaTheme.creamText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: _premiumInput(
                                        label: 'Собівартість',
                                        hint: 'Необовʼязково',
                                        suffixText: 'грн',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Швидкі ціни
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [45, 55, 65, 80, 100, 150].map((p) {
                                  return ActionChip(
                                    backgroundColor: const Color(0xFF11261F),
                                    side: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.3),
                                    ),
                                    label: Text(
                                      '$p грн',
                                      style: const TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        priceCtrl.text = p.toString();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'КАТЕГОРІЯ ВІТРИНИ:',
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: availableCats.map((cat) {
                                  final selected = category == cat;
                                  return ChoiceChip(
                                    label: Text(
                                      cat,
                                      style: TextStyle(
                                        color: selected
                                            ? OsnovaTheme.bgDark
                                            : OsnovaTheme.creamText,
                                        fontWeight: selected
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: selected,
                                    selectedColor: OsnovaTheme.gold,
                                    backgroundColor: const Color(0xFF0A1914),
                                    side: BorderSide(
                                      color: selected
                                          ? OsnovaTheme.goldBright
                                          : OsnovaTheme.gold
                                              .withValues(alpha: 0.28),
                                    ),
                                    onSelected: (_) =>
                                        setDialogState(() => category = cat),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Права частина: Живе прев'ю картки товару
                        Expanded(
                          flex: 40,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1914),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'ВИГЛЯД НА КАСІ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: OsnovaTheme.goldBright,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF143126),
                                        Color(0xFF0D2019),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: OsnovaTheme.goldBright
                                          .withValues(alpha: 0.55),
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0A1914),
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        child: Text(
                                          category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        nameCtrl.text.trim().isEmpty
                                            ? 'Назва позиції'
                                            : nameCtrl.text.trim(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: nameCtrl.text.trim().isEmpty
                                              ? OsnovaTheme.sageMuted
                                              : OsnovaTheme.creamText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        MoneyFormatter.format(previewPrice),
                                        style: const TextStyle(
                                          color: OsnovaTheme.goldBright,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (marginKopecks > 0) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: OsnovaTheme.liveGreen
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: OsnovaTheme.liveGreen
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      'Маржа: +${MoneyFormatter.format(marginKopecks)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: OsnovaTheme.liveGreen,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Скасувати',
                            style: TextStyle(color: OsnovaTheme.sageMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _goldPrimaryButton(
                          icon: Icons.add_circle_rounded,
                          label: 'Додати в меню',
                          onPressed: () async {
                            final price =
                                MoneyFormatter.parseToKopecks(priceCtrl.text);
                            final cost =
                                MoneyFormatter.parseToKopecks(costCtrl.text);
                            if (nameCtrl.text.trim().isNotEmpty && price > 0) {
                              await controller.addProduct(
                                nameCtrl.text.trim(),
                                category,
                                price,
                                cost,
                              );
                              if (ctx.mounted) {
                                OsnovaToast.success(
                                  ctx,
                                  'Позицію додано в меню',
                                  subtitle:
                                      '${nameCtrl.text.trim()} • ${MoneyFormatter.format(price)}',
                                );
                                Navigator.pop(ctx);
                              }
                            } else {
                              OsnovaToast.warning(
                                ctx,
                                'Вкажіть назву та ціну позиції',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 4. Внесення витрати (закупівля продуктів, розхідники)
  static Future<void> showExpenseDialog(
    BuildContext context,
    PosController controller,
  ) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String source = 'cash_drawer';

    const quickTemplates = [
      'Молоко',
      'Тости / Хліб',
      'Сир / Шинка',
      'Вода / Лід',
      'Серветки / Розхідники',
      'Таксі / Доставка',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final enteredKopecks = MoneyFormatter.parseToKopecks(amountCtrl.text);
          final exceedsDrawer = source == 'cash_drawer' &&
              enteredKopecks > controller.currentCashInDrawer;

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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dialogHeader(
                      icon: Icons.outbound_rounded,
                      title: 'НОВА ВИТРАТА ЗІ ЗМІНИ',
                      subtitle:
                          'Оперативні закупівлі продуктів, розхідників або оплата послуг',
                      accentColor: Colors.redAccent,
                      onClose: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 14),

                    // Швидкі шаблони
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickTemplates.map((tpl) {
                        return ActionChip(
                          backgroundColor: const Color(0xFF11261F),
                          side: BorderSide(
                            color: OsnovaTheme.gold.withValues(alpha: 0.3),
                          ),
                          label: Text(
                            tpl,
                            style: const TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            setDialogState(() => titleCtrl.text = tpl);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      style: const TextStyle(
                        color: OsnovaTheme.creamText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _premiumInput(
                        label: 'На що витрачено',
                        hint: 'Напр. Тости, Сир, Молоко, Вода...',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: _premiumInput(
                        label: 'Сума витрати',
                        suffixText: 'грн',
                        icon: Icons.payments_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'ДЖЕРЕЛО СПИСАННЯ КОШТІВ:',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _sourceSelectorCard(
                            title: 'З каси (готівка)',
                            subtitle:
                                'Доступно: ${MoneyFormatter.format(controller.currentCashInDrawer)}',
                            icon: Icons.point_of_sale_rounded,
                            isSelected: source == 'cash_drawer',
                            accentColor: OsnovaTheme.goldBright,
                            onTap: () =>
                                setDialogState(() => source = 'cash_drawer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sourceSelectorCard(
                            title: 'З картки / особисті',
                            subtitle: 'Не зменшує готівку в касі',
                            icon: Icons.credit_card_rounded,
                            isSelected: source == 'external',
                            accentColor: const Color(0xFF4FC3F7),
                            onTap: () =>
                                setDialogState(() => source = 'external'),
                          ),
                        ),
                      ],
                    ),

                    if (exceedsDrawer) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orangeAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Увага: сума витрати перевищує поточну готівку в касовій шухляді.',
                                style: TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Скасувати',
                            style: TextStyle(color: OsnovaTheme.sageMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _goldPrimaryButton(
                          icon: Icons.check_circle_rounded,
                          label: 'Зафіксувати витрату',
                          onPressed: () async {
                            final amount =
                                MoneyFormatter.parseToKopecks(amountCtrl.text);
                            if (titleCtrl.text.trim().isNotEmpty &&
                                amount > 0) {
                              await controller.addExpense(
                                titleCtrl.text.trim(),
                                amount,
                                source,
                              );
                              if (ctx.mounted) {
                                OsnovaToast.success(
                                  ctx,
                                  'Витрату збережено',
                                  subtitle:
                                      '${titleCtrl.text.trim()} • -${MoneyFormatter.format(amount)}',
                                );
                                Navigator.pop(ctx);
                              }
                            } else {
                              OsnovaToast.warning(
                                ctx,
                                'Заповніть назву та суму витрати',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _sourceSelectorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF143126)
              : const Color(0xFF0A1914),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : OsnovaTheme.gold.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? accentColor : OsnovaTheme.sageMuted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? OsnovaTheme.creamText
                          : OsnovaTheme.sageMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OsnovaTheme.sageMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Стандартний X-звіт та Z-звіт (ДПС / Poster) + Telegram + Xprinter
  static Future<void> showReportDialog(
    BuildContext context,
    PosController controller, {
    required bool isZReport,
    required void Function(String? error) onPrintFinished,
  }) async {
    final report = await controller.buildReport(isZReport: isZReport);
    if (report == null || !context.mounted) return;

    final standardZ = controller.lastStandardZReport;
    final lines = controller.buildReportReceiptLines(report);
    final hasPrinter = controller.connectedPrinterIp != null;
    final tgConfigured = OsnovaTelegramService.instance.isConfigured;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: OsnovaTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: (isZReport ? OsnovaTheme.goldBright : OsnovaTheme.liveGreen)
                .withValues(alpha: 0.55),
            width: 1.3,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  icon: isZReport
                      ? Icons.lock_clock_rounded
                      : Icons.analytics_rounded,
                  title: isZReport
                      ? 'Z-ЗВІТ • ЗАКРИТТЯ ЗМІНИ №${report.shiftId}'
                      : 'X-ЗВІТ • ПРОМІЖНИЙ ЗВІТ №${report.shiftId}',
                  subtitle: isZReport
                      ? 'Фіскальний підсумок зміни за стандартом ДПС / Poster'
                      : 'Поточний зріз каси без закриття робочої зміни',
                  accentColor: isZReport ? null : OsnovaTheme.liveGreen,
                  onClose: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 14),

                // Швидкі підсумкові KPI-картки звіту
                Row(
                  children: [
                    _miniKpiBox(
                      label: 'Загальна виручка',
                      value: MoneyFormatter.format(report.totalRevenue),
                      valueColor: OsnovaTheme.goldBright,
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(width: 8),
                    _miniKpiBox(
                      label: 'Готівка в касі',
                      value: MoneyFormatter.format(report.expectedCashInDrawer),
                      valueColor: OsnovaTheme.liveGreen,
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(width: 8),
                    _miniKpiBox(
                      label: 'Пробито чеків',
                      value: '${report.ordersCount} шт',
                      valueColor: OsnovaTheme.creamText,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (standardZ != null)
                          StandardZReportView(report: standardZ)
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1914),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              lines.join('\n'),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: OsnovaTheme.creamText,
                              ),
                            ),
                          ),
                        if (isZReport && tgConfigured) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color:
                                  OsnovaTheme.liveGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: OsnovaTheme.liveGreen
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: OsnovaTheme.liveGreen,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Z-звіт автоматично надіслано команді в Telegram. Автозакриття налаштовано на 23:50.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: OsnovaTheme.creamText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!hasPrinter) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: OsnovaTheme.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.print_disabled_outlined,
                                  color: OsnovaTheme.goldBright,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Принтер Xprinter не підключено — звіт можна надіслати файлом у Telegram.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: OsnovaTheme.creamText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Закрити',
                        style: TextStyle(color: OsnovaTheme.sageMuted),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OsnovaTheme.goldBright,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        side: BorderSide(
                          color: OsnovaTheme.gold.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Файл у Telegram',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () async {
                        await controller.exportReportToTelegram(report);
                      },
                    ),
                    const SizedBox(width: 10),
                    _goldPrimaryButton(
                      icon: Icons.print_rounded,
                      label: 'Друк (Xprinter)',
                      onPressed: !hasPrinter
                          ? null
                          : () async {
                              final err =
                                  await controller.printCurrentReceipt();
                              onPrintFinished(err);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isZReport) {
      await controller.initPos();
    }
  }

  /// 6. Редагування характеристик або видалення позиції (по затисканню на картку)
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
      text: product.costPrice > 0
          ? (product.costPrice / 100).toStringAsFixed(2)
          : '',
    );

    final availableCategories =
        controller.categories.where((c) => c != 'Усі').toList();
    String category = availableCategories.contains(product.category)
        ? product.category
        : availableCategories.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final pCents = MoneyFormatter.parseToKopecks(priceCtrl.text);
          final cCents = MoneyFormatter.parseToKopecks(costCtrl.text);
          final margin = pCents > 0 && cCents > 0 ? pCents - cCents : 0;

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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dialogHeader(
                      icon: Icons.edit_note_rounded,
                      title: 'РЕДАГУВАННЯ ПОЗИЦІЇ',
                      subtitle: 'Зміна назви, ціни, собівартості або категорії',
                      onClose: () => Navigator.pop(ctx),
                      trailing: IconButton(
                        tooltip: 'Видалити з меню',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await controller.deleteProduct(product.id);
                          if (ctx.mounted) {
                            OsnovaToast.success(
                              ctx,
                              'Позицію видалено з меню',
                              subtitle: product.name,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                        color: OsnovaTheme.creamText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _premiumInput(
                        label: 'Назва позиції',
                        icon: Icons.local_cafe_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            onChanged: (_) => setDialogState(() {}),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: _premiumInput(
                              label: 'Ціна продажу',
                              suffixText: 'грн',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            onChanged: (_) => setDialogState(() {}),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: _premiumInput(
                              label: 'Собівартість',
                              suffixText: 'грн',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (margin > 0) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Чиста маржа: +${MoneyFormatter.format(margin)}',
                          style: const TextStyle(
                            color: OsnovaTheme.liveGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableCategories.map((c) {
                        final selected = category == c;
                        return ChoiceChip(
                          label: Text(
                            c,
                            style: TextStyle(
                              color: selected
                                  ? OsnovaTheme.bgDark
                                  : OsnovaTheme.creamText,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          selected: selected,
                          selectedColor: OsnovaTheme.gold,
                          backgroundColor: const Color(0xFF0A1914),
                          onSelected: (_) =>
                              setDialogState(() => category = c),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Скасувати',
                            style: TextStyle(color: OsnovaTheme.sageMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _goldPrimaryButton(
                          icon: Icons.save_rounded,
                          label: 'Зберегти зміни',
                          onPressed: () async {
                            final newPrice =
                                MoneyFormatter.parseToKopecks(priceCtrl.text);
                            final newCost =
                                MoneyFormatter.parseToKopecks(costCtrl.text);
                            if (nameCtrl.text.trim().isNotEmpty &&
                                newPrice > 0) {
                              await controller.updateProduct(
                                id: product.id,
                                name: nameCtrl.text.trim(),
                                category: category,
                                priceKopecks: newPrice,
                                costPriceKopecks: newCost,
                              );
                              if (ctx.mounted) {
                                OsnovaToast.success(
                                  ctx,
                                  'Зміни збережено',
                                  subtitle: nameCtrl.text.trim(),
                                );
                                Navigator.pop(ctx);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 7. Налаштування мережевого термопринтера Xprinter (Wi-Fi / LAN 9100)
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
    final manualIpCtrl = TextEditingController(text: current.ip);

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
              if (selectedIp.isEmpty && printers.isNotEmpty) {
                selectedIp = printers.first;
                manualIpCtrl.text = selectedIp;
              }
            });
          }

          if (!scanStarted) {
            scanStarted = true;
            Future.microtask(runScan);
          }

          final activeIp = manualIpCtrl.text.trim().isNotEmpty
              ? manualIpCtrl.text.trim()
              : selectedIp;

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
              constraints: const BoxConstraints(maxWidth: 510),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dialogHeader(
                      icon: Icons.print_rounded,
                      title: 'ТЕРМОПРИНТЕР XPRINTER',
                      subtitle:
                          'Автопошук у Wi-Fi мережі та налаштування ширини чека',
                      onClose: () => Navigator.pop(ctx),
                      trailing: IconButton(
                        tooltip: 'Оновити пошук у мережі',
                        onPressed: isScanning ? null : runScan,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: OsnovaTheme.goldBright,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Секція автопошуку принтерів
                    if (isScanning)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1914),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: OsnovaTheme.goldBright,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Сканування локальної мережі (порт 9100)...',
                              style: TextStyle(
                                color: OsnovaTheme.creamText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (foundPrinters.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: OsnovaTheme.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OsnovaTheme.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.wifi_find_rounded,
                              color: OsnovaTheme.goldBright,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Автопошук не знайшов принтер. Перевірте живлення Xprinter або вкажіть IP-адресу вручну нижче.',
                                style: TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const Text(
                        'ЗНАЙДЕНІ ПРИСТРОЇ В МЕРЕЖІ:',
                        style: TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...foundPrinters.map((ip) {
                        final isSelected = ip == activeIp;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setDialogState(() {
                              selectedIp = ip;
                              manualIpCtrl.text = ip;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF143126)
                                    : const Color(0xFF0A1914),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? OsnovaTheme.goldBright
                                      : OsnovaTheme.gold.withValues(alpha: 0.25),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.print_rounded,
                                      color: OsnovaTheme.goldBright,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xprinter ($ip)',
                                          style: const TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Text(
                                          'TCP/IP RAW • Порт 9100',
                                          style: TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: OsnovaTheme.liveGreen,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 12),

                    // Поле ручного вводу IP
                    TextField(
                      controller: manualIpCtrl,
                      onChanged: (v) => setDialogState(() => selectedIp = v.trim()),
                      style: const TextStyle(
                        color: OsnovaTheme.creamText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _premiumInput(
                        label: 'IP-адреса принтера',
                        hint: 'Напр. 192.168.0.105',
                        icon: Icons.lan_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'ШИРИНА ТЕРМОСТРІЧКИ:',
                      style: TextStyle(
                        color: OsnovaTheme.sageMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _sourceSelectorCard(
                            title: '80 мм (Широка)',
                            subtitle: 'Повноформатний чек OSNOVA',
                            icon: Icons.receipt_long_rounded,
                            isSelected: is80mm,
                            accentColor: OsnovaTheme.goldBright,
                            onTap: () => setDialogState(() => is80mm = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sourceSelectorCard(
                            title: '58 мм (Компактна)',
                            subtitle: 'Вузька касова стрічка',
                            icon: Icons.receipt_outlined,
                            isSelected: !is80mm,
                            accentColor: OsnovaTheme.goldBright,
                            onTap: () => setDialogState(() => is80mm = false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        if (activeIp.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await controller.clearPrinterSettings();
                              setDialogState(() {
                                selectedIp = '';
                                manualIpCtrl.clear();
                              });
                            },
                            child: const Text(
                              'Відключити',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const Spacer(),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: OsnovaTheme.goldBright,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            side: BorderSide(
                              color: OsnovaTheme.gold.withValues(alpha: 0.45),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: activeIp.isEmpty
                              ? null
                              : () async {
                                  await controller.savePrinterSettings(
                                    ip: activeIp,
                                    is80mm: is80mm,
                                  );
                                  controller.prepareTestReceipt(activeIp);
                                  final err =
                                      await controller.printCurrentReceipt();
                                  onPrintFinished(err);
                                },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text(
                            'Тест друку',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _goldPrimaryButton(
                          icon: Icons.check_circle_rounded,
                          label: 'Зберегти',
                          onPressed: activeIp.isEmpty
                              ? null
                              : () async {
                                  await controller.savePrinterSettings(
                                    ip: activeIp,
                                    is80mm: is80mm,
                                  );
                                  if (ctx.mounted) {
                                    OsnovaToast.success(
                                      ctx,
                                      'Принтер Xprinter збережено',
                                      subtitle:
                                          '$activeIp • ${is80mm ? '80 мм' : '58 мм'}',
                                    );
                                    Navigator.pop(ctx);
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}