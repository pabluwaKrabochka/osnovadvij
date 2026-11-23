import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/pos_entities.dart';

typedef DbRow = Map<String, Object?>;

class PosLocalDataSource {
  static final PosLocalDataSource instance = PosLocalDataSource._init();
  static Database? _database;

  PosLocalDataSource._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'osnova_pos.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    return _database!;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        opening_cash INTEGER NOT NULL DEFAULT 0,
        closing_cash_expected INTEGER,
        closing_cash_actual INTEGER,
        status TEXT NOT NULL DEFAULT 'open'
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price INTEGER NOT NULL,
        cost_price INTEGER DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER NOT NULL,
        receipt_num INTEGER NOT NULL,
        total_amount INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'cash_drawer',
        created_at TEXT NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id)
      )
    ''');

    await _seedOsnovaMenu(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.delete('products');
      await _seedOsnovaMenu(db);
    }
  }

  Future<void> _seedOsnovaMenu(Database db) async {
    final osnovaMenu = <DbRow>[
      {'name': 'Еспресо', 'category': 'Основне меню', 'price': 3000, 'cost_price': 1000},
      {'name': 'Американо', 'category': 'Основне меню', 'price': 4000, 'cost_price': 1200},
      {'name': 'Капучіно (S)', 'category': 'Основне меню', 'price': 4600, 'cost_price': 1600},
      {'name': 'Капучіно (L)', 'category': 'Основне меню', 'price': 6000, 'cost_price': 2100},
      {'name': 'Допіо', 'category': 'Основне меню', 'price': 4800, 'cost_price': 1800},
      {'name': 'Флет', 'category': 'Основне меню', 'price': 5600, 'cost_price': 2000},
      {'name': 'Лате', 'category': 'Основне меню', 'price': 6000, 'cost_price': 2100},
      {'name': 'Раф', 'category': 'Основне меню', 'price': 8400, 'cost_price': 2800},
      {'name': 'Какао', 'category': 'Основне меню', 'price': 6200, 'cost_price': 2200},
      {'name': 'Чай (45)', 'category': 'Основне меню', 'price': 4500, 'cost_price': 1200},
      {'name': 'Чай (50)', 'category': 'Основне меню', 'price': 5000, 'cost_price': 1500},
      {'name': 'Чай фірмовий (60)', 'category': 'Основне меню', 'price': 6000, 'cost_price': 1800},
      {'name': 'Молоко', 'category': 'Додатки', 'price': 600, 'cost_price': 300},
      {'name': 'Сиропи', 'category': 'Додатки', 'price': 700, 'cost_price': 300},
      {'name': 'ДеКаф', 'category': 'Додатки', 'price': 1000, 'cost_price': 500},
      {'name': 'БезЛактозне', 'category': 'Додатки', 'price': 1200, 'cost_price': 600},
      {'name': 'Трикутний тост (Курка/Сир)', 'category': 'Смаколики', 'price': 8000, 'cost_price': 3800},
      {'name': 'Трикутний тост (Шинка)', 'category': 'Смаколики', 'price': 8500, 'cost_price': 4100},
      {'name': 'Наполеон', 'category': 'Смаколики', 'price': 10000, 'cost_price': 5000},
      {'name': 'Спартак', 'category': 'Смаколики', 'price': 10000, 'cost_price': 5000},
      {'name': 'Еклер (80)', 'category': 'Смаколики', 'price': 8000, 'cost_price': 4000},
      {'name': 'Еклер (85)', 'category': 'Смаколики', 'price': 8500, 'cost_price': 4200},
      {'name': 'Горішки', 'category': 'Смаколики', 'price': 4600, 'cost_price': 2200},
      {'name': 'Кекс', 'category': 'Смаколики', 'price': 4000, 'cost_price': 1800},
      {'name': 'КапуОранж', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 4200},
      {'name': 'ЕспресоТонік', 'category': 'Холодні напої', 'price': 10000, 'cost_price': 3500},
      {'name': 'IceЛате', 'category': 'Холодні напої', 'price': 9500, 'cost_price': 3000},
      {'name': 'TiKioracao', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 4000},
      {'name': 'Moxito', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 3800},
      {'name': 'Липова насолода', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 3800},
      {'name': 'PlayStation 5 (1 год)', 'category': 'Послуги', 'price': 10000, 'cost_price': 0},
      {'name': 'Настільні ігри (вечір)', 'category': 'Послуги', 'price': 10000, 'cost_price': 0},
      {'name': 'Мафія (вечір)', 'category': 'Послуги', 'price': 10000, 'cost_price': 0},
      {'name': 'Інтелектуальні квізи (вечір)', 'category': 'Послуги', 'price': 20000, 'cost_price': 0},
      {'name': 'Літературний клуб', 'category': 'Послуги', 'price': 15000, 'cost_price': 0},
      {'name': 'Психологічна робота', 'category': 'Послуги', 'price': 30000, 'cost_price': 0},
      {'name': 'Дні народження (з людини)', 'category': 'Послуги', 'price': 10000, 'cost_price': 0},
      {'name': 'Корпоративи (з людини)', 'category': 'Послуги', 'price': 20000, 'cost_price': 0},
    ];

    for (final item in osnovaMenu) {
      await db.insert('products', {...item, 'is_active': 1});
    }
  }

  ShiftEntity _mapShift(DbRow row) {
    return ShiftEntity(
      id: row['id'] as int,
      openedAt: row['opened_at'] as String,
      closedAt: row['closed_at'] as String?,
      openingCash: (row['opening_cash'] as int?) ?? 0,
      status: (row['status'] as String?) ?? 'open',
    );
  }

  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0}) async {
    final db = await database;
    final openShifts = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      limit: 1,
    );
    if (openShifts.isNotEmpty) {
      return _mapShift(openShifts.first);
    }

    final id = await db.insert('shifts', {
      'opened_at': DateTime.now().toIso8601String(),
      'opening_cash': defaultOpeningCash,
      'status': 'open',
    });
    final created = (await db.query('shifts', where: 'id = ?', whereArgs: [id])).first;
    return _mapShift(created);
  }

  Future<List<ProductEntity>> getActiveProducts() async {
    final db = await database;
    final rows = await db.query('products', where: 'is_active = 1', orderBy: 'id ASC');
    return rows
        .map(
          (row) => ProductEntity(
            id: row['id'] as int,
            name: row['name'] as String,
            category: row['category'] as String,
            price: row['price'] as int,
            costPrice: (row['cost_price'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<void> addProduct(String name, String category, int priceKopecks) async {
    final db = await database;
    await db.insert('products', {
      'name': name,
      'category': category,
      'price': priceKopecks,
      'cost_price': 0,
      'is_active': 1,
    });
  }

  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final countRes = await txn.rawQuery(
        'SELECT COUNT(*) as cnt FROM orders WHERE shift_id = ?',
        [shiftId],
      );
      final receiptNum = (Sqflite.firstIntValue(countRes) ?? 0) + 1;
      final totalAmount = items.fold<int>(0, (sum, item) => sum + item.totalPrice);

      final orderId = await txn.insert('orders', {
        'shift_id': shiftId,
        'receipt_num': receiptNum,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'qty': item.qty,
          'unit_price': item.product.price,
        });
      }
      return receiptNum;
    });
  }

  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amountInKopecks,
    required String source,
  }) async {
    final db = await database;
    await db.insert('expenses', {
      'shift_id': shiftId,
      'title': title,
      'amount': amountInKopecks,
      'source': source,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Перераховує початковий розмін так, щоб фактична готівка в касі дорівнювала введеному значенню
  Future<void> setCurrentCashInDrawer(int shiftId, int targetCashKopecks) async {
    final db = await database;
    final currentReport = await getShiftReport(shiftId);
    final adjustedOpeningCash =
        targetCashKopecks - currentReport.cashSales + currentReport.cashDrawerExpenses;

    await db.update(
      'shifts',
      {'opening_cash': adjustedOpeningCash},
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }
Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required int priceKopecks,
    int costPriceKopecks = 0,
  }) async {
    final db = await database;
    await db.update(
      'products',
      {
        'name': name,
        'category': category,
        'price': priceKopecks,
        'cost_price': costPriceKopecks,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<List<OrderEntity>> getShiftOrders(int shiftId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        o.id,
        o.receipt_num,
        o.total_amount,
        o.payment_method,
        o.created_at,
        GROUP_CONCAT(oi.product_name || ' ×' || oi.qty, ', ') as items_summary
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.shift_id = ?
      GROUP BY o.id
      ORDER BY o.id DESC
    ''', [shiftId]);

    return rows
        .map(
          (row) => OrderEntity(
            id: row['id'] as int,
            receiptNum: row['receipt_num'] as int,
            totalAmount: row['total_amount'] as int,
            paymentMethod: row['payment_method'] as String,
            createdAt: row['created_at'] as String,
            itemsSummary: (row['items_summary'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }
  Future<ShiftReportEntity> getShiftReport(int shiftId, {bool isZReport = false}) async {
    final db = await database;
    final shift = (await db.query('shifts', where: 'id = ?', whereArgs: [shiftId])).first;

    final salesRes = await db.rawQuery('''
      SELECT
        COUNT(*) as orders_count,
        COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN total_amount ELSE 0 END), 0) as cash_sales,
        COALESCE(SUM(CASE WHEN payment_method = 'card' THEN total_amount ELSE 0 END), 0) as card_sales
      FROM orders
      WHERE shift_id = ?
    ''', [shiftId]);

    final expRes = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN source = 'cash_drawer' THEN amount ELSE 0 END), 0) as drawer_exp,
        COALESCE(SUM(CASE WHEN source != 'cash_drawer' THEN amount ELSE 0 END), 0) as ext_exp
      FROM expenses
      WHERE shift_id = ?
    ''', [shiftId]);

    final expenseRows = await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'id ASC',
    );

    final expensesList = expenseRows
        .map(
          (row) => ExpenseEntity(
            id: row['id'] as int,
            title: row['title'] as String,
            amount: row['amount'] as int,
            source: (row['source'] as String?) ?? 'cash_drawer',
            createdAt: row['created_at'] as String,
          ),
        )
        .toList();

    final s = salesRes.first;
    final e = expRes.first;

    return ShiftReportEntity(
      shiftId: shiftId,
      isZReport: isZReport,
      openedAt: shift['opened_at'] as String,
      closedAt: shift['closed_at'] as String?,
      openingCash: (shift['opening_cash'] as int?) ?? 0,
      cashSales: (s['cash_sales'] as int?) ?? 0,
      cardSales: (s['card_sales'] as int?) ?? 0,
      ordersCount: (s['orders_count'] as int?) ?? 0,
      cashDrawerExpenses: (e['drawer_exp'] as int?) ?? 0,
      externalExpenses: (e['ext_exp'] as int?) ?? 0,
      expensesList: expensesList,
    );
  }

  Future<ShiftReportEntity> closeShift(int shiftId) async {
    final db = await database;
    final report = await getShiftReport(shiftId, isZReport: true);
    await db.update(
      'shifts',
      {
        'closed_at': DateTime.now().toIso8601String(),
        'closing_cash_expected': report.expectedCashInDrawer,
        'closing_cash_actual': report.expectedCashInDrawer,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    return getShiftReport(shiftId, isZReport: true);
  }
}
