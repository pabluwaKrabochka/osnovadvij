import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

class PosController extends ChangeNotifier {
  final PosRepository _repository;
  final PrinterService _printerService;
  final ReportExportService _exportService;
  bool printReceipt = true;
  final GlobalKey receiptPrintKey = GlobalKey();
  bool get isPrinterConnected =>
      connectedPrinterIp != null && connectedPrinterIp!.isNotEmpty;
  bool get canPrintReceipt => isPrinterConnected && printReceipt;
  PosController({
    required PosRepository repository,
    required PrinterService printerService,
    required ReportExportService exportService,
  })  : _repository = repository,
        _printerService = printerService,
        _exportService = exportService;

  ShiftEntity? currentShift;
  int currentCashInDrawer = 0;
  List<ProductEntity> products = [];
  final List<CartItemEntity> cart = [];
  String selectedCategory = 'Усі';
  String paymentMethod = 'card';

  String receiptPreviewTitle = 'OSNOVA';
  List<String> receiptPreviewLines = ['Тестовий чек підключення'];

  final List<String> categories = const [
    'Усі',
    'Основне меню',
    'Холодні напої',
    'Смаколики',
    'Додатки',
    'Послуги',
  ];

  List<ProductEntity> get filteredProducts {
    if (selectedCategory == 'Усі') return products;
    return products.where((p) => p.category == selectedCategory).toList();
  }

  int get cartTotal => cart.fold<int>(0, (sum, item) => sum + item.totalPrice);

  int getProductCartQty(int productId) {
    final index = cart.indexWhere((e) => e.product.id == productId);
    return index == -1 ? 0 : cart[index].qty;
  }

