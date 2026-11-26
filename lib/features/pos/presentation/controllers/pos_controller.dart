import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osnova_pos/features/pos/data/services/fortune_generator.dart';
import 'package:osnova_pos/features/pos/data/services/osnova_telegram_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/osnova_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../../data/services/privat_terminal_service_impl.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';
import '../widgets/abc_analytics_dialog.dart';
import '../widgets/cash_operations_z_report.dart';
import '../widgets/receipt_print_template.dart';

class CheckoutResult {
  final int receiptNum;
  final String receiptCode;
  final String? transactionId;
  final bool printed;
  final String? printError;

  const CheckoutResult({
    required this.receiptNum,
    required this.receiptCode,
    this.transactionId,
    required this.printed,
    this.printError,
  });
}

class PosController extends ChangeNotifier {
  final PosRepository _repository;
  final PrinterService _printerService;
  final ReportExportService _exportService;
  final PrivatTerminalService _privatTerminalService;

  PosController({
    required PosRepository repository,
    required PrinterService printerService,
    required ReportExportService exportService,
    PrivatTerminalService? privatTerminalService,
  })  : _repository = repository,
        _printerService = printerService,
        _exportService = exportService,
        _privatTerminalService =
            privatTerminalService ?? PrivatTerminalServiceImpl();

  static const _keyCategoryOrder = 'osnova_category_order';

  final GlobalKey receiptPrintKey = GlobalKey();
  final Random _random = Random();
  final ShiftAutoCloseScheduler _autoCloseScheduler = ShiftAutoCloseScheduler();

  void Function(StandardZReportData report)? onAutoZReportCompleted;

  ShiftEntity? currentShift;
  List<ProductEntity> products = [];
  List<String> _savedCategoryOrder = [];
  String selectedCategory = 'Усі';

  final List<CartItemEntity> cart = [];
  String paymentMethod = 'card';

  int currentCashInDrawer = 0;
  String? connectedPrinterIp;
  bool is80mmPrinter = true;
  bool printReceipt = false;

  bool isOplata24Configured = false;
  String? cashierPhone;

  List<OrderHistoryEntity> shiftOrders = [];
  List<ExpenseEntity> shiftExpenses = [];
  List<CashOperationRecord> shiftCashOperations = [];
  int shiftServiceInTotal = 0;
  int shiftServiceOutTotal = 0;
  StandardZReportData? lastStandardZReport;

  ReceiptPrintData receiptPrintData = const ReceiptPrintData(
    documentTitle: 'ТОВАРНИЙ ЧЕК',
    dateTimeText: '',
  );

  OsnovaThemeId get currentTheme => OsnovaTheme.currentTheme;

  Future<void> setTheme(OsnovaThemeId themeId) async {
    await OsnovaTheme.setTheme(themeId);
    notifyListeners();
  }

  bool get isPrinterConnected =>
      connectedPrinterIp != null && connectedPrinterIp!.isNotEmpty;

  bool get canPrintReceipt => isPrinterConnected && printReceipt;

  List<String> get categories {
    final existing = <String>{};
    for (final p in products) {
      if (p.category.trim().isNotEmpty && p.category != 'Усі') {
        existing.add(p.category);
      }
    }

    final ordered = <String>[];
    for (final saved in _savedCategoryOrder) {
      if (existing.remove(saved)) {
        ordered.add(saved);
      }
    }
    ordered.addAll(existing);

    return ['Усі', ...ordered];
  }

  List<ProductEntity> get filteredProducts {
    if (selectedCategory == 'Усі') return products;
    return products.where((p) => p.category == selectedCategory).toList();
  }

  int get cartTotal => cart.fold<int>(0, (sum, item) => sum + item.totalPrice);

  String _generateUniqueReceiptCode(DateTime now, int receiptNum) {
    final datePart = DateFormat('ddMMyy').format(now);
    final timePart = DateFormat('HHmm').format(now);
    final seqPart = receiptNum.toString().padLeft(3, '0');
    final checkDigits = (1000 + _random.nextInt(9000)).toString();
    return '763-$datePart-$timePart-$seqPart-$checkDigits';
  }

