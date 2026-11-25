import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../widgets/osnova_toast.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  static const List<String> _monthNames = [
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

  late int _selectedYear;
  late int _selectedMonth;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedSupplierFilter;

  final TextEditingController _searchCtrl = TextEditingController();
  DbRowList _purchases = [];
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await PosLocalDataSource.instance.getPurchasesByMonth(
      year: _selectedYear,
      month: _selectedMonth,
    );
    if (!mounted) return;
    setState(() {
      _purchases = data;
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    var newMonth = _selectedMonth + delta;
    var newYear = _selectedYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
      _expandedIds.clear();
      _selectedCategoryFilter = null;
      _selectedSupplierFilter = null;
    });
    _loadData();
  }

  void _jumpToCurrentMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      _selectedYear = now.year;
      _selectedMonth = now.month;
      _expandedIds.clear();
      _selectedCategoryFilter = null;
      _selectedSupplierFilter = null;
    });
    _loadData();
  }

  Future<void> _openPurchaseEditor({DbRow? existingPurchase}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PurchaseEditorDialog(
        existingPurchase: existingPurchase,
      ),
    );
    if (saved == true) {
      await _loadData();
    }
  }

  void _toggleExpand(int id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _toggleExpandAll(DbRowList visiblePurchases) {
    final allExpanded = visiblePurchases.isNotEmpty &&
        visiblePurchases.every((p) => _expandedIds.contains(p['id'] as int));

    setState(() {
      if (allExpanded) {
        _expandedIds.clear();
      } else {
        for (final p in visiblePurchases) {
          _expandedIds.add(p['id'] as int);
        }
      }
    });
  }

  Future<void> _confirmDeletePurchase(int id, String supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OsnovaTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.4)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'Видалити накладну?',
              style: TextStyle(
                color: OsnovaTheme.creamText,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Накладну від «$supplier» буде видалено без можливості відновлення.',
          style: const TextStyle(color: OsnovaTheme.sageMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: OsnovaTheme.sageMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Видалити',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PosLocalDataSource.instance.deletePurchase(id);
      _expandedIds.remove(id);
      if (mounted) {
        OsnovaToast.success(
          context,
          'Накладну видалено',
          subtitle: supplier,
        );
      }
      await _loadData();
    }
  }

  String _formatDateUa(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('стакан') || lower.contains('розхід')) {
      return Icons.coffee_maker_outlined;
    }
    if (lower.contains('чаї') ||
        lower.contains('кава') ||
        lower.contains('сироп')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('вода') || lower.contains('напо')) {
      return Icons.water_drop_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    int monthTotal = 0;
    int totalItemsCount = 0;
    int matchedItemTotal = 0;
    final categoryTotals = <String, int>{};
    final supplierTotals = <String, int>{};

    final query = _searchQuery.trim().toLowerCase();

    for (final purchase in _purchases) {
      final pTotal = (purchase['total_amount'] as int?) ?? 0;
      monthTotal += pTotal;

      final supplier = (purchase['supplier'] as String?) ?? 'Інший';
      supplierTotals[supplier] = (supplierTotals[supplier] ?? 0) + pTotal;

      final items = (purchase['items'] as List).cast<DbRow>();
      totalItemsCount += items.length;
      for (final item in items) {
        final cat = (item['category'] as String?) ?? 'Інше';
        final itemTotal = (item['total_price'] as int?) ?? 0;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + itemTotal;

        if (query.isNotEmpty &&
            (item['name'] as String).toLowerCase().contains(query)) {
          matchedItemTotal += itemTotal;
        }
      }
    }

    final filteredPurchases = _purchases.where((purchase) {
      final supplier = (purchase['supplier'] as String);
      if (_selectedSupplierFilter != null &&
          supplier != _selectedSupplierFilter) {
        return false;
      }

      final items = (purchase['items'] as List).cast<DbRow>();
      if (_selectedCategoryFilter != null) {
        final hasCat = items.any(
          (i) => (i['category'] as String? ?? 'Інше') == _selectedCategoryFilter,
        );
        if (!hasCat) return false;
      }

      if (query.isEmpty) return true;
      final note = ((purchase['note'] as String?) ?? '').toLowerCase();
      final hasMatchingItem = items.any(
        (i) => (i['name'] as String).toLowerCase().contains(query),
      );
      return supplier.toLowerCase().contains(query) ||
          note.contains(query) ||
          hasMatchingItem;
    }).toList();

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedSuppliers = supplierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final avgInvoiceCents =
        _purchases.isNotEmpty ? (monthTotal ~/ _purchases.length) : 0;

    final allExpanded = filteredPurchases.isNotEmpty &&
        filteredPurchases.every((p) => _expandedIds.contains(p['id'] as int));

    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    return Scaffold(
      backgroundColor: OsnovaTheme.bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: OsnovaTheme.gold),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: OsnovaTheme.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: OsnovaTheme.bgDark,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ЗАКУПКИ ТА НАКЛАДНІ',
                  style: TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'ОБЛІК ВИТРАТ І ПОСТАЧАЛЬНИКІВ • OSNOVA POS',
                  style: TextStyle(
                    color: OsnovaTheme.sageMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isCurrentMonth)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextButton.icon(
                onPressed: _jumpToCurrentMonth,
                icon: const Icon(
                  Icons.today_rounded,
                  size: 16,
                  color: OsnovaTheme.goldBright,
                ),
                label: const Text(
                  'Поточний місяць',
                  style: TextStyle(
                    color: OsnovaTheme.goldBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF11261F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OsnovaTheme.gold.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: OsnovaTheme.goldBright,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: OsnovaTheme.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                          color: OsnovaTheme.creamText,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: OsnovaTheme.goldBright,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OsnovaTheme.gold,
                foregroundColor: OsnovaTheme.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openPurchaseEditor(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Нова накладна',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: OsnovaTheme.gold),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ЛІВА КОЛОНКА: Преміальна аналітика витрат та постачальників
                  Expanded(
                    flex: 36,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hero-картка загальних витрат
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF143126),
                                  Color(0xFF0A1914),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.48),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.32),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -6,
                                  top: -8,
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 74,
                                    color:
                                        OsnovaTheme.gold.withValues(alpha: 0.08),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: OsnovaTheme.goldBright,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ВИТРАЧЕНО ЗА ${_monthNames[_selectedMonth - 1].toUpperCase()}',
                                          style: const TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      MoneyFormatter.format(monthTotal),
                                      style: const TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _StatPill(
                                          label: 'Накладних',
                                          value: '${_purchases.length}',
                                          icon: Icons.description_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        _StatPill(
                                          label: 'Позицій',
                                          value: '$totalItemsCount',
                                          icon: Icons.inventory_2_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        _StatPill(
                                          label: 'Сер. чек',
                                          value: MoneyFormatter.format(
                                            avgInvoiceCents,
                                          ),
                                          icon: Icons.analytics_outlined,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Блок витрат за категоріями (інтерактивний фільтр)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: OsnovaTheme.surfaceCard
                                  .withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: OsnovaTheme.gold.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'СТРУКТУРА ЗА КАТЕГОРІЯМИ',
                                      style: TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.85,
                                      ),
                                    ),
                                    if (_selectedCategoryFilter != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedCategoryFilter = null,
                                        ),
                                        child: const Text(
                                          'Скинути',
                                          style: TextStyle(
                                            color: OsnovaTheme.liveGreen,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (sortedCategories.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'За цей місяць ще немає закупок.',
                                      style: TextStyle(
                                        color: OsnovaTheme.sageMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                else
                                  ...sortedCategories.map((entry) {
                                    final fraction = monthTotal > 0
                                        ? entry.value / monthTotal
                                        : 0.0;
                                    final percent = (fraction * 100).round();
                                    final isSelected =
                                        _selectedCategoryFilter == entry.key;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            _selectedCategoryFilter =
                                                isSelected ? null : entry.key;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? OsnovaTheme.gold
                                                    .withValues(alpha: 0.16)
                                                : const Color(0xFF0A1914)
                                                    .withValues(alpha: 0.65),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? OsnovaTheme.goldBright
                                                  : OsnovaTheme.gold
                                                      .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    _iconForCategory(entry.key),
                                                    size: 15,
                                                    color:
                                                        OsnovaTheme.goldBright,
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: OsnovaTheme
                                                            .creamText,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: OsnovaTheme
                                                          .surfaceCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      '$percent%',
                                                      style: const TextStyle(
                                                        color: OsnovaTheme
                                                            .sageMuted,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    MoneyFormatter.format(
                                                      entry.value,
                                                    ),
                                                    style: const TextStyle(
                                                      color: OsnovaTheme
                                                          .goldBright,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 7),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: LinearProgressIndicator(
                                                  value: fraction,
                                                  minHeight: 6,
                                                  backgroundColor:
                                                      OsnovaTheme.bgDark,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    isSelected
                                                        ? OsnovaTheme.liveGreen
                                                        : OsnovaTheme.gold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),

                          // Блок постачальників місяця
                          if (sortedSuppliers.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: OsnovaTheme.surfaceCard
                                    .withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ПОСТАЧАЛЬНИКИ МІСЯЦЯ',
                                        style: TextStyle(
                                          color: OsnovaTheme.goldBright,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.85,
                                        ),
                                      ),
                                      if (_selectedSupplierFilter != null)
                                        GestureDetector(
                                          onTap: () => setState(
                                            () =>
                                                _selectedSupplierFilter = null,
                                          ),
                                          child: const Text(
                                            'Всі',
                                            style: TextStyle(
                                              color: OsnovaTheme.liveGreen,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: sortedSuppliers.map((sup) {
                                      final isSelected =
                                          _selectedSupplierFilter == sup.key;
                                      return ChoiceChip(
                                        label: Text(
                                          '${sup.key} • ${MoneyFormatter.format(sup.value)}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? OsnovaTheme.bgDark
                                                : OsnovaTheme.creamText,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: OsnovaTheme.gold,
                                        backgroundColor:
                                            const Color(0xFF0A1914),
                                        side: BorderSide(
                                          color: isSelected
                                              ? OsnovaTheme.goldBright
                                              : OsnovaTheme.gold
                                                  .withValues(alpha: 0.28),
                                        ),
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedSupplierFilter =
                                                isSelected ? null : sup.key;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ПРАВА КОЛОНКА: Пошук + Журнал накладних
                  Expanded(
                    flex: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontSize: 13.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Пошук по товарах або постачальниках (TeaKava, стаканчики, TeaHouse, Оболонь)...',
                                  hintStyle: TextStyle(
                                    color: OsnovaTheme.sageMuted
                                        .withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: OsnovaTheme.goldBright,
                                  ),
                                  suffixIcon: query.isNotEmpty
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: OsnovaTheme.liveGreen
                                                    .withValues(alpha: 0.16),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: OsnovaTheme.liveGreen
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: Text(
                                                'По позиціях: ${MoneyFormatter.format(matchedItemTotal)}',
                                                style: const TextStyle(
                                                  color: OsnovaTheme.liveGreen,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: OsnovaTheme.sageMuted,
                                              ),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(
                                                  () => _searchQuery = '',
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: OsnovaTheme.surfaceCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: OsnovaTheme.goldBright,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                              ),
                            ),
                            if (filteredPurchases.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: OsnovaTheme.surfaceCard,
                                  foregroundColor: OsnovaTheme.goldBright,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 15,
                                  ),
                                  side: BorderSide(
                                    color: OsnovaTheme.gold
                                        .withValues(alpha: 0.38),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () =>
                                    _toggleExpandAll(filteredPurchases),
                                icon: Icon(
                                  allExpanded
                                      ? Icons.unfold_less_rounded
                                      : Icons.unfold_more_rounded,
                                  color: OsnovaTheme.goldBright,
                                  size: 19,
                                ),
                                label: Text(
                                  allExpanded ? 'Згорнути всі' : 'Розгорнути всі',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Рядок активних фільтрів (якщо обрано категорію чи постачальника)
                        if (_selectedCategoryFilter != null ||
                            _selectedSupplierFilter != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Активні фільтри:',
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_selectedSupplierFilter != null)
                                InputChip(
                                  label: Text(
                                    'Постачальник: $_selectedSupplierFilter',
                                  ),
                                  backgroundColor: const Color(0xFF11261F),
                                  labelStyle: const TextStyle(
                                    color: OsnovaTheme.goldBright,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                  deleteIconColor: OsnovaTheme.goldBright,
                                  onDeleted: () => setState(
                                    () => _selectedSupplierFilter = null,
                                  ),
                                ),
                              if (_selectedCategoryFilter != null)
                                InputChip(
                                  label: Text(
                                    'Категорія: $_selectedCategoryFilter',
                                  ),
                                  backgroundColor: const Color(0xFF11261F),
                                  labelStyle: const TextStyle(
                                    color: OsnovaTheme.liveGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                  deleteIconColor: OsnovaTheme.liveGreen,
                                  onDeleted: () => setState(
                                    () => _selectedCategoryFilter = null,
                                  ),
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        Expanded(
                          child: filteredPurchases.isEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: OsnovaTheme.surfaceCard
                                        .withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: OsnovaTheme.gold
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_outlined,
                                            size: 42,
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'Накладних за вибраними параметрами не знайдено',
                                          style: TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Додайте нову накладну або змініть період / фільтри пошуку',
                                          style: TextStyle(
                                            color: OsnovaTheme.sageMuted,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredPurchases.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final purchase = filteredPurchases[index];
                                    final pId = purchase['id'] as int;
                                    final isExpanded =
                                        _expandedIds.contains(pId);

                                    return _CollapsiblePurchaseCard(
                                      purchase: purchase,
                                      dateFormatted: _formatDateUa(
                                        purchase['purchase_date'] as String,
                                      ),
                                      isExpanded: isExpanded,
                                      searchQuery: query,
                                      categoryFilter: _selectedCategoryFilter,
                                      onToggleExpand: () => _toggleExpand(pId),
                                      onEdit: () => _openPurchaseEditor(
                                        existingPurchase: purchase,
                                      ),
                                      onDelete: () => _confirmDeletePurchase(
                                        pId,
                                        purchase['supplier'] as String,
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
    );
  }
}

class _CollapsiblePurchaseCard extends StatelessWidget {
  final DbRow purchase;
  final String dateFormatted;
  final bool isExpanded;
  final String searchQuery;
  final String? categoryFilter;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CollapsiblePurchaseCard({
    required this.purchase,
    required this.dateFormatted,
    required this.isExpanded,
    required this.searchQuery,
    required this.categoryFilter,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onDelete,
  });

  String _pluralizePositions(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return '$count позиція';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$count позиції';
    }
    return '$count позицій';
  }

  @override
  Widget build(BuildContext context) {
    final items = (purchase['items'] as List).cast<DbRow>();
    final supplier = purchase['supplier'] as String;
    final note = purchase['note'] as String?;
    final total = (purchase['total_amount'] as int?) ?? 0;

    final matchedCount = searchQuery.isEmpty
        ? 0
        : items
            .where((i) =>
                (i['name'] as String).toLowerCase().contains(searchQuery))
            .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isExpanded
            ? const Color(0xFF122820)
            : OsnovaTheme.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? OsnovaTheme.goldBright.withValues(alpha: 0.65)
              : OsnovaTheme.gold.withValues(alpha: 0.28),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? OsnovaTheme.gold.withValues(alpha: 0.25)
                          : const Color(0xFF0A1914),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: OsnovaTheme.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: OsnovaTheme.goldBright,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1914),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: OsnovaTheme.gold.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                supplier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: OsnovaTheme.creamText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1914),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _pluralizePositions(items.length),
                                style: const TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (matchedCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: OsnovaTheme.liveGreen
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: OsnovaTheme.liveGreen
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(
                                  'Збігів: $matchedCount',
                                  style: const TextStyle(
                                    color: OsnovaTheme.liveGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.tag_rounded,
                                size: 13,
                                color: OsnovaTheme.sageMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1914),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: OsnovaTheme.gold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      MoneyFormatter.format(total),
                      style: const TextStyle(
                        color: OsnovaTheme.goldBright,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Редагувати накладну',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: OsnovaTheme.goldBright,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Видалити накладну',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                    height: 12,
                    color: OsnovaTheme.gold.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 4),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final qty = (item['qty'] as num).toDouble();
                    final qtyText = qty % 1 == 0
                        ? qty.toInt().toString()
                        : qty.toStringAsFixed(2);
                    final unit = item['unit'] as String? ?? 'шт';
                    final unitPrice = item['unit_price'] as int? ?? 0;
                    final itemTotal = item['total_price'] as int? ?? 0;
                    final cat = item['category'] as String? ?? 'Інше';

                    final isHighlighted = (searchQuery.isNotEmpty &&
                            (item['name'] as String)
                                .toLowerCase()
                                .contains(searchQuery)) ||
                        (categoryFilter != null && cat == categoryFilter);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? OsnovaTheme.gold.withValues(alpha: 0.18)
                            : const Color(0xFF0A1914).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isHighlighted
                              ? OsnovaTheme.goldBright.withValues(alpha: 0.6)
                              : OsnovaTheme.gold.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: OsnovaTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: OsnovaTheme.goldBright,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: const TextStyle(
                                    color: OsnovaTheme.creamText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    color: OsnovaTheme.sageMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$qtyText $unit × ${MoneyFormatter.format(unitPrice)}',
                            style: const TextStyle(
                              color: OsnovaTheme.sageMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            MoneyFormatter.format(itemTotal),
                            style: const TextStyle(
                              color: OsnovaTheme.goldBright,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1914).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OsnovaTheme.gold.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: OsnovaTheme.gold),
                const SizedBox(width: 4),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: OsnovaTheme.creamText,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseEditorDialog extends StatefulWidget {
  final DbRow? existingPurchase;

  const _PurchaseEditorDialog({this.existingPurchase});

  @override
  State<_PurchaseEditorDialog> createState() => _PurchaseEditorDialogState();
}

class _PurchaseEditorDialogState extends State<_PurchaseEditorDialog> {
  static const List<String> _categories = [
    'Стаканчики та розхідники',
    'Чаї, кава та сиропи',
    'Вода та напої',
    'Госптовари та інше',
  ];

  static const List<String> _units = ['уп', 'пак', 'шт', 'кг', 'л'];

  static const List<String> _quickSuppliers = [
    'TeaKava',
    'Оболонь',
    'Метро',
    'ІПК Техніка',
    'Опт-Пак',
  ];

  static const DbRowList _quickPresets = [
    // TeaKava
    {
      'supplier': 'TeaKava',
      'name': 'Стаканчики 340 мл',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Стаканчики 250 мл',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Стаканчики 175 мл',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Стаканчики 110 мл',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Кришечки',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Мішалочки (500 шт/уп)',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Чай TeaHouse',
      'cat': 'Чаї, кава та сиропи',
      'unit': 'уп',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Чай рідкий',
      'cat': 'Чаї, кава та сиропи',
      'unit': 'шт',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Сироп',
      'cat': 'Чаї, кава та сиропи',
      'unit': 'шт',
    },
    {
      'supplier': 'TeaKava',
      'name': 'Серветки',
      'cat': 'Стаканчики та розхідники',
      'unit': 'уп',
    },

    // Оболонь
    {
      'supplier': 'Оболонь',
      'name': 'Мінеральна вода 2 л (пак)',
      'cat': 'Вода та напої',
      'unit': 'пак',
    },
    {
      'supplier': 'Оболонь',
      'name': 'Вода негазована 0.5 л (пак)',
      'cat': 'Вода та напої',
      'unit': 'пак',
    },
    {
      'supplier': 'Оболонь',
      'name': 'Вода газована 0.5 л (пак)',
      'cat': 'Вода та напої',
      'unit': 'пак',
    },
  ];

  late DateTime _selectedDate;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _noteCtrl;

  final _itemNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  String _selectedCategory = _categories.first;
  String _selectedUnit = _units.first;
  bool _showAllPresets = false;

  final DbRowList _items = [];
  int? _editingItemIndex;
  bool _isSaving = false;

  bool get _isEditingInvoice => widget.existingPurchase != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPurchase;
    if (existing != null) {
      _selectedDate =
          DateTime.tryParse(existing['purchase_date'] as String) ??
              DateTime.now();
      _supplierCtrl = TextEditingController(
        text: existing['supplier'] as String? ?? '',
      );
      _noteCtrl = TextEditingController(
        text: existing['note'] as String? ?? '',
      );
      final rawItems = (existing['items'] as List).cast<DbRow>();
      for (final item in rawItems) {
        _items.add(Map<String, dynamic>.from(item));
      }
    } else {
      _selectedDate = DateTime.now();
      _supplierCtrl = TextEditingController(text: 'TeaKava');
      _noteCtrl = TextEditingController();
    }

    _qtyCtrl.addListener(_onDraftChanged);
    _priceCtrl.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_onDraftChanged);
    _priceCtrl.removeListener(_onDraftChanged);
    _supplierCtrl.dispose();
    _noteCtrl.dispose();
    _itemNameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  int get _draftLineTotalCents {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final priceUah =
        double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0 || priceUah <= 0) return 0;
    return (qty * (priceUah * 100).round()).round();
  }

  DbRowList get _visiblePresets {
    if (_showAllPresets) return _quickPresets;
    final sup = _supplierCtrl.text.trim().toLowerCase();
    if (sup.isEmpty) return _quickPresets;

    final filtered = _quickPresets
        .where((p) => (p['supplier'] as String).toLowerCase() == sup)
        .toList();
    return filtered.isEmpty ? _quickPresets : filtered;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectSupplier(String supplier) {
    setState(() {
      _supplierCtrl.text = supplier;
      _showAllPresets = false;
      if (supplier == 'Оболонь') {
        _selectedCategory = 'Вода та напої';
        _selectedUnit = 'пак';
      } else if (supplier == 'TeaKava') {
        _selectedCategory = 'Стаканчики та розхідники';
        _selectedUnit = 'уп';
      }
    });
  }

  void _applyPreset(DbRow preset) {
    setState(() {
      _itemNameCtrl.text = preset['name'] as String;
      _selectedCategory = preset['cat'] as String;
      _selectedUnit = preset['unit'] as String;
      if (_supplierCtrl.text.trim().isEmpty) {
        _supplierCtrl.text = preset['supplier'] as String;
      }
    });
  }

  void _adjustQty(double delta) {
    final current = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1;
    final next = (current + delta).clamp(0.5, 9999.0);
    setState(() {
      _qtyCtrl.text =
          next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    });
  }

  void _startEditingItem(int index) {
    final item = _items[index];
    final qty = (item['qty'] as num).toDouble();
    final unitPriceUah = ((item['unit_price'] as int?) ?? 0) / 100.0;

    setState(() {
      _editingItemIndex = index;
      _itemNameCtrl.text = item['name'] as String;
      _selectedCategory = _categories.contains(item['category'])
          ? item['category'] as String
          : _categories.first;
      _selectedUnit = _units.contains(item['unit'])
          ? item['unit'] as String
          : _units.first;
      _qtyCtrl.text =
          qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
      _priceCtrl.text = unitPriceUah % 1 == 0
          ? unitPriceUah.toInt().toString()
          : unitPriceUah.toStringAsFixed(2);
    });
  }

  void _cancelEditingItem() {
    setState(() {
      _editingItemIndex = null;
      _itemNameCtrl.clear();
      _qtyCtrl.text = '1';
      _priceCtrl.clear();
    });
  }

  void _commitItemToInvoice() {
    final name = _itemNameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final unitPriceUah =
        double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

    if (name.isEmpty || qty <= 0 || unitPriceUah <= 0) {
      OsnovaToast.warning(
        context,
        'Заповніть дані товару',
        subtitle: 'Вкажіть назву позиції, кількість та ціну за одиницю',
      );
      return;
    }

    final unitPriceCents = (unitPriceUah * 100).round();
    final totalPriceCents = (qty * unitPriceCents).round();

    final newItem = <String, dynamic>{
      'name': name,
      'category': _selectedCategory,
      'qty': qty,
      'unit': _selectedUnit,
      'unit_price': unitPriceCents,
      'total_price': totalPriceCents,
    };

    setState(() {
      if (_editingItemIndex != null &&
          _editingItemIndex! >= 0 &&
          _editingItemIndex! < _items.length) {
        _items[_editingItemIndex!] = newItem;
        _editingItemIndex = null;
      } else {
        _items.add(newItem);
      }
      _itemNameCtrl.clear();
      _qtyCtrl.text = '1';
      _priceCtrl.clear();
    });
  }

  Future<void> _saveInvoice() async {
    final supplier = _supplierCtrl.text.trim().isEmpty
        ? 'Закупка без постачальника'
        : _supplierCtrl.text.trim();

    if (_items.isEmpty) {
      OsnovaToast.warning(
        context,
        'Накладна порожня',
        subtitle: 'Додайте хоча б одну позицію перед збереженням',
      );
      return;
    }

    final totalCents = _items.fold<int>(
      0,
      (sum, item) => sum + (item['total_price'] as int),
    );

    setState(() => _isSaving = true);

    if (_isEditingInvoice) {
      await PosLocalDataSource.instance.updatePurchase(
        purchaseId: widget.existingPurchase!['id'] as int,
        purchaseDate: _selectedDate,
        supplier: supplier,
        note: _noteCtrl.text,
        items: _items,
      );
    } else {
      await PosLocalDataSource.instance.createPurchase(
        purchaseDate: _selectedDate,
        supplier: supplier,
        note: _noteCtrl.text,
        items: _items,
      );
    }

    if (!mounted) return;
    OsnovaToast.success(
      context,
      _isEditingInvoice ? 'Накладну оновлено' : 'Накладну збережено',
      subtitle: '$supplier • ${MoneyFormatter.format(totalCents)}',
    );
    Navigator.pop(context, true);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: OsnovaTheme.sageMuted, fontSize: 12.5),
      hintStyle: TextStyle(
        color: OsnovaTheme.sageMuted.withValues(alpha: 0.55),
        fontSize: 12.5,
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: OsnovaTheme.goldBright)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0A1914),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.28)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OsnovaTheme.gold.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OsnovaTheme.goldBright, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}';
    final totalCents = _items.fold<int>(
      0,
      (sum, item) => sum + (item['total_price'] as int),
    );
    final currentSupplierLower = _supplierCtrl.text.trim().toLowerCase();
    final presetsToShow = _visiblePresets;

    return Dialog(
      backgroundColor: OsnovaTheme.surfaceCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: OsnovaTheme.gold.withValues(alpha: 0.48),
          width: 1.2,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 710),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Верхній заголовок діалогу
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: OsnovaTheme.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditingInvoice
                          ? Icons.edit_note_rounded
                          : Icons.receipt_long_rounded,
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
                          _isEditingInvoice
                              ? 'РЕДАГУВАННЯ НАКЛАДНОЇ'
                              : 'НОВА НАКЛАДНА ЗАКУПКИ',
                          style: const TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Text(
                          'Оберіть постачальника, додайте позиції з накладної та збережіть у журнал',
                          style: TextStyle(
                            color: OsnovaTheme.sageMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1914),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: OsnovaTheme.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: OsnovaTheme.goldBright,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Дата: $dateText',
                            style: const TextStyle(
                              color: OsnovaTheme.creamText,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_outlined,
                            color: OsnovaTheme.sageMuted,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: OsnovaTheme.sageMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Основна двоколонкова робоча область
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ЛІВА КОЛОНКА: Постачальник + Конструктор позиції
                    Expanded(
                      flex: 55,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Блок 1: Вибір постачальника
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11261F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      OsnovaTheme.gold.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '1. ПОСТАЧАЛЬНИК ТА НОМЕР НАКЛАДНОЇ',
                                    style: TextStyle(
                                      color: OsnovaTheme.goldBright,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _quickSuppliers.map((sup) {
                                      final isSelected =
                                          currentSupplierLower ==
                                              sup.toLowerCase();
                                      return ChoiceChip(
                                        label: Text(
                                          sup,
                                          style: TextStyle(
                                            color: isSelected
                                                ? OsnovaTheme.bgDark
                                                : OsnovaTheme.creamText,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: OsnovaTheme.gold,
                                        backgroundColor:
                                            const Color(0xFF0A1914),
                                        side: BorderSide(
                                          color: isSelected
                                              ? OsnovaTheme.goldBright
                                              : OsnovaTheme.gold
                                                  .withValues(alpha: 0.35),
                                        ),
                                        onSelected: (_) => _selectSupplier(sup),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: TextField(
                                          controller: _supplierCtrl,
                                          onChanged: (_) => setState(() {}),
                                          style: const TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: 'Постачальник',
                                            hint: 'TeaKava, Оболонь або інший',
                                            icon: Icons.storefront_outlined,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          controller: _noteCtrl,
                                          style: const TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontSize: 13.5,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: '№ накладної / нотатка',
                                            hint: 'Необов’язково',
                                            icon: Icons.tag_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Блок 2: Конструктор товару з накладної
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11261F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _editingItemIndex != null
                                      ? OsnovaTheme.liveGreen
                                          .withValues(alpha: 0.7)
                                      : OsnovaTheme.gold
                                          .withValues(alpha: 0.38),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _editingItemIndex != null
                                            ? '2. РЕДАГУВАННЯ ПОЗИЦІЇ #${_editingItemIndex! + 1}'
                                            : '2. ТОВАР ІЗ НАКЛАДНОЇ',
                                        style: TextStyle(
                                          color: _editingItemIndex != null
                                              ? OsnovaTheme.liveGreen
                                              : OsnovaTheme.goldBright,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (_editingItemIndex != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child: GestureDetector(
                                                onTap: _cancelEditingItem,
                                                child: const Text(
                                                  'Скасувати',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          GestureDetector(
                                            onTap: () => setState(() =>
                                                _showAllPresets =
                                                    !_showAllPresets),
                                            child: Text(
                                              _showAllPresets
                                                  ? 'Тільки обраного постач.'
                                                  : 'Показати всі шаблони',
                                              style: const TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Швидкі пресети товарів
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: presetsToShow.map((preset) {
                                      return ActionChip(
                                        backgroundColor:
                                            const Color(0xFF0A1914),
                                        side: BorderSide(
                                          color: OsnovaTheme.gold
                                              .withValues(alpha: 0.35),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        label: Text(
                                          '+ ${preset['name']}',
                                          style: const TextStyle(
                                            color: OsnovaTheme.goldBright,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        onPressed: () => _applyPreset(preset),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 10),

                                  TextField(
                                    controller: _itemNameCtrl,
                                    style: const TextStyle(
                                      color: OsnovaTheme.creamText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: _fieldDecoration(
                                      label: 'Назва товару',
                                      hint:
                                          'Оберіть шаблон вище або впишіть вручну',
                                      icon: Icons.inventory_2_outlined,
                                      suffixIcon: _itemNameCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear_rounded,
                                                size: 16,
                                                color: OsnovaTheme.sageMuted,
                                              ),
                                              onPressed: () => setState(
                                                () => _itemNameCtrl.clear(),
                                              ),
                                            )
                                          : null,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),

                                  const SizedBox(height: 10),

                                  // Вибір категорії чіпами
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _categories.map((cat) {
                                      final isSelected =
                                          _selectedCategory == cat;
                                      return ChoiceChip(
                                        label: Text(
                                          cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? OsnovaTheme.bgDark
                                                : OsnovaTheme.creamText,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: OsnovaTheme.gold,
                                        backgroundColor:
                                            const Color(0xFF0A1914),
                                        side: BorderSide(
                                          color: isSelected
                                              ? OsnovaTheme.goldBright
                                              : OsnovaTheme.gold
                                                  .withValues(alpha: 0.25),
                                        ),
                                        onSelected: (_) => setState(
                                          () => _selectedCategory = cat,
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 12),

                                  // Кількість зі степпером, одиниці виміру, ціна за одиницю
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          controller: _qtyCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.,]'),
                                            ),
                                          ],
                                          style: const TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: 'Кількість',
                                            suffixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () => _adjustQty(-1),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(4.0),
                                                    child: Icon(
                                                      Icons.remove_rounded,
                                                      size: 16,
                                                      color: OsnovaTheme
                                                          .sageMuted,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => _adjustQty(1),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(4.0),
                                                    child: Icon(
                                                      Icons.add_rounded,
                                                      size: 16,
                                                      color: OsnovaTheme
                                                          .goldBright,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Перемикач одиниць виміру
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0A1914),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: _units.map((u) {
                                            final active = _selectedUnit == u;
                                            return GestureDetector(
                                              onTap: () => setState(
                                                () => _selectedUnit = u,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: active
                                                      ? OsnovaTheme.gold
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: Text(
                                                  u,
                                                  style: TextStyle(
                                                    color: active
                                                        ? OsnovaTheme.bgDark
                                                        : OsnovaTheme.creamText,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          controller: _priceCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.,]'),
                                            ),
                                          ],
                                          style: const TextStyle(
                                            color: OsnovaTheme.creamText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          decoration: _fieldDecoration(
                                            label:
                                                'Ціна за 1 $_selectedUnit (грн)',
                                            hint: '0.00',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Кнопка додавання з живим підрахунком позиції
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0A1914),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Сума позиції',
                                              style: TextStyle(
                                                color: OsnovaTheme.sageMuted,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              MoneyFormatter.format(
                                                _draftLineTotalCents,
                                              ),
                                              style: const TextStyle(
                                                color: OsnovaTheme.goldBright,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                _editingItemIndex != null
                                                    ? OsnovaTheme.liveGreen
                                                    : OsnovaTheme.gold,
                                            foregroundColor: OsnovaTheme.bgDark,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _commitItemToInvoice,
                                          icon: Icon(
                                            _editingItemIndex != null
                                                ? Icons.check_rounded
                                                : Icons
                                                    .add_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _editingItemIndex != null
                                                ? 'Оновити позицію'
                                                : 'Додати в накладну',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ПРАВА КОЛОНКА: Живий чек складу накладної
                    Expanded(
                      flex: 45,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_outlined,
                                      size: 16,
                                      color: OsnovaTheme.goldBright,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'СКЛАД НАКЛАДНОЇ',
                                      style: TextStyle(
                                        color: OsnovaTheme.goldBright,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: OsnovaTheme.gold
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_items.length}',
                                        style: const TextStyle(
                                          color: OsnovaTheme.goldBright,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_items.isNotEmpty)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _items.clear();
                                        _editingItemIndex = null;
                                      });
                                    },
                                    child: const Text(
                                      'Очистити все',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_items.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Натисніть на позицію, щоб відредагувати її',
                                style: TextStyle(
                                  color: OsnovaTheme.sageMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            const Divider(height: 14),
                            Expanded(
                              child: _items.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.playlist_add_rounded,
                                            size: 46,
                                            color: OsnovaTheme.gold
                                                .withValues(alpha: 0.35),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Список порожній\nДодайте товари зліва',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: OsnovaTheme.sageMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _items.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = _items[index];
                                        final qty =
                                            (item['qty'] as num).toDouble();
                                        final qtyStr = qty % 1 == 0
                                            ? qty.toInt().toString()
                                            : qty.toStringAsFixed(2);
                                        final isEditingThis =
                                            _editingItemIndex == index;

                                        return InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () => _startEditingItem(index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isEditingThis
                                                  ? OsnovaTheme.liveGreen
                                                      .withValues(alpha: 0.16)
                                                  : const Color(0xFF11261F),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isEditingThis
                                                    ? OsnovaTheme.liveGreen
                                                    : OsnovaTheme.gold
                                                        .withValues(alpha: 0.24),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['name'] as String,
                                                        style: const TextStyle(
                                                          color: OsnovaTheme
                                                              .creamText,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 13.5,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${item['category']} • $qtyStr ${item['unit']} × ${MoneyFormatter.format(item['unit_price'] as int)}',
                                                        style: const TextStyle(
                                                          color: OsnovaTheme
                                                              .sageMuted,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  MoneyFormatter.format(
                                                    item['total_price'] as int,
                                                  ),
                                                  style: const TextStyle(
                                                    color:
                                                        OsnovaTheme.goldBright,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.redAccent,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (_editingItemIndex ==
                                                          index) {
                                                        _editingItemIndex =
                                                            null;
                                                      }
                                                      _items.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Нижня панель підсумку та збереження
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF143126), Color(0xFF0A1914)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: OsnovaTheme.gold.withValues(alpha: 0.42),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'РАЗОМ ПО НАКЛАДНІЙ:',
                          style: TextStyle(
                            color: OsnovaTheme.sageMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          MoneyFormatter.format(totalCents),
                          style: const TextStyle(
                            color: OsnovaTheme.goldBright,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Скасувати',
                            style: TextStyle(color: OsnovaTheme.sageMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OsnovaTheme.liveGreen,
                            foregroundColor: OsnovaTheme.bgDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveInvoice,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _isEditingInvoice
                                ? 'Зберегти зміни'
                                : 'Зберегти накладну',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
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