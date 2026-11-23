import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import '../entities/pos_entities.dart';

abstract class PosRepository {
  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0});
  Future<List<ProductEntity>> getActiveProducts();
  Future<void> addProduct(String name, String category, int priceKopecks);
  Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required int priceKopecks,
    int costPriceKopecks = 0,
  });
  Future<void> deleteProduct(int id);
  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
  });
  Future<List<OrderEntity>> getShiftOrders(int shiftId);
  Future<void> deleteOrder(int orderId);
  Future<void> deleteExpense(int expenseId);
  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amountInKopecks,
    required String source,
  });
  
  Future<void> setCurrentCashInDrawer(int shiftId, int targetCashKopecks);
  Future<ShiftReportEntity> getShiftReport(int shiftId, {bool isZReport = false});
  Future<ShiftReportEntity> closeShift(int shiftId);
}

abstract class PrinterService {
Future<PrinterSettingsEntity> loadSettings();
  Future<void> saveSettings({required String ip, int port = 9100, required bool is80mm});
  Future<void> saveAutoPrint(bool enabled);
  Future<void> clearSettings();
  Future<List<String>> discoverNetworkPrinters({int port = 9100});
  Future<Uint8List?> captureWidgetAsImage(GlobalKey boundaryKey);
  Future<void> printImageOverWifi(Uint8List pngBytes);
}
abstract class ReportExportService {
  Future<void> shareReportFile(ShiftReportEntity report);
}

