import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import 'osnova_toast.dart';

enum AbcPeriodMode {
  day,
  week,
  month,
  last30Days,
  custom,
}

enum AbcSortMetric {
  revenue,
  quantity,
}

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
  final double sharePercent;
  final double cumulativePercent;
  final String group; // 'A', 'B', 'C'

  const AbcItemResult({
    required this.stat,
    required this.sharePercent,
    required this.cumulativePercent,
    required this.group,
  });
}

class AbcAnalyzer {
  static List<AbcItemResult> analyze(
    List<ProductSalesStat> items, {
    AbcSortMetric metric = AbcSortMetric.revenue,
  }) {
    final sorted = List<ProductSalesStat>.from(items)
      ..sort((a, b) {
        if (metric == AbcSortMetric.quantity) {
          final cmp = b.qtySold.compareTo(a.qtySold);
          return cmp != 0 ? cmp : b.revenueCents.compareTo(a.revenueCents);
        }
        return b.revenueCents.compareTo(a.revenueCents);
      });

    final totalValue = sorted.fold<int>(
      0,
      (sum, item) =>
          sum + (metric == AbcSortMetric.quantity ? item.qtySold : item.revenueCents),
    );
    if (totalValue <= 0) return [];

    double cumulative = 0.0;
    final results = <AbcItemResult>[];

    for (final item in sorted) {
      final value =
          metric == AbcSortMetric.quantity ? item.qtySold : item.revenueCents;
      final share = (value / totalValue) * 100.0;
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
          sharePercent: share,
          cumulativePercent: cumulative.clamp(0.0, 100.0),
          group: group,
        ),
      );
    }

    return results;
  }
}

typedef AbcRangeLoader = Future<List<ProductSalesStat>> Function(
  DateTime start,
  DateTime end,
);

class AbcAnalyticsDialog extends StatefulWidget {
  final List<ProductSalesStat> salesData;
  final String periodTitle;
  final AbcRangeLoader? onLoadRange;

  const AbcAnalyticsDialog({
    super.key,
    required this.salesData,
    this.periodTitle = 'За останні 30 днів',
    this.onLoadRange,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ProductSalesStat> salesData,
    String periodTitle = 'За останні 30 днів',
    AbcRangeLoader? onLoadRange,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AbcAnalyticsDialog(
        salesData: salesData,
        periodTitle: periodTitle,
        onLoadRange: onLoadRange,
      ),
    );
  }

  @override
  State<AbcAnalyticsDialog> createState() => _AbcAnalyticsDialogState();
}

class _AbcAnalyticsDialogState extends State<AbcAnalyticsDialog> {
  static const List<String> _ukMonths = [
    'Січень',
    'Лютий',
    'Березень',
    'Квітень',
    'Травень',
    'Червень',
    'Липень',
    'Серпень',
    'Вересень',
    'Жовтень',
    'Листопад',
    'Грудень',
  ];