  Future<void> initPos() async {
    await OsnovaTheme.loadSavedTheme();
    final prefs = await SharedPreferences.getInstance();
    _savedCategoryOrder = prefs.getStringList(_keyCategoryOrder) ?? [];

    final tgConfig = await PosLocalDataSource.instance.loadTelegramSettings();
    OsnovaTelegramService.instance.onConfigSaved = (token, chatId) async {
      await PosLocalDataSource.instance.saveTelegramSettings(
        token: token,
        chatId: chatId,
      );
    };
    OsnovaTelegramService.instance.configure(
      token: tgConfig.token,
      targetChatId: tgConfig.chatId,
      persist: false,
    );

    currentShift = await _repository.getOrOpenShift(defaultOpeningCash: 0);
    products = await _repository.getActiveProducts();

    final printer = await _printerService.loadSettings();
    connectedPrinterIp = printer.ip.isEmpty ? null : printer.ip;
    is80mmPrinter = printer.is80mm;
    printReceipt = isPrinterConnected ? printer.autoPrint : false;

    final pbSettings = await _privatTerminalService.loadSettings();
    isOplata24Configured = pbSettings.isConfigured;
    cashierPhone =
        pbSettings.cashierPhone.isEmpty ? null : pbSettings.cashierPhone;

    await _refreshShiftData();
    _startAutoCloseWatcher();
    notifyListeners();
  }

  void _startAutoCloseWatcher() {
    if (currentShift == null) return;
    _autoCloseScheduler.start(
      currentShiftOpenedAt: DateTime.tryParse(currentShift!.openedAt),
      onAutoCloseShift: ({required bool isAuto}) async {
        await performAutoCloseShift();
      },
    );
  }

  Future<void> performAutoCloseShift() async {
    if (currentShift == null) return;
    await buildReport(isZReport: true, isAutoClosed: true);
    final closedZ = lastStandardZReport;
    final carryOverCash = closedZ?.expectedCashInDrawerCents ?? 0;

    currentShift = await _repository.getOrOpenShift(
      defaultOpeningCash: carryOverCash,
    );
    await _refreshShiftData();
    _startAutoCloseWatcher();
    notifyListeners();

    if (closedZ != null) {
      onAutoZReportCompleted?.call(closedZ);
    }
  }

  Future<void> _refreshShiftData() async {
    if (currentShift == null) return;
    final shiftId = currentShift!.id;

    shiftCashOperations =
        await PosLocalDataSource.instance.getShiftCashOperations(shiftId);
    final opTotals =
        await PosLocalDataSource.instance.getShiftCashOpTotals(shiftId);
    shiftServiceInTotal = opTotals.serviceIn;
    shiftServiceOutTotal = opTotals.serviceOut;

    final summary = await _repository.getShiftSummary(shiftId);
    currentCashInDrawer = summary.shift.openingCash +
        summary.cashSales +
        shiftServiceInTotal -
        shiftServiceOutTotal -
        summary.cashExpenses;

    shiftOrders = await _repository.getShiftOrders(shiftId);
    shiftExpenses = await _repository.getShiftExpenses(shiftId);
  }

  Future<void> addCashOperation(
    CashOpType type,
    int amountCents,
    String reason,
  ) async {
    if (currentShift == null) return;
    await PosLocalDataSource.instance.addCashOperation(
      shiftId: currentShift!.id,
      type: type,
      amountCents: amountCents,
      reason: reason,
    );
    await _refreshShiftData();
    notifyListeners();

    OsnovaTelegramService.instance.notifyCashOperation(
      type: type,
      amountCents: amountCents,
      reason: reason,
    );
  }

  Future<List<ProductSalesStat>> loadAbcAnalytics({int daysBack = 30}) {
    return PosLocalDataSource.instance.getProductSalesStats(daysBack: daysBack);
  }

 Future<List<ProductSalesStat>> loadAbcAnalyticsRange(
    DateTime start,
    DateTime end,
  ) {
    return PosLocalDataSource.instance.getProductSalesStatsByRange(
      start: start,
      end: end,
    );
  }

