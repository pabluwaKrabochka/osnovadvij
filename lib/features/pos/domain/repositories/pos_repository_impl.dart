import '../../data/datasources/pos_local_datasource.dart';
import '../entities/pos_entities.dart';
import 'pos_repositories.dart';

class PosRepositoryImpl implements PosRepository {
  final PosLocalDataSource _localDataSource;

  PosRepositoryImpl(this._localDataSource);

  @override
  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0}) {
    return _localDataSource.getOrOpenShift(
      defaultOpeningCash: defaultOpeningCash,
    );
  }

  @override
  Future<void> updateOpeningCash({required int shiftId, required int amount}) {
    return _localDataSource.updateOpeningCash(shiftId: shiftId, amount: amount);
  }

  @override
  Future<List<ProductEntity>> getActiveProducts() {
    return _localDataSource.getActiveProducts();
  }

  @override
  Future<void> addProduct({
    required String name,
    required String category,
    required int price,
    int costPrice = 0,
  }) {
    return _localDataSource.addProduct(
      name: name,
      category: category,
      price: price,
      costPrice: costPrice,
    );
  }

  @override
  Future<void> updateProduct(ProductEntity product) {
    return _localDataSource.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(int productId) {
    return _localDataSource.deleteProduct(productId);
  }

  @override
  Future<void> updateProductsOrder(List<ProductEntity> orderedProducts) {
    return _localDataSource.updateProductsOrder(orderedProducts);
  }

  @override
  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
    String? receiptCode,
    String? transactionId,
  }) {
    return _localDataSource.createOrder(
      shiftId: shiftId,
      items: items,
      paymentMethod: paymentMethod,
      receiptCode: receiptCode,
      transactionId: transactionId,
    );
  }

  @override
  Future<void> deleteOrder(int orderId) {
    return _localDataSource.deleteOrder(orderId);
  }

  @override
  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amount,
    required String source,
  }) {
    return _localDataSource.addExpense(
      shiftId: shiftId,
      title: title,
      amount: amount,
      source: source,
    );
  }

  @override
  Future<void> deleteExpense(int expenseId) {
    return _localDataSource.deleteExpense(expenseId);
  }

  @override
  Future<List<ExpenseEntity>> getShiftExpenses(int shiftId) {
    return _localDataSource.getShiftExpenses(shiftId);
  }

  @override
  Future<ShiftSummaryEntity> getShiftSummary(int shiftId) {
    return _localDataSource.getShiftSummary(shiftId);
  }

  @override
  Future<List<OrderHistoryEntity>> getShiftOrders(int shiftId) {
    return _localDataSource.getShiftOrders(shiftId);
  }

  @override
  Future<void> closeShift({required int shiftId, required int closingCash}) {
    return _localDataSource.closeShift(
      shiftId: shiftId,
      closingCash: closingCash,
    );
  }
}