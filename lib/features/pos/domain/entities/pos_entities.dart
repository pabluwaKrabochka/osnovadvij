class ShiftEntity {
  final int id;
  final String openedAt;
  final String? closedAt;
  final int openingCash;
  final int? closingCash;
  final String status;

  const ShiftEntity({
    required this.id,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
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
  final ProductEntity product;
  final int qty;

  const CartItemEntity({
    required this.product,
    required this.qty,
  });

  int get totalPrice => product.price * qty;

  CartItemEntity copyWith({
    ProductEntity? product,
    int? qty,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      qty: qty ?? this.qty,
    );
  }
}

class ExpenseEntity {
  final int id;
  final int shiftId;
  final String createdAt;
  final String title;
  final int amount;
  final String source;

  const ExpenseEntity({
    required this.id,
    required this.shiftId,
    required this.createdAt,
    required this.title,
    required this.amount,
    required this.source,
  });
}

class OrderItemEntity {
  final String productName;
  final int qty;
  final int price;

  const OrderItemEntity({
    required this.productName,
    required this.qty,
    required this.price,
  });

  int get total => price * qty;
}

class OrderHistoryEntity {
  final int id;
  final int receiptNum;
  final String receiptCode;
  final String createdAt;
  final int totalAmount;
  final String paymentMethod;
  final String? transactionId;
  final List<OrderItemEntity> items;

  const OrderHistoryEntity({
    required this.id,
    required this.receiptNum,
    this.receiptCode = '',
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    this.transactionId,
    required this.items,
  });

  int get total => totalAmount;

  String get itemsSummary =>
      items.map((e) => '${e.productName} x${e.qty}').join(', ');
}

class ShiftSummaryEntity {
  final ShiftEntity shift;
  final int ordersCount;
  final int cardSales;
  final int cashSales;
  final int oplata24Sales;
  final int totalSales;
  final int cashExpenses;
  final int cardExpenses;
  final int expectedCashInDrawer;
  final Map<String, int> topProducts;

  const ShiftSummaryEntity({
    required this.shift,
    required this.ordersCount,
    required this.cardSales,
    required this.cashSales,
    this.oplata24Sales = 0,
    required this.totalSales,
    required this.cashExpenses,
    required this.cardExpenses,
    required this.expectedCashInDrawer,
    required this.topProducts,
  });
}

class ShiftReportEntity {
  final int shiftId;
  final String openedAt;
  final bool isZReport;
  final int ordersCount;
  final int cashSales;
  final int cardSales;
  final int oplata24Sales;
  final int totalRevenue;
  final int openingCash;
  final int cashDrawerExpenses;
  final int externalExpenses;
  final int expectedCashInDrawer;
  final List<ExpenseEntity> expensesList;

  const ShiftReportEntity({
    required this.shiftId,
    required this.openedAt,
    required this.isZReport,
    required this.ordersCount,
    required this.cashSales,
    required this.cardSales,
    this.oplata24Sales = 0,
    required this.totalRevenue,
    required this.openingCash,
    required this.cashDrawerExpenses,
    required this.externalExpenses,
    required this.expectedCashInDrawer,
    this.expensesList = const [],
  });
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

class PrivatTerminalSettingsEntity {
  final String clid;
  final String secret;
  final String clientToken;
  final String retailerId;
  final String cashierPhone;

  const PrivatTerminalSettingsEntity({
    required this.clid,
    required this.secret,
    required this.clientToken,
    required this.retailerId,
    required this.cashierPhone,
  });

  bool get isConfigured =>
      clid.trim().isNotEmpty &&
      secret.trim().isNotEmpty &&
      clientToken.trim().isNotEmpty &&
      cashierPhone.trim().isNotEmpty;
}