  void selectCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> reorderCategories(
    String draggedCategory,
    String targetCategory,
  ) async {
    if (draggedCategory == 'Усі' ||
        targetCategory == 'Усі' ||
        draggedCategory == targetCategory) {
      return;
    }

    final movable = categories.where((c) => c != 'Усі').toList();
    final oldIndex = movable.indexOf(draggedCategory);
    final newIndex = movable.indexOf(targetCategory);
    if (oldIndex == -1 || newIndex == -1 || oldIndex == newIndex) return;

    final item = movable.removeAt(oldIndex);
    movable.insert(newIndex, item);

    _savedCategoryOrder = movable;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCategoryOrder, movable);
  }

  Future<void> reorderProducts(
    int draggedProductId,
    int targetProductId,
  ) async {
    if (draggedProductId == targetProductId) return;

    final oldIndex = products.indexWhere((p) => p.id == draggedProductId);
    final newIndex = products.indexWhere((p) => p.id == targetProductId);
    if (oldIndex == -1 || newIndex == -1 || oldIndex == newIndex) return;

    final moved = products.removeAt(oldIndex);
    products.insert(newIndex, moved);

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      products[i] = ProductEntity(
        id: p.id,
        name: p.name,
        category: p.category,
        price: p.price,
        costPrice: p.costPrice,
        isActive: p.isActive,
        sortOrder: i,
      );
    }

    notifyListeners();
    await _repository.updateProductsOrder(products);
  }

  void addToCart(ProductEntity product) {
    final idx = cart.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(qty: cart[idx].qty + 1);
    } else {
      cart.add(CartItemEntity(product: product, qty: 1));
    }
    notifyListeners();
  }

  void decrementProduct(int productId) {
    final index = cart.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    decrementCartItem(index);
  }

  void decrementCartItem(int index) {
    if (index < 0 || index >= cart.length) return;
    final current = cart[index];
    if (current.qty > 1) {
      cart[index] = current.copyWith(qty: current.qty - 1);
    } else {
      cart.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    if (paymentMethod == method) return;
    paymentMethod = method;
    notifyListeners();
  }

  Future<void> setPrintReceipt(bool value) async {
    if (!isPrinterConnected) {
      printReceipt = false;
      notifyListeners();
      return;
    }
    printReceipt = value;
    notifyListeners();
    await _printerService.saveAutoPrint(value);
  }

  Future<void> updateCashInDrawer(int newKopecks) async {
    if (currentShift == null) return;
    final summary = await _repository.getShiftSummary(currentShift!.id);
    final opTotals =
        await PosLocalDataSource.instance.getShiftCashOpTotals(currentShift!.id);

    final newOpeningCash = newKopecks -
        summary.cashSales -
        opTotals.serviceIn +
        opTotals.serviceOut +
        summary.cashExpenses;

    await _repository.updateOpeningCash(
      shiftId: currentShift!.id,
      amount: newOpeningCash,
    );
    currentShift = await _repository.getOrOpenShift(
      defaultOpeningCash: newOpeningCash,
    );
    await _refreshShiftData();
    notifyListeners();
  }

  Future<void> addProduct(
    String name,
    String category,
    int priceKopecks, [
    int costPriceKopecks = 0,
  ]) async {
    await _repository.addProduct(
      name: name,
      category: category,
      price: priceKopecks,
      costPrice: costPriceKopecks,
    );
    products = await _repository.getActiveProducts();
    notifyListeners();
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required int priceKopecks,
    int costPriceKopecks = 0,
  }) async {
    final existing = products.where((p) => p.id == id).firstOrNull;
    await _repository.updateProduct(
      ProductEntity(
        id: id,
        name: name,
        category: category,
        price: priceKopecks,
        costPrice: costPriceKopecks,
        isActive: true,
        sortOrder: existing?.sortOrder ?? 0,
      ),
    );
    products = await _repository.getActiveProducts();
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Усі';
    }
    notifyListeners();
  }

  Future<void> deleteProduct(int productId) async {
    await _repository.deleteProduct(productId);
    products = await _repository.getActiveProducts();
    cart.removeWhere((item) => item.product.id == productId);
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Усі';
    }
    notifyListeners();
  }

  Future<void> deleteOrder(int orderId) async {
    await _repository.deleteOrder(orderId);
    await _refreshShiftData();
    notifyListeners();
  }

  Future<void> addExpense(String title, int amount, String source) async {
    if (currentShift == null) return;
    await _repository.addExpense(
      shiftId: currentShift!.id,
      title: title,
      amount: amount,
      source: source,
    );
    await _refreshShiftData();
    notifyListeners();
  }

  Future<void> deleteExpense(int expenseId) async {
    await _repository.deleteExpense(expenseId);
    await _refreshShiftData();
    notifyListeners();
  }

  Future<PrinterSettingsEntity> loadPrinterSettings() {
    return _printerService.loadSettings();
  }

  Future<List<String>> discoverPrinters() {
    return _printerService.discoverNetworkPrinters();
  }

  Future<void> savePrinterSettings({
    required String ip,
    required bool is80mm,
  }) async {
    await _printerService.saveSettings(ip: ip, is80mm: is80mm);
    final updated = await _printerService.loadSettings();
    connectedPrinterIp = updated.ip.isEmpty ? null : updated.ip;
    is80mmPrinter = updated.is80mm;
    if (isPrinterConnected) {
      printReceipt = true;
      await _printerService.saveAutoPrint(true);
    } else {
      printReceipt = false;
    }
    notifyListeners();
  }

  Future<void> clearPrinterSettings() async {
    await _printerService.clearSettings();
    connectedPrinterIp = null;
    printReceipt = false;
    notifyListeners();
  }

  Future<PrivatTerminalSettingsEntity> loadPrivatTerminalSettings() {
    return _privatTerminalService.loadSettings();
  }

  Future<void> savePrivatTerminalSettings(
    PrivatTerminalSettingsEntity settings,
  ) async {
    await _privatTerminalService.saveSettings(settings);
    isOplata24Configured = settings.isConfigured;
    cashierPhone = settings.cashierPhone.trim().isEmpty
        ? null
        : settings.cashierPhone.trim();
    notifyListeners();
  }

  Future<PrivatPaymentSession> startOplata24Session() async {
    if (cart.isEmpty) {
      throw Exception('Кошик порожній');
    }
    final itemsSummary =
        cart.map((e) => '${e.product.name} x${e.qty}').join(', ');
    final purpose = itemsSummary.length > 90
        ? 'OSNOVA • ${itemsSummary.substring(0, 87)}...'
        : 'OSNOVA • $itemsSummary';

    return _privatTerminalService.initiatePayment(
      amountKopecks: cartTotal,
      purpose: purpose,
    );
  }

  Future<PrivatPaymentPollResult> checkOplata24Session(String paymentToken) {
    return _privatTerminalService.checkPaymentStatus(paymentToken);
  }

  void prepareTestReceipt(String ip) {
    final now = DateTime.now();
    final formattedNow = DateFormat('dd.MM.yyyy HH:mm:ss').format(now);
    receiptPrintData = ReceiptPrintData(
      documentTitle: 'ТЕСТ ДРУКУ XPRINTER',
      receiptCode: _generateUniqueReceiptCode(now, 0),
      shiftReceiptLabel: is80mmPrinter ? 'Стрічка: 80 мм' : 'Стрічка: 58 мм',
      dateTimeText: formattedNow,
      summaryRows: [
        ReceiptSummaryRow(
          label: 'IP-адреса принтера:',
          value: ip.isNotEmpty ? ip : (connectedPrinterIp ?? 'Не вказано'),
          isBold: true,
        ),
        const ReceiptSummaryRow(
          label: 'Статус зв\'язку:',
          value: 'Успішно підключено',
          isBold: true,
        ),
      ],
      footerNote: 'Принтер готовий до роботи!',
      showSocials: true,
    );
    notifyListeners();
  }

  Future<String?> printCurrentReceipt() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));
      final pngBytes =
          await _printerService.captureWidgetAsImage(receiptPrintKey);
      if (pngBytes == null) {
        return 'Не вдалося сформувати зображення чека';
      }
      await _printerService.printImageOverWifi(pngBytes);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  String _formatPaymentLabel(String method) {
    switch (method) {
      case 'oplata24':
        return 'Оплата24 (ПриватБанк)';
      case 'card':
        return 'Картка (Термінал)';
      default:
        return 'Готівка';
    }
  }

  Future<CheckoutResult?> checkout({String? externalTransactionId}) async {
    if (cart.isEmpty || currentShift == null) return null;

    final shiftId = currentShift!.id;
    final itemsSnapshot = List<CartItemEntity>.from(cart);
    final totalSnapshot = cartTotal;
    final methodSnapshot = paymentMethod;

    final now = DateTime.now();
    final nextNum = (shiftOrders.isEmpty
            ? 0
            : shiftOrders.map((e) => e.receiptNum).reduce(max)) +
        1;
    final uniqueCode = _generateUniqueReceiptCode(now, nextNum);

    String? fortuneText;
    final fortuneEnabled =
        await PosLocalDataSource.instance.isFortuneEnabled();
    if (fortuneEnabled) {
      final customs = await PosLocalDataSource.instance.getCustomFortunes();
      final customTexts = customs
          .map((e) => (e['text'] ?? '').toString())
          .where((t) => t.trim().isNotEmpty)
          .toList();
      fortuneText = FortuneGenerator.generate(customFortunes: customTexts);
    }

    final receiptNum = await _repository.createOrder(
      shiftId: shiftId,
      items: itemsSnapshot,
      paymentMethod: methodSnapshot,
      receiptCode: uniqueCode,
      transactionId: externalTransactionId,
    );

    final formattedNow = DateFormat('dd.MM.yyyy HH:mm').format(now);

    receiptPrintData = ReceiptPrintData(
      documentTitle: 'ТОВАРНИЙ ЧЕК',
      receiptCode: uniqueCode,
      shiftReceiptLabel: 'Чек за зміну: №$receiptNum',
      dateTimeText: formattedNow,
      items: itemsSnapshot
          .map(
            (e) => ReceiptPrintItem(
              name: e.product.name,
              qty: e.qty,
              unitPriceText: MoneyFormatter.format(e.product.price),
              totalPriceText: MoneyFormatter.format(e.totalPrice),
            ),
          )
          .toList(),
      summaryRows: [
        if (externalTransactionId != null && externalTransactionId.isNotEmpty)
          ReceiptSummaryRow(
            label: 'RRN / Код транзакції:',
            value: externalTransactionId,
            isBold: true,
          ),
      ],
      grandTotalLabel: 'ДО СПЛАТИ:',
      grandTotalValue: MoneyFormatter.format(totalSnapshot),
      paymentMethodText: _formatPaymentLabel(methodSnapshot),
      fortuneText: fortuneText,
      footerNote: 'Дякуємо, що завітали в OSNOVA!',
      showSocials: true,
    );

    cart.clear();
    await _refreshShiftData();
    notifyListeners();

    if (!canPrintReceipt) {
      return CheckoutResult(
        receiptNum: receiptNum,
        receiptCode: uniqueCode,
        transactionId: externalTransactionId,
        printed: false,
      );
    }

    final printError = await printCurrentReceipt();
    return CheckoutResult(
      receiptNum: receiptNum,
      receiptCode: uniqueCode,
      transactionId: externalTransactionId,
      printed: true,
      printError: printError,
    );
  }

  Future<ShiftReportEntity?> buildReport({
    required bool isZReport,
    bool isAutoClosed = false,
  }) async {
    if (currentShift == null) return null;

    final shiftId = currentShift!.id;
    final summary = await _repository.getShiftSummary(shiftId);
    final expenses = await _repository.getShiftExpenses(shiftId);
    final cashOps =
        await PosLocalDataSource.instance.getShiftCashOperations(shiftId);
    final opTotals =
        await PosLocalDataSource.instance.getShiftCashOpTotals(shiftId);

    final expectedDrawer = summary.shift.openingCash +
        summary.cashSales +
        opTotals.serviceIn -
        opTotals.serviceOut -
        summary.cashExpenses;

    final now = DateTime.now();
    final formattedNow = DateFormat('dd.MM.yyyy HH:mm').format(now);

    lastStandardZReport = StandardZReportData(
      shiftNumber: summary.shift.id,
      openedAt: DateTime.tryParse(summary.shift.openedAt) ?? now,
      closedAt: now,
      isAutoClosed: isAutoClosed,
      openingCashCents: summary.shift.openingCash,
      cashSalesCents: summary.cashSales,
      cardTerminalSalesCents: summary.cardSales + summary.oplata24Sales,
      receiptsCount: summary.ordersCount,
      serviceInTotalCents: opTotals.serviceIn,
      serviceOutTotalCents: opTotals.serviceOut,
      expensesTotalCents: summary.cashExpenses,
      operations: cashOps,
    );

    receiptPrintData = ReceiptPrintData(
      documentTitle: isZReport
          ? 'Z-ЗВІТ (ЗАКРИТТЯ ЗМІНИ)'
          : 'X-ЗВІТ (ПРОМІЖНИЙ)',
      shiftReceiptLabel: 'Зміна №${summary.shift.id}',
      dateTimeText: formattedNow,
      summaryRows: [
        ReceiptSummaryRow(
          label: 'Видано чеків за зміну:',
          value: '${summary.ordersCount} шт',
          isBold: true,
        ),
        ReceiptSummaryRow(
          label: 'Залишок на старті:',
          value: MoneyFormatter.format(summary.shift.openingCash),
        ),
        ReceiptSummaryRow(
          label: 'Виручка (Картка):',
          value: MoneyFormatter.format(summary.cardSales),
        ),
        if (summary.oplata24Sales > 0)
          ReceiptSummaryRow(
            label: 'Виручка (Оплата24 ПБ):',
            value: MoneyFormatter.format(summary.oplata24Sales),
          ),
        ReceiptSummaryRow(
          label: 'Виручка (Готівка):',
          value: MoneyFormatter.format(summary.cashSales),
        ),
        ReceiptSummaryRow(
          label: '+ Службове внесення:',
          value: MoneyFormatter.format(opTotals.serviceIn),
        ),
        ReceiptSummaryRow(
          label: '- Службове винесення:',
          value: '-${MoneyFormatter.format(opTotals.serviceOut)}',
        ),
        ReceiptSummaryRow(
          label: 'Витрати з каси:',
          value: '-${MoneyFormatter.format(summary.cashExpenses)}',
        ),
        ReceiptSummaryRow(
          label: 'Витрати з картки:',
          value: '-${MoneyFormatter.format(summary.cardExpenses)}',
        ),
        ReceiptSummaryRow(
          label: 'Очікувана готівка в касі:',
          value: MoneyFormatter.format(expectedDrawer),
          isBold: true,
        ),
      ],
      grandTotalLabel: 'ЗАГАЛЬНА ВИРУЧКА:',
      grandTotalValue: MoneyFormatter.format(summary.totalSales),
      footerNote: isZReport ? 'Зміну успішно закрито' : 'Звіт сформовано',
      showSocials: true,
    );

    if (isZReport) {
      await _repository.closeShift(
        shiftId: shiftId,
        closingCash: expectedDrawer,
      );
      await OsnovaTelegramService.instance.notifyZReport(lastStandardZReport!);
    }

    notifyListeners();

    return ShiftReportEntity(
      shiftId: summary.shift.id,
      openedAt: summary.shift.openedAt,
      isZReport: isZReport,
      ordersCount: summary.ordersCount,
      cashSales: summary.cashSales,
      cardSales: summary.cardSales,
      oplata24Sales: summary.oplata24Sales,
      totalRevenue: summary.totalSales,
      openingCash: summary.shift.openingCash,
      cashDrawerExpenses: summary.cashExpenses,
      externalExpenses: summary.cardExpenses,
      expectedCashInDrawer: expectedDrawer,
      expensesList: expenses,
    );
  }

  List<String> buildReportReceiptLines(ShiftReportEntity report) {
    return [
      'OSNOVA • Зміна №${report.shiftId}',
      '--------------------------------',
      'Видано чеків за день: ${report.ordersCount} шт',
      'Розмін на старті:     ${MoneyFormatter.format(report.openingCash)}',
      'Виручка (Картка):     ${MoneyFormatter.format(report.cardSales)}',
      if (report.oplata24Sales > 0)
        'Виручка (Оплата24):   ${MoneyFormatter.format(report.oplata24Sales)}',
      'Виручка (Готівка):    ${MoneyFormatter.format(report.cashSales)}',
      '+ Службове внесення:  ${MoneyFormatter.format(shiftServiceInTotal)}',
      '- Службове винесення:-${MoneyFormatter.format(shiftServiceOutTotal)}',
      'Витрати з каси:      -${MoneyFormatter.format(report.cashDrawerExpenses)}',
      'Витрати з картки:    -${MoneyFormatter.format(report.externalExpenses)}',
      '--------------------------------',
      'Готівка в шухляді:    ${MoneyFormatter.format(report.expectedCashInDrawer)}',
      'ЗАГАЛЬНА ВИРУЧКА:     ${MoneyFormatter.format(report.totalRevenue)}',
    ];
  }

  Future<void> exportReportToTelegram(ShiftReportEntity report) {
    return _exportService.shareReportFile(report);
  }

  @override
  void dispose() {
    _autoCloseScheduler.dispose();
    super.dispose();
  }
}