  late List<ProductSalesStat> _currentData;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  AbcPeriodMode _periodMode = AbcPeriodMode.last30Days;
  AbcSortMetric _metric = AbcSortMetric.revenue;
  String _selectedGroup = 'ALL'; // ALL, A, B, C
  String _selectedCategory = 'ALL';
  bool _isLoading = false;

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  bool get _canShiftForward {
    final today = _todayStart;
    switch (_periodMode) {
      case AbcPeriodMode.day:
        return !_rangeStart.add(const Duration(days: 1)).isAfter(today);
      case AbcPeriodMode.week:
        return !_rangeStart.add(const Duration(days: 7)).isAfter(today);
      case AbcPeriodMode.month:
        final nextMonth = DateTime(_rangeStart.year, _rangeStart.month + 1, 1);
        return !nextMonth.isAfter(today);
      case AbcPeriodMode.last30Days:
        return !_rangeStart.add(const Duration(days: 30)).isAfter(today);
      case AbcPeriodMode.custom:
        final spanDays = _rangeEnd.difference(_rangeStart).inDays + 1;
        return !_rangeStart.add(Duration(days: spanDays)).isAfter(today);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentData = widget.salesData;
    _rangeEnd = _todayEnd;
    _rangeStart = _todayStart.subtract(const Duration(days: 29));
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String _buildPeriodSubtitle() {
    switch (_periodMode) {
      case AbcPeriodMode.day:
        return 'День: ${_fmtDate(_rangeStart)}';
      case AbcPeriodMode.week:
        return 'Тиждень: ${_fmtDate(_rangeStart)} — ${_fmtDate(_rangeEnd)}';
      case AbcPeriodMode.month:
        return '${_ukMonths[_rangeStart.month - 1]} ${_rangeStart.year} (${_fmtDate(_rangeStart)} — ${_fmtDate(_rangeEnd)})';
      case AbcPeriodMode.last30Days:
        return 'Останні 30 днів (${_fmtDate(_rangeStart)} — ${_fmtDate(_rangeEnd)})';
      case AbcPeriodMode.custom:
        return 'Обраний період: ${_fmtDate(_rangeStart)} — ${_fmtDate(_rangeEnd)}';
    }
  }

  Future<void> _applyPeriod(
    AbcPeriodMode mode, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final todayStart = _todayStart;
    final todayEnd = _todayEnd;

    late DateTime start;
    late DateTime end;

    switch (mode) {
      case AbcPeriodMode.day:
        start = customStart ?? todayStart;
        end = DateTime(start.year, start.month, start.day, 23, 59, 59);
        break;
      case AbcPeriodMode.week:
        final anchor = customStart ?? todayStart;
        final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        final sunday = start.add(const Duration(days: 6));
        end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        break;
      case AbcPeriodMode.month:
        final anchor = customStart ?? todayStart;
        start = DateTime(anchor.year, anchor.month, 1);
        final lastDay = DateTime(anchor.year, anchor.month + 1, 0);
        end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
        break;
      case AbcPeriodMode.last30Days:
        start = todayStart.subtract(const Duration(days: 29));
        end = todayEnd;
        break;
      case AbcPeriodMode.custom:
        start = customStart ?? _rangeStart;
        end = customEnd ?? _rangeEnd;
        break;
    }

    // Не дозволяємо виходити за межі сьогоднішнього дня
    if (start.isAfter(todayStart)) {
      start = todayStart;
    }
    if (end.isAfter(todayEnd)) {
      end = todayEnd;
    }
    if (end.isBefore(start)) {
      end = DateTime(start.year, start.month, start.day, 23, 59, 59);
    }

    setState(() {
      _periodMode = mode;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedCategory = 'ALL';
      _selectedGroup = 'ALL';
    });

    await _reloadData();
  }

  Future<void> _shiftPeriod(int direction) async {
    if (direction > 0 && !_canShiftForward) return;
    HapticFeedback.selectionClick();

    switch (_periodMode) {
      case AbcPeriodMode.day:
        final nextDay = _rangeStart.add(Duration(days: direction));
        await _applyPeriod(AbcPeriodMode.day, customStart: nextDay);
        break;
      case AbcPeriodMode.week:
        final nextWeek = _rangeStart.add(Duration(days: 7 * direction));
        await _applyPeriod(AbcPeriodMode.week, customStart: nextWeek);
        break;
      case AbcPeriodMode.month:
        final nextMonth =
            DateTime(_rangeStart.year, _rangeStart.month + direction, 1);
        await _applyPeriod(AbcPeriodMode.month, customStart: nextMonth);
        break;
      case AbcPeriodMode.last30Days:
        final nextStart = _rangeStart.add(Duration(days: 30 * direction));
        final nextEnd = DateTime(
          nextStart.year,
          nextStart.month,
          nextStart.day,
          23,
          59,
          59,
        ).add(const Duration(days: 29));
        await _applyPeriod(
          AbcPeriodMode.custom,
          customStart: nextStart,
          customEnd: nextEnd,
        );
        break;
      case AbcPeriodMode.custom:
        final spanDays = _rangeEnd.difference(_rangeStart).inDays + 1;
        final nextStart =
            _rangeStart.add(Duration(days: spanDays * direction));
        final nextEnd = DateTime(
          nextStart.year,
          nextStart.month,
          nextStart.day,
          23,
          59,
          59,
        ).add(Duration(days: spanDays - 1));
        await _applyPeriod(
          AbcPeriodMode.custom,
          customStart: nextStart,
          customEnd: nextEnd,
        );
        break;
    }
  }

  Future<void> _pickCustomRange() async {
    final today = _todayStart;
    var initStart =
        DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    var initEnd = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);

    if (initStart.isAfter(today)) initStart = today;
    if (initEnd.isAfter(today)) initEnd = today;
    if (initEnd.isBefore(initStart)) initEnd = initStart;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: today,
      initialDateRange: DateTimeRange(start: initStart, end: initEnd),
      helpText: 'ОБЕРІТЬ ПЕРІОД ДО СЬОГОДНІШНЬОГО ДНЯ',
      saveText: 'ЗАСТОСУВАТИ',
      builder: (context, child) {
        return Theme(
          data: OsnovaTheme.buildTheme(),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final rawEnd = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
    );
    final end = rawEnd.isAfter(_todayEnd) ? _todayEnd : rawEnd;

    await _applyPeriod(
      AbcPeriodMode.custom,
      customStart: start,
      customEnd: end,
    );
  }

  Future<void> _reloadData() async {
    if (widget.onLoadRange == null) return;
    setState(() => _isLoading = true);
    try {
      final fresh = await widget.onLoadRange!(_rangeStart, _rangeEnd);
      if (!mounted) return;
      setState(() {
        _currentData = fresh;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Color _groupColor(String group) {
    switch (group) {
      case 'A':
        return OsnovaTheme.liveGreen;
      case 'B':
        return OsnovaTheme.goldBright;
      default:
        return const Color(0xFFFB923C);
    }
  }

  String _groupHint(String group) {
    switch (group) {
      case 'A':
        return 'Топ-позиція (80% каси) — тримати в наявності';
      case 'B':
        return 'Стабільний попит (15% каси)';
      default:
        return 'Низький попит (5% каси) — перегляд або акція';
    }
  }

  Future<void> _copyReportToClipboard(
    List<AbcItemResult> analyzed,
    int totalRevenueCents,
    int totalUnits,
  ) async {
    if (analyzed.isEmpty) return;
    final buf = StringBuffer()
      ..writeln('📊 ABC-АНАЛІЗ OSNOVA')
      ..writeln('📅 ${_buildPeriodSubtitle()}')
      ..writeln(
        '💰 Каса: ${MoneyFormatter.format(totalRevenueCents)} • Продано: $totalUnits шт.',
      )
      ..writeln();

    for (final grp in ['A', 'B', 'C']) {
      final grpItems = analyzed.where((e) => e.group == grp).toList();
      if (grpItems.isEmpty) continue;
      buf.writeln('▪ Група $grp (${grpItems.length} поз.):');
      for (final item in grpItems.take(8)) {
        buf.writeln(
          '  • ${item.stat.name} — ${MoneyFormatter.formatShort(item.stat.revenueCents)} (${item.stat.qtySold} шт., ${item.sharePercent.toStringAsFixed(1)}%)',
        );
      }
      if (grpItems.length > 8) {
        buf.writeln('  ... та ще ${grpItems.length - 8} поз.');
      }
    }

    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    OsnovaToast.success(
      context,
      'Звіт скопійовано в буфер обміну',
      subtitle: 'Можна вставити в Telegram',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = OsnovaTheme.isNeon;
    final canGoForward = _canShiftForward;

    final categories = <String>{
      'ALL',
      ..._currentData.map((e) => e.category).where((c) => c.trim().isNotEmpty),
    }.toList();

    final categoryFiltered = _selectedCategory == 'ALL'
        ? _currentData
        : _currentData
            .where((e) => e.category == _selectedCategory)
            .toList();

    final analyzed = AbcAnalyzer.analyze(categoryFiltered, metric: _metric);

    final countA = analyzed.where((e) => e.group == 'A').length;
    final countB = analyzed.where((e) => e.group == 'B').length;
    final countC = analyzed.where((e) => e.group == 'C').length;

    final totalRevenueCents =
        categoryFiltered.fold<int>(0, (sum, item) => sum + item.revenueCents);
    final totalUnits =
        categoryFiltered.fold<int>(0, (sum, item) => sum + item.qtySold);

    final shareA = analyzed
        .where((e) => e.group == 'A')
        .fold<double>(0, (s, e) => s + e.sharePercent);
    final shareB = analyzed
        .where((e) => e.group == 'B')
        .fold<double>(0, (s, e) => s + e.sharePercent);
    final shareC = analyzed
        .where((e) => e.group == 'C')
        .fold<double>(0, (s, e) => s + e.sharePercent);

    final visible = _selectedGroup == 'ALL'
        ? analyzed
        : analyzed.where((e) => e.group == _selectedGroup).toList();

    final dialogShape = OsnovaTheme.adaptiveShape(
      radius: 22,
      bevel: 14,
      side: BorderSide(
        color: (isNeon ? OsnovaTheme.neonGlow : OsnovaTheme.gold)
            .withValues(alpha: 0.55),
        width: 1.4,
      ),
    );

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      shape: dialogShape,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 680),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: dialogShape),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Заголовок + дії
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: ShapeDecoration(
                        shape: OsnovaTheme.adaptiveShape(
                          radius: 12,
                          bevel: 7,
                        ),
                        gradient: OsnovaTheme.goldGradient,
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: OsnovaTheme.bgDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 2),
                          Text(
                            _buildPeriodSubtitle(),
                            style: TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: OsnovaTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (analyzed.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OsnovaTheme.goldBright,
                          side: BorderSide(
                            color: OsnovaTheme.gold.withValues(alpha: 0.45),
                          ),
                          shape: OsnovaTheme.adaptiveShape(
                            radius: 10,
                            bevel: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                        ),
                        onPressed: () => _copyReportToClipboard(
                          analyzed,
                          totalRevenueCents,
                          totalUnits,
                        ),
                        icon: const Icon(Icons.copy_all_rounded, size: 17),
                        label: const Text(
                          'Звіт у ТГ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: OsnovaTheme.sageMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Панель вибору періоду
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: ShapeDecoration(
                    shape: OsnovaTheme.adaptiveShape(
                      radius: 14,
                      bevel: 8,
                      side: BorderSide(
                        color: OsnovaTheme.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    color: OsnovaTheme.bgDark.withValues(alpha: 0.72),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _periodButton(AbcPeriodMode.day, 'День'),
                              const SizedBox(width: 6),
                              _periodButton(AbcPeriodMode.week, 'Тиждень'),
                              const SizedBox(width: 6),
                              _periodButton(AbcPeriodMode.month, 'Місяць'),
                              const SizedBox(width: 6),
                              _periodButton(
                                AbcPeriodMode.last30Days,
                                '30 днів',
                              ),
                              const SizedBox(width: 6),
                              _customDateButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Кнопки гортання періоду назад / вперед
                      Container(
                        decoration: ShapeDecoration(
                          shape: OsnovaTheme.adaptiveShape(
                            radius: 10,
                            bevel: 6,
                            side: BorderSide(
                              color: OsnovaTheme.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          color: OsnovaTheme.surfaceCard,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Попередній період',
                              visualDensity: VisualDensity.compact,
                              onPressed:
                                  _isLoading ? null : () => _shiftPeriod(-1),
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: OsnovaTheme.goldBright,
                                size: 22,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 18,
                              color: OsnovaTheme.gold.withValues(alpha: 0.25),
                            ),
                            IconButton(
                              tooltip: canGoForward
                                  ? 'Наступний період'
                                  : 'Майбутній період ще не настав',
                              visualDensity: VisualDensity.compact,
                              onPressed: (_isLoading || !canGoForward)
                                  ? null
                                  : () => _shiftPeriod(1),
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: canGoForward
                                    ? OsnovaTheme.goldBright
                                    : OsnovaTheme.sageMuted
                                        .withValues(alpha: 0.3),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: OsnovaTheme.bgDeep,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(OsnovaTheme.goldBright),
                    ),
                  ),

                const SizedBox(height: 10),

                // 3. Зведені KPI картки + шкала розподілу Парето
                if (analyzed.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          label: 'ВИРУЧКА ЗА ПЕРІОД',
                          value: MoneyFormatter.format(totalRevenueCents),
                          accent: OsnovaTheme.goldBright,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiTile(
                          label: 'ПРОДАНО ОДИНИЦЬ',
                          value: '$totalUnits шт.',
                          subValue: totalUnits > 0
                              ? 'Сер. ціна: ${MoneyFormatter.formatShort((totalRevenueCents / totalUnits).round())}'
                              : null,
                          accent: OsnovaTheme.liveGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: ShapeDecoration(
                            shape: OsnovaTheme.adaptiveShape(
                              radius: 12,
                              bevel: 7,
                              side: BorderSide(
                                color: OsnovaTheme.gold.withValues(alpha: 0.24),
                              ),
                            ),
                            color: OsnovaTheme.bgDark.withValues(alpha: 0.68),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'СТРУКТУРА ПАРЕТО (A / B / C)',
                                    style: TextStyle(
                                      color: OsnovaTheme.sageMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Text(
                                    '${shareA.toStringAsFixed(0)}% / ${shareB.toStringAsFixed(0)}% / ${shareC.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: OsnovaTheme.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      if (shareA > 0)
                                        Expanded(
                                          flex: (shareA * 10)
                                              .round()
                                              .clamp(1, 1000),
                                          child: Container(
                                            color: _groupColor('A'),
                                          ),
                                        ),
                                      if (shareB > 0)
                                        Expanded(
                                          flex: (shareB * 10)
                                              .round()
                                              .clamp(1, 1000),
                                          child: Container(
                                            color: _groupColor('B'),
                                          ),
                                        ),
                                      if (shareC > 0)
                                        Expanded(
                                          flex: (shareC * 10)
                                              .round()
                                              .clamp(1, 1000),
                                          child: Container(
                                            color: _groupColor('C'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. Фільтри груп A/B/C + Категорія + Метрика сортування
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _groupChip('ALL', 'Усі (${analyzed.length})'),
                            const SizedBox(width: 6),
                            _groupChip('A', 'A • Лідери ($countA)'),
                            const SizedBox(width: 6),
                            _groupChip('B', 'B • Середні ($countB)'),
                            const SizedBox(width: 6),
                            _groupChip('C', 'C • Слабкі ($countC)'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (categories.length > 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: ShapeDecoration(
                          shape: OsnovaTheme.adaptiveShape(
                            radius: 10,
                            bevel: 6,
                            side: BorderSide(
                              color: OsnovaTheme.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          color: OsnovaTheme.bgDark,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : 'ALL',
                            dropdownColor: OsnovaTheme.surfaceCard,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: OsnovaTheme.goldBright,
                              size: 18,
                            ),
                            style: TextStyle(
                              color: OsnovaTheme.creamText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat == 'ALL' ? 'Усі категорії' : cat,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedCategory = val;
                                _selectedGroup = 'ALL';
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: ShapeDecoration(
                        shape: OsnovaTheme.adaptiveShape(
                          radius: 10,
                          bevel: 6,
                          side: BorderSide(
                            color: OsnovaTheme.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        color: OsnovaTheme.bgDark,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _metricBtn(AbcSortMetric.revenue, '₴ Каса'),
                          _metricBtn(AbcSortMetric.quantity, '№ Шт.'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Список товарів
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.query_stats_rounded,
                                size: 44,
                                color: OsnovaTheme.gold.withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Недостатньо даних продажів за обраний період',
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_periodMode != AbcPeriodMode.last30Days &&
                                  widget.onLoadRange != null) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: OsnovaTheme.goldBright,
                                    side: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _applyPeriod(AbcPeriodMode.last30Days),
                                  icon: const Icon(
                                    Icons.history_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Показати за останні 30 днів'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final item = visible[idx];
                            final color = _groupColor(item.group);
                            final rank = analyzed.indexOf(item) + 1;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: ShapeDecoration(
                                shape: OsnovaTheme.adaptiveShape(
                                  radius: 14,
                                  bevel: 8,
                                  side: BorderSide(
                                    color: color.withValues(alpha: 0.42),
                                  ),
                                ),
                                color: OsnovaTheme.bgDark.withValues(alpha: 0.74),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: ShapeDecoration(
                                      shape: OsnovaTheme.adaptiveShape(
                                        radius: 10,
                                        bevel: 6,
                                        side: BorderSide(color: color),
                                      ),
                                      color: color.withValues(alpha: 0.16),
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
                                        Row(
                                          children: [
                                            Text(
                                              '#$rank ',
                                              style: TextStyle(
                                                color: OsnovaTheme.sageMuted,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                                fontFeatures:
                                                    OsnovaTheme.tabularFigures,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item.stat.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: OsnovaTheme.creamText,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${item.stat.category} • ${_groupHint(item.group)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: (item.sharePercent / 100.0)
                                                .clamp(0.02, 1.0),
                                            minHeight: 4,
                                            backgroundColor:
                                                OsnovaTheme.surfaceCard,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                          fontSize: 14.5,
                                          fontFeatures:
                                              OsnovaTheme.tabularFigures,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.stat.qtySold} шт. • ${item.sharePercent.toStringAsFixed(1)}% (накоп. ${item.cumulativePercent.toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          color: OsnovaTheme.sageMuted,
                                          fontSize: 11.5,
                                          fontFeatures:
                                              OsnovaTheme.tabularFigures,
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
      ),
    );
  }

  Widget _periodButton(AbcPeriodMode mode, String label) {
    final active = _periodMode == mode;
    final shape = OsnovaTheme.adaptiveShape(
      radius: 10,
      bevel: 6,
      side: BorderSide(
        color: active
            ? OsnovaTheme.goldBright
            : OsnovaTheme.gold.withValues(alpha: 0.25),
      ),
    );

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              _applyPeriod(mode);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: ShapeDecoration(
          shape: shape,
          gradient: active ? OsnovaTheme.goldGradient : null,
          color: active ? null : OsnovaTheme.surfaceCard,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OsnovaTheme.bgDark : OsnovaTheme.creamText,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _customDateButton() {
    final active = _periodMode == AbcPeriodMode.custom;
    final shape = OsnovaTheme.adaptiveShape(
      radius: 10,
      bevel: 6,
      side: BorderSide(
        color: active
            ? OsnovaTheme.goldBright
            : OsnovaTheme.gold.withValues(alpha: 0.35),
      ),
    );

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              _pickCustomRange();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: ShapeDecoration(
          shape: shape,
          gradient: active ? OsnovaTheme.goldGradient : null,
          color: active ? null : OsnovaTheme.surfaceCard,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: active ? OsnovaTheme.bgDark : OsnovaTheme.goldBright,
            ),
            const SizedBox(width: 5),
            Text(
              'Обрати дати',
              style: TextStyle(
                color: active ? OsnovaTheme.bgDark : OsnovaTheme.goldBright,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupChip(String code, String label) {
    final active = _selectedGroup == code;
    final chipColor = code == 'ALL' ? OsnovaTheme.gold : _groupColor(code);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: active ? OsnovaTheme.bgDark : OsnovaTheme.creamText,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
          fontFeatures: OsnovaTheme.tabularFigures,
        ),
      ),
      selected: active,
      selectedColor: chipColor,
      backgroundColor: OsnovaTheme.bgDark,
      side: BorderSide(
        color: active ? chipColor : chipColor.withValues(alpha: 0.35),
      ),
      shape: OsnovaTheme.adaptiveShape(radius: 10, bevel: 6),
      onSelected: (_) => setState(() => _selectedGroup = code),
    );
  }

  Widget _metricBtn(AbcSortMetric metric, String label) {
    final active = _metric == metric;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _metric = metric);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: ShapeDecoration(
          shape: OsnovaTheme.adaptiveShape(radius: 8, bevel: 5),
          color: active ? OsnovaTheme.gold : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OsnovaTheme.bgDark : OsnovaTheme.sageMuted,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color accent;

  const _KpiTile({
    required this.label,
    required this.value,
    this.subValue,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        shape: OsnovaTheme.adaptiveShape(
          radius: 12,
          bevel: 7,
          side: BorderSide(
            color: accent.withValues(alpha: 0.32),
          ),
        ),
        color: OsnovaTheme.bgDark.withValues(alpha: 0.68),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: OsnovaTheme.sageMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFeatures: OsnovaTheme.tabularFigures,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 1),
            Text(
              subValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OsnovaTheme.sageMuted.withValues(alpha: 0.8),
                fontSize: 10.5,
                fontFeatures: OsnovaTheme.tabularFigures,
              ),
            ),
          ],
        ],
      ),
    );
  }
}