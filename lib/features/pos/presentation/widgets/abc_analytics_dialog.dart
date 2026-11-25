import 'package:flutter/material.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';

class ProductSalesStat {
  final String name;
  final String category;
  final int qtySold;
  final int revenueCents;

  const ProductSalesStat({
    required this.name,
    required this.category,
    required this.qtySold,
    required this.revenueCents,
  });
}

class AbcItemResult {
  final ProductSalesStat stat;
  final double revenueSharePercent;
  final double cumulativePercent;
  final String group; // 'A', 'B', 'C'

  const AbcItemResult({
    required this.stat,
    required this.revenueSharePercent,
    required this.cumulativePercent,
    required this.group,
  });
}

class AbcAnalyzer {
  static List<AbcItemResult> analyze(List<ProductSalesStat> items) {
    final sorted = List<ProductSalesStat>.from(items)
      ..sort((a, b) => b.revenueCents.compareTo(a.revenueCents));

    final totalRevenue =
        sorted.fold<int>(0, (sum, item) => sum + item.revenueCents);
    if (totalRevenue <= 0) return [];

    double cumulative = 0.0;
    final results = <AbcItemResult>[];

    for (final item in sorted) {
      final share = (item.revenueCents / totalRevenue) * 100.0;
      cumulative += share;

      final String group;
      if (cumulative <= 80.0 || results.isEmpty) {
        group = 'A';
      } else if (cumulative <= 95.0) {
        group = 'B';
      } else {
        group = 'C';
      }

      results.add(
        AbcItemResult(
          stat: item,
          revenueSharePercent: share,
          cumulativePercent: cumulative.clamp(0.0, 100.0),
          group: group,
        ),
      );
    }

    return results;
  }
}

class AbcAnalyticsDialog extends StatefulWidget {
  final List<ProductSalesStat> salesData;
  final String periodTitle;

  const AbcAnalyticsDialog({
    super.key,
    required this.salesData,
    this.periodTitle = 'За поточний місяць',
  });

  static Future<void> show(
    BuildContext context, {
    required List<ProductSalesStat> salesData,
    String periodTitle = 'За поточний місяць',
  }) {
    return showDialog(
      context: context,
      builder: (_) => AbcAnalyticsDialog(
        salesData: salesData,
        periodTitle: periodTitle,
      ),
    );
  }

  @override
  State<AbcAnalyticsDialog> createState() => _AbcAnalyticsDialogState();
}

class _AbcAnalyticsDialogState extends State<AbcAnalyticsDialog> {
  String _selectedFilter = 'ALL'; // ALL, A, B, C

  Color _groupColor(String group) {
    switch (group) {
      case 'A':
        return OsnovaTheme.liveGreen;
      case 'B':
        return OsnovaTheme.goldBright;
      default:
        return Colors.orangeAccent;
    }
  }

  String _groupHint(String group) {
    switch (group) {
      case 'A':
        return 'Топ-позиція (80% каси) — завжди тримати в наявності';
      case 'B':
        return 'Стабільний попит (15% каси)';
      default:
        return 'Низький попит (5% каси) — кандидат на акцію або перегляд';
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyzed = AbcAnalyzer.analyze(widget.salesData);
    final countA = analyzed.where((e) => e.group == 'A').length;
    final countB = analyzed.where((e) => e.group == 'B').length;
    final countC = analyzed.where((e) => e.group == 'C').length;

    final visible = _selectedFilter == 'ALL'
        ? analyzed
        : analyzed.where((e) => e.group == _selectedFilter).toList();

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.45)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ABC-АНАЛІЗ ПРОДАЖІВ ТОВАРІВ',
                        style: TextStyle(
                          color: OsnovaTheme.goldBright,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        widget.periodTitle,
                        style: TextStyle(
                          color: OsnovaTheme.sageMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
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

              // Фільтри груп A / B / C
              Wrap(
                spacing: 8,
                children: [
                  _filterChip('ALL', 'Усі (${analyzed.length})'),
                  _filterChip('A', 'Група A • Лідери ($countA)'),
                  _filterChip('B', 'Група B • Середні ($countB)'),
                  _filterChip('C', 'Група C • Слабкі ($countC)'),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          'Недостатньо даних продажів для ABC-аналізу',
                          style: TextStyle(color: OsnovaTheme.sageMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = visible[idx];
                          final color = _groupColor(item.group);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: OsnovaTheme.bgDark.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(
                                    item.group,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.stat.name,
                                        style: TextStyle(
                                          color: OsnovaTheme.creamText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${item.stat.category} •${_groupHint(item.group)}',
                                        style: TextStyle(
                                          color: OsnovaTheme.sageMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      MoneyFormatter.format(
                                        item.stat.revenueCents,
                                      ),
                                      style: TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${item.stat.qtySold} шт • ${item.revenueSharePercent.toStringAsFixed(1)}\% (накоп. ${item.cumulativePercent.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: OsnovaTheme.sageMuted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String code, String label) {
    final active = _selectedFilter == code;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: active ? OsnovaTheme.bgDark : OsnovaTheme.creamText,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
      selected: active,
      selectedColor: OsnovaTheme.gold,
      backgroundColor: OsnovaTheme.bgDark,
      onSelected: (_) => setState(() => _selectedFilter = code),
    );
  }
}