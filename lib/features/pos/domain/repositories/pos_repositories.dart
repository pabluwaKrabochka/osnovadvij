import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import '../entities/pos_entities.dart';

enum PrivatPaymentState { pending, paid, failed, cancelled }

class PrivatPaymentSession {
  final String paymentToken;
  final String purpose;

  const PrivatPaymentSession({
    required this.paymentToken,
    required this.purpose,
  });
}

class PrivatPaymentPollResult {
  final PrivatPaymentState state;
  final String? rrn;
  final String? message;

  const PrivatPaymentPollResult({
    required this.state,
    this.rrn,
    this.message,
  });
}

abstract class PosRepository {
  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0});
  Future<void> updateOpeningCash({required int shiftId, required int amount});
  Future<List<ProductEntity>> getActiveProducts();
  Future<void> addProduct({
    required String name,
    required String category,
    required int price,
    int costPrice = 0,
  });
  Future<void> updateProduct(ProductEntity product);
  Future<void> deleteProduct(int productId);
  Future<void> updateProductsOrder(List<ProductEntity> orderedProducts);
  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
    String? receiptCode,
    String? transactionId,
  });
  Future<void> deleteOrder(int orderId);
  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amount,
    required String source,
  });
  Future<void> deleteExpense(int expenseId);
  Future<List<ExpenseEntity>> getShiftExpenses(int shiftId);
  Future<ShiftSummaryEntity> getShiftSummary(int shiftId);
  Future<List<OrderHistoryEntity>> getShiftOrders(int shiftId);
  Future<void> closeShift({required int shiftId, required int closingCash});
}

abstract class PrinterService {
  Future<PrinterSettingsEntity> loadSettings();
  Future<void> saveSettings({
    required String ip,
    int port = 9100,
    required bool is80mm,
  });
  Future<void> saveAutoPrint(bool enabled);
  Future<void> clearSettings();
  Future<List<String>> discoverNetworkPrinters({int port = 9100});
  Future<Uint8List?> captureWidgetAsImage(GlobalKey boundaryKey);
  Future<void> printImageOverWifi(Uint8List pngBytes);
}

abstract class PrivatTerminalService {
  Future<PrivatTerminalSettingsEntity> loadSettings();
  Future<void> saveSettings(PrivatTerminalSettingsEntity settings);
  Future<PrivatPaymentSession> initiatePayment({
    required int amountKopecks,
    required String purpose,
  });
  Future<PrivatPaymentPollResult> checkPaymentStatus(String paymentToken);
}

abstract class ReportExportService {
  Future<void> shareReportFile(ShiftReportEntity report);
}