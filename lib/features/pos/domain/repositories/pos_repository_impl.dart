import 'package:osnova_pos/features/pos/data/datasources/pos_local_datasource.dart';

import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repositories.dart';

class PosRepositoryImpl implements PosRepository {
  final PosLocalDataSource _localDataSource;

  PosRepositoryImpl(this._localDataSource);

  @override
  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0}) {
    return _localDataSource.getOrOpenShift(defaultOpeningCash: defaultOpeningCash);
  }

  @override
  Future<List<ProductEntity>> getActiveProducts() {
    return _localDataSource.getActiveProducts();
  }

  @override
  Future<void> addProduct(String name, String category, int priceKopecks) {
    return _localDataSource.addProduct(name, category, priceKopecks);
  }

  @override
  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
  }) {
    return _localDataSource.createOrder(
      shiftId: shiftId,
      items: items,
      paymentMethod: paymentMethod,
    );
  }
@override
  Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required int priceKopecks,
    int costPriceKopecks = 0,
  }) {
    return _localDataSource.updateProduct(
      id: id,
      name: name,
      category: category,
      priceKopecks: priceKopecks,
      costPriceKopecks: costPriceKopecks,
    );
  }
@override
  Future<List<OrderEntity>> getShiftOrders(int shiftId) =>
      _localDataSource.getShiftOrders(shiftId);

  @override
  Future<void> deleteOrder(int orderId) =>
      _localDataSource.deleteOrder(orderId);

  @override
  Future<void> deleteExpense(int expenseId) =>
      _localDataSource.deleteExpense(expenseId);
  @override
  Future<void> deleteProduct(int id) {
    return _localDataSource.deleteProduct(id);
  }
  @override
  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amountInKopecks,
    required String source,
  }) {
    return _localDataSource.addExpense(
      shiftId: shiftId,
      title: title,
      amountInKopecks: amountInKopecks,
      source: source,
    );
  }

  @override
  Future<void> setCurrentCashInDrawer(int shiftId, int targetCashKopecks) {
    return _localDataSource.setCurrentCashInDrawer(shiftId, targetCashKopecks);
  }

  @override
  Future<ShiftReportEntity> getShiftReport(int shiftId, {bool isZReport = false}) {
    return _localDataSource.getShiftReport(shiftId, isZReport: isZReport);
  }

  @override
  Future<ShiftReportEntity> closeShift(int shiftId) {
    return _localDataSource.closeShift(shiftId);
  }
}