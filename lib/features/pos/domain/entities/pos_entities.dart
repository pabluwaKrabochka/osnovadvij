class ShiftEntity {
  final int id;
  final String openedAt;
  final String? closedAt;
  final int openingCash;
  final String status;

  const ShiftEntity({
    required this.id,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.status,
  });
}

class ProductEntity {
  final int id;
  final String name;
  final String category;
  final int price;
  final int costPrice;
  final bool isActive;
  final int sortOrder;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.costPrice = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });
}

class CartItemEntity {
  ProductEntity product;
  int qty;

  CartItemEntity({required this.product, this.qty = 1});

  int get totalPrice => product.price * qty;
}

class ExpenseEntity {
  final int id;
  final String title;
  final int amount;
  final String source;
  final String createdAt;

  const ExpenseEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.source,
    required this.createdAt,
  });
}
class OrderEntity {
  final int id;
  final int receiptNum;
  final int totalAmount;
  final String paymentMethod;
  final String createdAt;
  final String itemsSummary;

  const OrderEntity({
    required this.id,
    required this.receiptNum,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.itemsSummary,
  });
}
class ShiftReportEntity {
  final int shiftId;
  final bool isZReport;
  final String openedAt;
  final String? closedAt;
  final int openingCash;
  final int cashSales;
  final int cardSales;
  final int ordersCount;
  final int cashDrawerExpenses;
  final int externalExpenses;
  final List<ExpenseEntity> expensesList;

  const ShiftReportEntity({
    required this.shiftId,
    required this.isZReport,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.cashSales,
    required this.cardSales,
    required this.ordersCount,
    required this.cashDrawerExpenses,
    required this.externalExpenses,
    required this.expensesList,
  });

  int get totalRevenue => cashSales + cardSales;
  int get expectedCashInDrawer => openingCash + cashSales - cashDrawerExpenses;
}

class PrinterSettingsEntity {
  final String ip;
  final int port;
  final bool is80mm;
  final bool autoPrint;

  const PrinterSettingsEntity({
    required this.ip,
    required this.port,
    required this.is80mm,
    this.autoPrint = true,
  });
}