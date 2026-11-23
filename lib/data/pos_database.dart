import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ShiftModel {
  final int id;
  final String openedAt;
  final String? closedAt;
  final int openingCash;
  final String status;

  ShiftModel({
    required this.id,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.status,
  });

  factory ShiftModel.fromMap(Map<String, Object?> map) {
    return ShiftModel(
      id: map['id'] as int,
      openedAt: map['opened_at'] as String,
      closedAt: map['closed_at'] as String?,
      openingCash: (map['opening_cash'] as int?) ?? 0,
      status: (map['status'] as String?) ?? 'open',
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String category;
  final int price;
  final int costPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.costPrice = 0,
  });

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      price: map['price'] as int,
      costPrice: (map['cost_price'] as int?) ?? 0,
    );
  }
}

class CartItemModel {
  final ProductModel product;
  int qty;

  CartItemModel({required this.product, this.qty = 1});

  int get totalPrice => product.price * qty;
}

class ShiftReport {
  final int shiftId;
  final String openedAt;
  final String? closedAt;
  final int openingCash;
  final int cashSales;
  final int cardSales;
  final int ordersCount;
  final int cashDrawerExpenses;
  final int externalExpenses;

  ShiftReport({
    required this.shiftId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.cashSales,
    required this.cardSales,
    required this.ordersCount,
    required this.cashDrawerExpenses,
    required this.externalExpenses,
  });

  int get totalRevenue => cashSales + cardSales;
  int get expectedCashInDrawer => openingCash + cashSales - cashDrawerExpenses;
}

class PosDatabase {
  static final PosDatabase instance = PosDatabase._init();
  static Database? _database;

  PosDatabase._init();

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

  Future<void> syncOfficialMenu() async {
    final db = await database;
    await db.delete('products');
    await _seedOsnovaMenu(db);
  }

  Future<void> _seedOsnovaMenu(Database db) async {
    final osnovaMenu = [
      // ОСНОВНЕ МЕНЮ
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

      // ДОДАТКИ
      {'name': 'Молоко', 'category': 'Додатки', 'price': 600, 'cost_price': 300},
      {'name': 'Сиропи', 'category': 'Додатки', 'price': 700, 'cost_price': 300},
      {'name': 'ДеКаф', 'category': 'Додатки', 'price': 1000, 'cost_price': 500},
      {'name': 'БезЛактозне', 'category': 'Додатки', 'price': 1200, 'cost_price': 600},

      // СМАКОЛИКИ + ТОСТИ
      {'name': 'Трикутний тост (Курка/Сир)', 'category': 'Смаколики', 'price': 8000, 'cost_price': 3800},
      {'name': 'Трикутний тост (Шинка)', 'category': 'Смаколики', 'price': 8500, 'cost_price': 4100},
      {'name': 'Наполеон', 'category': 'Смаколики', 'price': 10000, 'cost_price': 5000},
      {'name': 'Спартак', 'category': 'Смаколики', 'price': 10000, 'cost_price': 5000},
      {'name': 'Еклер (80)', 'category': 'Смаколики', 'price': 8000, 'cost_price': 4000},
      {'name': 'Еклер (85)', 'category': 'Смаколики', 'price': 8500, 'cost_price': 4200},
      {'name': 'Горішки', 'category': 'Смаколики', 'price': 4600, 'cost_price': 2200},
      {'name': 'Кекс', 'category': 'Смаколики', 'price': 4000, 'cost_price': 1800},

      // ХОЛОДНІ НАПОЇ
      {'name': 'КапуОранж', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 4200},
      {'name': 'ЕспресоТонік', 'category': 'Холодні напої', 'price': 10000, 'cost_price': 3500},
      {'name': 'IceЛате', 'category': 'Холодні напої', 'price': 9500, 'cost_price': 3000},
      {'name': 'TiKioracao', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 4000},
      {'name': 'Moxito', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 3800},
      {'name': 'Липова насолода', 'category': 'Холодні напої', 'price': 12000, 'cost_price': 3800},

      // НАШІ ПРОПОЗИЦІЇ (ПОСЛУГИ)
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
      await db.insert('products', {
        ...item,
        'is_active': 1,
      });
    }
  }

  Future<ShiftModel> getOrOpenShift({int openingCash = 0}) async {
    final db = await database;
    final openShifts = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      limit: 1,
    );
    if (openShifts.isNotEmpty) {
      return ShiftModel.fromMap(openShifts.first);
    }

    final id = await db.insert('shifts', {
      'opened_at': DateTime.now().toIso8601String(),
      'opening_cash': openingCash,
      'status': 'open',
    });
    final created = (await db.query('shifts', where: 'id = ?', whereArgs: [id])).first;
    return ShiftModel.fromMap(created);
  }

  Future<List<ProductModel>> getActiveProducts() async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    return rows.map((row) => ProductModel.fromMap(row)).toList();
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
    required List<CartItemModel> cartItems,
    required String paymentMethod,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final countRes = await txn.rawQuery(
        'SELECT COUNT(*) as cnt FROM orders WHERE shift_id = ?',
        [shiftId],
      );
      final receiptNum = (Sqflite.firstIntValue(countRes) ?? 0) + 1;

      final totalAmount = cartItems.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final orderId = await txn.insert('orders', {
        'shift_id': shiftId,
        'receipt_num': receiptNum,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in cartItems) {
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

  Future<ShiftReport> buildShiftReport(int shiftId) async {
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

    final s = salesRes.first;
    final e = expRes.first;

    return ShiftReport(
      shiftId: shiftId,
      openedAt: shift['opened_at'] as String,
      closedAt: shift['closed_at'] as String?,
      openingCash: shift['opening_cash'] as int,
      cashSales: (s['cash_sales'] as int?) ?? 0,
      cardSales: (s['card_sales'] as int?) ?? 0,
      ordersCount: (s['orders_count'] as int?) ?? 0,
      cashDrawerExpenses: (e['drawer_exp'] as int?) ?? 0,
      externalExpenses: (e['ext_exp'] as int?) ?? 0,
    );
  }

  Future<ShiftReport> closeShift(int shiftId, int actualCashInDrawer) async {
    final db = await database;
    final report = await buildShiftReport(shiftId);
    await db.update(
      'shifts',
      {
        'closed_at': DateTime.now().toIso8601String(),
        'closing_cash_expected': report.expectedCashInDrawer,
        'closing_cash_actual': actualCashInDrawer,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    return buildShiftReport(shiftId);
  }
}