 String? connectedPrinterIp;
 
Future<void> initPos() async {
    currentShift = await _repository.getOrOpenShift(defaultOpeningCash: 0);
    products = await _repository.getActiveProducts();
    final printer = await _printerService.loadSettings();
    connectedPrinterIp = printer.ip.isEmpty ? null : printer.ip;
    printReceipt = isPrinterConnected ? printer.autoPrint : false;
    await _refreshCashBalance();
    notifyListeners();
  }

Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required int priceKopecks,
    int costPriceKopecks = 0,
  }) async {
    await _repository.updateProduct(
      id: id,
      name: name,
      category: category,
      priceKopecks: priceKopecks,
      costPriceKopecks: costPriceKopecks,
    );
    products = await _repository.getActiveProducts();

    // Оновлюємо позицію в активному кошику, якщо вона вже там є
    final cartIndex = cart.indexWhere((item) => item.product.id == id);
    if (cartIndex != -1) {
      final updated = products.where((p) => p.id == id).firstOrNull;
      if (updated != null) {
        cart[cartIndex].product = updated;
      }
    }
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    products = await _repository.getActiveProducts();
    cart.removeWhere((item) => item.product.id == id);
    notifyListeners();
  }
  List<OrderEntity> shiftOrders = [];
  List<ExpenseEntity> shiftExpenses = [];

  Future<void> _refreshCashBalance() async {
    if (currentShift == null) return;
    final report = await _repository.getShiftReport(currentShift!.id);
    currentCashInDrawer = report.expectedCashInDrawer;
    shiftExpenses = report.expensesList.reversed.toList();
    shiftOrders = await _repository.getShiftOrders(currentShift!.id);
  }
  Future<void> deleteOrder(int orderId) async {
    await _repository.deleteOrder(orderId);
    await _refreshCashBalance();
    notifyListeners();
  }

  Future<void> deleteExpense(int expenseId) async {
    await _repository.deleteExpense(expenseId);
    await _refreshCashBalance();
    notifyListeners();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
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
  void addToCart(ProductEntity product) {
    final index = cart.indexWhere((e) => e.product.id == product.id);
    if (index != -1) {
      cart[index].qty += 1;
    } else {
      cart.add(CartItemEntity(product: product, qty: 1));
    }
    notifyListeners();
  }

  void decrementCartItem(int index) {
    if (cart[index].qty > 1) {
      cart[index].qty -= 1;
    } else {
      cart.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
Future<void> clearPrinterSettings() async {
    await _printerService.clearSettings();
    connectedPrinterIp = null;
    printReceipt = false;
    notifyListeners();
  }
  Future<void> addProduct(String name, String category, int priceKopecks) async {
    await _repository.addProduct(name, category, priceKopecks);
    products = await _repository.getActiveProducts();
    notifyListeners();
  }

  Future<void> addExpense(String title, int amountInKopecks, String source) async {
    if (currentShift == null) return;
    await _repository.addExpense(
      shiftId: currentShift!.id,
      title: title,
      amountInKopecks: amountInKopecks,
      source: source,
    );
    await _refreshCashBalance();
    notifyListeners();
  }

  Future<void> updateCashInDrawer(int targetCashKopecks) async {
    if (currentShift == null) return;
    await _repository.setCurrentCashInDrawer(currentShift!.id, targetCashKopecks);
    await _refreshCashBalance();
    notifyListeners();
  }

  Future<ShiftReportEntity?> buildReport({required bool isZReport}) async {
    if (currentShift == null) return null;
    final shiftId = currentShift!.id;
    final report = isZReport
        ? await _repository.closeShift(shiftId)
        : await _repository.getShiftReport(shiftId, isZReport: false);

    receiptPreviewTitle = isZReport ? 'Z-ЗВІТ' : 'X-ЗВІТ';
    receiptPreviewLines = buildReportReceiptLines(report);
    notifyListeners();
    return report;
  }

  List<String> buildReportReceiptLines(ShiftReportEntity report) {
    return [
      'OSNOVA • ${report.isZReport ? 'Z-ЗВІТ (ЗАКРИТТЯ ЗМІНИ)' : 'X-ЗВІТ (ПРОМІЖНИЙ)'}',
      'Відкрита: ${DateFormat('dd.MM HH:mm').format(DateTime.parse(report.openedAt))}',
      '--------------------------------',
      'Кількість чеків: ${report.ordersCount}',
      'Виручка готівка: ${MoneyFormatter.format(report.cashSales)}',
      'Виручка картка:  ${MoneyFormatter.format(report.cardSales)}',
      'ЗАГАЛЬНА ВИРУЧКА: ${MoneyFormatter.format(report.totalRevenue)}',
      '--------------------------------',
      'Розмін на старті: ${MoneyFormatter.format(report.openingCash)}',
      'Витрати з каси:   -${MoneyFormatter.format(report.cashDrawerExpenses)}',
      'Інші витрати:     ${MoneyFormatter.format(report.externalExpenses)}',
      'ГОТІВКИ В КАСІ:   ${MoneyFormatter.format(report.expectedCashInDrawer)}',
    ];
  }

  Future<void> exportReportToTelegram(ShiftReportEntity report) async {
    await _exportService.shareReportFile(report);
  }

  Future<String?> checkoutAndPrint() async {
    if (cart.isEmpty || currentShift == null) return null;

    final shiftId = currentShift!.id;
    final receiptNum = await _repository.createOrder(
      shiftId: shiftId,
      items: List<CartItemEntity>.from(cart),
      paymentMethod: paymentMethod,
    );

    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    receiptPreviewTitle = 'ЧЕК №$receiptNum';
    receiptPreviewLines = [
      'OSNOVA • КРОПИВНИЦЬКИЙ',
      'Чек №$receiptNum від $now',
      '--------------------------------',
      ...cart.map(
        (e) => '${e.product.name} x${e.qty} = ${MoneyFormatter.format(e.totalPrice)}',
      ),
      '--------------------------------',
      'РАЗОМ: ${MoneyFormatter.format(cartTotal)}',
      'Оплата: ${paymentMethod == 'card' ? 'Картка (Термінал ПБ)' : 'Готівка'}',
      'Дякуємо за візит!',
    ];

    cart.clear();
    await _refreshCashBalance();
    notifyListeners();

    return printCurrentReceipt();
  }
  Future<CheckoutResult?> checkout() async {
    if (cart.isEmpty || currentShift == null) return null;

    final shiftId = currentShift!.id;
    final receiptNum = await _repository.createOrder(
      shiftId: shiftId,
      items: List<CartItemEntity>.from(cart),
      paymentMethod: paymentMethod,
    );

    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    receiptPreviewTitle = 'ЧЕК №$receiptNum';
    receiptPreviewLines = [
      'OSNOVA • КРОПИВНИЦЬКИЙ',
      'Чек №$receiptNum від $now',
      '--------------------------------',
      ...cart.map(
        (e) => '${e.product.name} x${e.qty} = ${MoneyFormatter.format(e.totalPrice)}',
      ),
      '--------------------------------',
      'РАЗОМ: ${MoneyFormatter.format(cartTotal)}',
      'Оплата: ${paymentMethod == 'card' ? 'Картка (Термінал ПБ)' : 'Готівка'}',
      'Дякуємо за візит!',
    ];

    cart.clear();
    await _refreshCashBalance();
    notifyListeners();

    if (!canPrintReceipt) {
      return CheckoutResult(receiptNum: receiptNum, printed: false);
    }

    final printError = await printCurrentReceipt();
    return CheckoutResult(
      receiptNum: receiptNum,
      printed: true,
      printError: printError,
    );
  }
Future<String?> printCurrentReceipt() async {
    if (connectedPrinterIp == null || connectedPrinterIp!.isEmpty) {
      return 'Принтер не обрано. Натисніть ⚙ зверху та оберіть Xprinter.';
    }

    await Future.delayed(const Duration(milliseconds: 90));
    final imgBytes = await _printerService.captureWidgetAsImage(receiptPrintKey);
    if (imgBytes == null) return 'Не вдалося сформувати зображення чека';

    try {
      await _printerService.printImageOverWifi(imgBytes);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
  Future<PrinterSettingsEntity> loadPrinterSettings() => _printerService.loadSettings();

Future<void> savePrinterSettings({required String ip, required bool is80mm}) async {
    await _printerService.saveSettings(ip: ip, is80mm: is80mm);
    final updated = await _printerService.loadSettings();
    connectedPrinterIp = updated.ip.isEmpty ? null : updated.ip;
    if (isPrinterConnected) {
      printReceipt = true;
      await _printerService.saveAutoPrint(true);
    } else {
      printReceipt = false;
    }
    notifyListeners();
  }
  Future<List<String>> discoverPrinters() => _printerService.discoverNetworkPrinters();

  void prepareTestReceipt(String ip) {
    receiptPreviewTitle = 'OSNOVA • ТЕСТ';
    receiptPreviewLines = [
      'Принтер успішно підключено!',
      'IP: $ip',
      'Час: ${DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now())}',
    ];
    notifyListeners();
  }
}

class CheckoutResult {
  final int receiptNum;
  final bool printed;
  final String? printError;

  const CheckoutResult({
    required this.receiptNum,
    required this.printed,
    this.printError,
  });
}
