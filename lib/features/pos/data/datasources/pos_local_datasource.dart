import 'package:osnova_pos/features/pos/data/services/fortune_generator.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/pos_entities.dart';
import '../../presentation/widgets/abc_analytics_dialog.dart';
import '../../presentation/widgets/cash_operations_z_report.dart';

typedef DbRow = Map<String, dynamic>;
typedef DbRowList = List<DbRow>;
typedef DbRowListFuture = Future<DbRowList>;
typedef PragmaRow = Map<String, Object?>;

class PosLocalDataSource {
  PosLocalDataSource._();
  static final PosLocalDataSource instance = PosLocalDataSource._();

  Database? _db;
  bool _ordersHasTotalAmount = false;
  Set<String> _orderColumns = {};
  Set<String> _orderItemColumns = {};
  Map<String, String> _requiredOrderCols = {};
  Map<String, String> _requiredOrderItemCols = {};

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'osnova_pos.db');

    return openDatabase(
      path,
      version: 10,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE shifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            opened_at TEXT NOT NULL,
            closed_at TEXT,
            opening_cash INTEGER NOT NULL DEFAULT 0,
            closing_cash INTEGER,
            status TEXT NOT NULL DEFAULT 'open'
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shift_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL DEFAULT 0,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purchase_date TEXT NOT NULL,
            supplier TEXT NOT NULL,
            note TEXT,
            total_amount INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE purchase_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purchase_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            qty REAL NOT NULL DEFAULT 1,
            unit TEXT NOT NULL DEFAULT 'шт',
            unit_price INTEGER NOT NULL DEFAULT 0,
            total_price INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE fortunes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE pos_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price INTEGER NOT NULL,
            cost_price INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shift_id INTEGER NOT NULL,
            receipt_num INTEGER NOT NULL,
            receipt_code TEXT,
            created_at TEXT NOT NULL,
            total INTEGER NOT NULL DEFAULT 0,
            total_amount INTEGER NOT NULL DEFAULT 0,
            payment_method TEXT NOT NULL,
            transaction_id TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL DEFAULT 0,
            product_name TEXT NOT NULL,
            qty INTEGER NOT NULL,
            price INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shift_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            title TEXT NOT NULL,
            amount INTEGER NOT NULL,
            source TEXT NOT NULL
          )
        ''');

        await _ensureSchemaColumns(db);
        await _seedDefaultMenu(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureSchemaColumns(db);
      },
      onOpen: (db) async {
        await _ensureSchemaColumns(db);
      },
    );
  }

  Future<void> _ensureSchemaColumns(Database db) async {
    // 1. Таблиця shifts
    final shiftCols = await db.rawQuery('PRAGMA table_info(shifts)');
    final shiftColNames = shiftCols.map((c) => c['name'] as String).toSet();

    if (!shiftColNames.contains('closed_at')) {
      await db.execute('ALTER TABLE shifts ADD COLUMN closed_at TEXT');
    }
    if (!shiftColNames.contains('closing_cash')) {
      await db.execute('ALTER TABLE shifts ADD COLUMN closing_cash INTEGER');
    }
    if (!shiftColNames.contains('opening_cash')) {
      await db.execute(
        'ALTER TABLE shifts ADD COLUMN opening_cash INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!shiftColNames.contains('status')) {
      await db.execute(
        "ALTER TABLE shifts ADD COLUMN status TEXT NOT NULL DEFAULT 'open'",
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tg_event_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        topic_id INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final catCountRes =
        await db.rawQuery('SELECT COUNT(*) AS cnt FROM tg_event_categories');
    final catCount = (catCountRes.first['cnt'] as int?) ?? 0;
    if (catCount == 0) {
      final defaults = [
        {'name': 'Мафія', 'topic_id': null, 'sort_order': 1},
        {'name': 'Настільні ігри', 'topic_id': null, 'sort_order': 2},
        {'name': 'Квіз / Своя гра', 'topic_id': null, 'sort_order': 3},
        {'name': 'Літературний клуб', 'topic_id': null, 'sort_order': 4},
        {'name': 'КіноКуточок', 'topic_id': null, 'sort_order': 5},
        {'name': 'Психологічні зустрічі', 'topic_id': null, 'sort_order': 6},
        {'name': 'General', 'topic_id': null, 'sort_order': 7},
      ];
      for (final item in defaults) {
        await db.insert('tg_event_categories', item);
      }
    }
await db.execute('''
      CREATE TABLE IF NOT EXISTS tg_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        date_time_text TEXT NOT NULL DEFAULT '',
        price_text TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        tagged_subscriber_ids TEXT NOT NULL DEFAULT '',
        topic_id INTEGER,
        updated_at TEXT NOT NULL
      )
    ''');
    // 2. Таблиця службових внесень / винесень (ДПС / Poster)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL DEFAULT 0,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tg_subscribers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT ''
      )
    ''');
    // 3. Таблиця products
    final productCols = await db.rawQuery('PRAGMA table_info(products)');
    final productColNames = productCols.map((c) => c['name'] as String).toSet();

    if (!productColNames.contains('sort_order')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('UPDATE products SET sort_order = id');
    }
    if (!productColNames.contains('cost_price')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN cost_price INTEGER NOT NULL DEFAULT 0',
      );
    }

    // 4. Таблиці закупок, передбачень та налаштувань
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_date TEXT NOT NULL,
        supplier TEXT NOT NULL,
        note TEXT,
        total_amount INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        qty REAL NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT 'шт',
        unit_price INTEGER NOT NULL DEFAULT 0,
        total_price INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fortunes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 5. Таблиця orders
    var orderCols = await db.rawQuery('PRAGMA table_info(orders)');
    var orderColNames = orderCols.map((c) => c['name'] as String).toSet();

    _ordersHasTotalAmount = orderColNames.contains('total_amount');

    if (!orderColNames.contains('total')) {
      await db.execute(
        'ALTER TABLE orders ADD COLUMN total INTEGER NOT NULL DEFAULT 0',
      );
      if (_ordersHasTotalAmount) {
        await db.execute('UPDATE orders SET total = COALESCE(total_amount, 0)');
      }
    }
    if (!orderColNames.contains('receipt_code')) {
      await db.execute('ALTER TABLE orders ADD COLUMN receipt_code TEXT');
    }
    if (!orderColNames.contains('transaction_id')) {
      await db.execute('ALTER TABLE orders ADD COLUMN transaction_id TEXT');
    }

    orderCols = await db.rawQuery('PRAGMA table_info(orders)');
    _orderColumns = orderCols.map((c) => c['name'] as String).toSet();
    _requiredOrderCols = _extractRequiredColumns(orderCols);

    // 6. Таблиця order_items
    var itemCols = await db.rawQuery('PRAGMA table_info(order_items)');
    var itemColNames = itemCols.map((c) => c['name'] as String).toSet();

    if (!itemColNames.contains('price')) {
      await db.execute(
        'ALTER TABLE order_items ADD COLUMN price INTEGER NOT NULL DEFAULT 0',
      );
      if (itemColNames.contains('unit_price')) {
        await db.execute(
          'UPDATE order_items SET price = COALESCE(unit_price, 0)',
        );
      } else if (itemColNames.contains('price_at_sale')) {
        await db.execute(
          'UPDATE order_items SET price = COALESCE(price_at_sale, 0)',
        );
      }
    }

    itemCols = await db.rawQuery('PRAGMA table_info(order_items)');
    _orderItemColumns = itemCols.map((c) => c['name'] as String).toSet();
    _requiredOrderItemCols = _extractRequiredColumns(itemCols);

    await db.execute(
      'DELETE FROM orders WHERE id NOT IN (SELECT DISTINCT order_id FROM order_items)',
    );
  }

  Map<String, String> _extractRequiredColumns(List<PragmaRow> pragmaRows) {
    final result = <String, String>{};
    for (final col in pragmaRows) {
      final name = col['name'] as String;
      final pk = (col['pk'] as int?) ?? 0;
      final notNull = (col['notnull'] as int?) ?? 0;
      final dflt = col['dflt_value'];
      final type = ((col['type'] as String?) ?? 'TEXT').toUpperCase();

      if (pk == 0 && notNull == 1 && dflt == null) {
        result[name] = type;
      }
    }
    return result;
  }

  Object _defaultValueForSqlType(String sqlType) {
    if (sqlType.contains('INT') ||
        sqlType.contains('REAL') ||
        sqlType.contains('NUM') ||
        sqlType.contains('DEC')) {
      return 0;
    }
    return '';
  }

  Future<void> _seedDefaultMenu(Database db) async {
    final defaultItems = [
      {'name': 'Американо', 'category': 'Основне меню', 'price': 4000},
      {'name': 'Капучіно (S)', 'category': 'Основне меню', 'price': 4600},
      {'name': 'Капучіно (L)', 'category': 'Основне меню', 'price': 6000},
      {'name': 'Допіо', 'category': 'Основне меню', 'price': 4800},
      {'name': 'Флет', 'category': 'Основне меню', 'price': 5600},
      {'name': 'Лате', 'category': 'Основне меню', 'price': 6000},
      {'name': 'Раф', 'category': 'Основне меню', 'price': 8400},
      {'name': 'Какао', 'category': 'Основне меню', 'price': 6200},
      {'name': 'Чай (45)', 'category': 'Основне меню', 'price': 4500},
      {'name': 'КапуОранж', 'category': 'Холодні напої', 'price': 12000},
      {'name': 'ЕспресоТонік', 'category': 'Холодні напої', 'price': 10000},
      {'name': 'ІсеЛате', 'category': 'Холодні напої', 'price': 9500},
      {'name': 'ТіКіогасао', 'category': 'Холодні напої', 'price': 12000},
      {'name': 'Спартак', 'category': 'Смаколики', 'price': 10000},
      {'name': 'Еклер (80)', 'category': 'Смаколики', 'price': 8000},
      {'name': 'Еклер (85)', 'category': 'Смаколики', 'price': 8500},
      {'name': 'Горішки', 'category': 'Смаколики', 'price': 4600},
      {'name': 'Кекс', 'category': 'Смаколики', 'price': 4000},
      {'name': 'Молоко', 'category': 'Додатки', 'price': 600},
      {'name': 'Сиропи', 'category': 'Додатки', 'price': 700},
      {'name': 'ДеКаф', 'category': 'Додатки', 'price': 1000},
      {'name': 'БезЛактозне', 'category': 'Додатки', 'price': 1200},
      {'name': 'PlayStation 5 (1 год)', 'category': 'Послуги', 'price': 10000},
      {'name': 'Мафія (вечір)', 'category': 'Послуги', 'price': 10000},
      {'name': 'Інтелектуальні квізи (вечір)', 'category': 'Послуги', 'price': 30000},
      {'name': 'Настільні ігри (вечір)', 'category': 'Послуги', 'price': 10000},
      {'name': 'Дні народження (з людини)', 'category': 'Послуги', 'price': 10000},
      {'name': 'Психологічна робота', 'category': 'Послуги', 'price': 40000},
    ];

    final batch = db.batch();
    for (int i = 0; i < defaultItems.length; i++) {
      final item = defaultItems[i];
      batch.insert('products', {
        'name': item['name'],
        'category': item['category'],
        'price': item['price'],
        'cost_price': 0,
        'is_active': 1,
        'sort_order': i,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<ShiftEntity> getOrOpenShift({int defaultOpeningCash = 0}) async {
    final db = await database;
    final openShifts = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (openShifts.isNotEmpty) {
      final row = openShifts.first;
      return ShiftEntity(
        id: row['id'] as int,
        openedAt: row['opened_at'] as String,
        closedAt: row['closed_at'] as String?,
        openingCash: row['opening_cash'] as int,
        closingCash: row['closing_cash'] as int?,
        status: row['status'] as String,
      );
    }

    final now = DateTime.now().toIso8601String();
    final id = await db.insert('shifts', {
      'opened_at': now,
      'opening_cash': defaultOpeningCash,
      'status': 'open',
    });

    return ShiftEntity(
      id: id,
      openedAt: now,
      openingCash: defaultOpeningCash,
      status: 'open',
    );
  }

  Future<void> updateOpeningCash({
    required int shiftId,
    required int amount,
  }) async {
    final db = await database;
    await db.update(
      'shifts',
      {'opening_cash': amount},
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }
// ==================== КАТЕГОРІЇ ПОДІЙ ТА ПРИВ'ЯЗКА ДО ГІЛОК ТГ ====================

  DbRowListFuture getTgEventCategories() async {
    final db = await database;
    return db.query('tg_event_categories', orderBy: 'sort_order ASC, id ASC');
  }

  Future<int> saveTgEventCategory({
    int? id,
    required String name,
    int? topicId,
  }) async {
    final db = await database;
    final cleanTopic = (topicId != null && topicId > 1) ? topicId : null;
    final data = <String, dynamic>{
      'name': name.trim(),
      'topic_id': cleanTopic,
    };

    if (id != null) {
      await db.update(
        'tg_event_categories',
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    } else {
      data['sort_order'] = DateTime.now().millisecondsSinceEpoch;
      return db.insert('tg_event_categories', data);
    }
  }

  Future<void> deleteTgEventCategory(int id) async {
    final db = await database;
    await db.delete('tg_event_categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== СЛУЖБОВЕ ВНЕСЕННЯ / ВИНЕСЕННЯ ====================

  Future<void> addCashOperation({
    required int shiftId,
    required CashOpType type,
    required int amountCents,
    required String reason,
  }) async {
    final db = await database;
    await db.insert('cash_operations', {
      'shift_id': shiftId,
      'type': type == CashOpType.serviceIn ? 'service_in' : 'service_out',
      'amount': amountCents,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<CashOperationRecord>> getShiftCashOperations(int shiftId) async {
    final db = await database;
    final rows = await db.query(
      'cash_operations',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'id ASC',
    );

    return rows.map((r) {
      final rawType = r['type'] as String? ?? 'service_in';
      return CashOperationRecord(
        id: r['id'] as int,
        type: rawType == 'service_out'
            ? CashOpType.serviceOut
            : CashOpType.serviceIn,
        amountCents: (r['amount'] as int?) ?? 0,
        reason: (r['reason'] as String?) ?? '',
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<({int serviceIn, int serviceOut})> getShiftCashOpTotals(
    int shiftId,
  ) async {
    final ops = await getShiftCashOperations(shiftId);
    int serviceIn = 0;
    int serviceOut = 0;
    for (final op in ops) {
      if (op.type == CashOpType.serviceIn) {
        serviceIn += op.amountCents;
      } else {
        serviceOut += op.amountCents;
      }
    }
    return (serviceIn: serviceIn, serviceOut: serviceOut);
  }
// ==================== ПОДІЇ ДЛЯ TELEGRAM (СТВОРЕННЯ / РЕДАГУВАННЯ) ====================

  DbRowListFuture getTgEvents() async {
    final db = await database;
    return db.query('tg_events', orderBy: 'id DESC');
  }

  Future<int> saveTgEvent({
    int? id,
    required String category,
    required String title,
    required String dateTimeText,
    required String priceText,
    required String description,
    required List<int> taggedSubscriberIds,
    int? topicId,
  }) async {
    final db = await database;
    final data = <String, dynamic>{
      'category': category.trim(),
      'title': title.trim(),
      'date_time_text': dateTimeText.trim(),
      'price_text': priceText.trim(),
      'description': description.trim(),
      'tagged_subscriber_ids': taggedSubscriberIds.join(','),
      'topic_id': (topicId != null && topicId > 1) ? topicId : null,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id != null) {
      await db.update(
        'tg_events',
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    } else {
      return db.insert('tg_events', data);
    }
  }

  Future<void> deleteTgEvent(int id) async {
    final db = await database;
    await db.delete('tg_events', where: 'id = ?', whereArgs: [id]);
  }
// ==================== УЧАСНИКИ ТА ТЕГИ ДЛЯ TELEGRAM ====================

  DbRowListFuture getTgSubscribers() async {
    final db = await database;
    return db.query('tg_subscribers', orderBy: 'id DESC');
  }

  Future<void> addTgSubscriber({
    required String name,
    required String username,
    required List<String> tags,
  }) async {
    final cleanTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();
    if (cleanTags.isEmpty) {
      throw ArgumentError('Оберіть хоча б один напрямок для учасника');
    }

    final db = await database;
    var cleanUser = username.trim();
    if (cleanUser.isNotEmpty && !cleanUser.startsWith('@')) {
      cleanUser = '@$cleanUser';
    }
    await db.insert('tg_subscribers', {
      'name': name.trim(),
      'username': cleanUser,
      'tags': cleanTags.join(','),
    });
  }

  Future<void> updateTgSubscriberTags({
    required int id,
    required List<String> tags,
  }) async {
    final cleanTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();
    if (cleanTags.isEmpty) {
      throw ArgumentError('Потрібен хоча б один напрямок');
    }

    final db = await database;
    await db.update(
      'tg_subscribers',
      {'tags': cleanTags.join(',')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTgSubscriber(int id) async {
    final db = await database;
    await db.delete('tg_subscribers', where: 'id = ?', whereArgs: [id]);
  }
  // ==================== ABC-АНАЛІЗ ПРОДАЖІВ ====================

  Future<List<ProductSalesStat>> getProductSalesStats({
    int daysBack = 30,
  }) async {
    final db = await database;
    final sinceIso = DateTime.now()
        .subtract(Duration(days: daysBack))
        .toIso8601String();

    final rows = await db.rawQuery('''
      SELECT
        oi.product_name AS name,
        COALESCE(MAX(p.category), 'Основне меню') AS category,
        SUM(oi.qty) AS qty_sold,
        SUM(oi.qty * oi.price) AS revenue_cents
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      LEFT JOIN products p ON p.name = oi.product_name
      WHERE o.created_at >= ?
      GROUP BY oi.product_name
      ORDER BY revenue_cents DESC
    ''', [sinceIso]);

    return rows.map((r) {
      return ProductSalesStat(
        name: (r['name'] as String?) ?? 'Без назви',
        category: (r['category'] as String?) ?? 'Основне меню',
        qtySold: (r['qty_sold'] as num?)?.toInt() ?? 0,
        revenueCents: (r['revenue_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  // ==================== НАЛАШТУВАННЯ TELEGRAM ====================

  Future<({String token, String chatId})> loadTelegramSettings() async {
    final db = await database;
    final rows = await db.query(
      'pos_settings',
      where: 'key IN (?, ?)',
      whereArgs: ['tg_bot_token', 'tg_chat_id'],
    );
    String token = '';
    String chatId = '';
    for (final r in rows) {
      if (r['key'] == 'tg_bot_token') token = (r['value'] as String?) ?? '';
      if (r['key'] == 'tg_chat_id') chatId = (r['value'] as String?) ?? '';
    }
    return (token: token, chatId: chatId);
  }

  Future<void> saveTelegramSettings({
    required String token,
    required String chatId,
  }) async {
    final db = await database;
    await db.insert(
      'pos_settings',
      {'key': 'tg_bot_token', 'value': token.trim()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'pos_settings',
      {'key': 'tg_chat_id', 'value': chatId.trim()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProductEntity>> getActiveProducts() async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, id ASC',
    );

    return rows
        .map(
          (r) => ProductEntity(
            id: r['id'] as int,
            name: r['name'] as String,
            category: r['category'] as String,
            price: r['price'] as int,
            costPrice: (r['cost_price'] as int?) ?? 0,
            isActive: (r['is_active'] as int) == 1,
            sortOrder: (r['sort_order'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required int price,
    int costPrice = 0,
  }) async {
    final db = await database;
    final maxRes = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), 0) AS max_order FROM products',
    );
    final nextOrder = ((maxRes.first['max_order'] as int?) ?? 0) + 1;

    await db.insert('products', {
      'name': name,
      'category': category,
      'price': price,
      'cost_price': costPrice,
      'is_active': 1,
      'sort_order': nextOrder,
    });
  }

  Future<void> updateProduct(ProductEntity product) async {
    final db = await database;
    await db.update(
      'products',
      {
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'cost_price': product.costPrice,
        'is_active': product.isActive ? 1 : 0,
        'sort_order': product.sortOrder,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int productId) async {
    final db = await database;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> updateProductsOrder(List<ProductEntity> orderedProducts) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedProducts.length; i++) {
      batch.update(
        'products',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedProducts[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> createOrder({
    required int shiftId,
    required List<CartItemEntity> items,
    required String paymentMethod,
    String? receiptCode,
    String? transactionId,
  }) async {
    final db = await database;

    return db.transaction((txn) async {
      final countRes = await txn.rawQuery(
        'SELECT COALESCE(MAX(receipt_num), 0) AS max_num FROM orders WHERE shift_id = ?',
        [shiftId],
      );
      final receiptNum = ((countRes.first['max_num'] as int?) ?? 0) + 1;
      final total = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
      final now = DateTime.now().toIso8601String();

      final orderRow = <String, Object?>{
        'shift_id': shiftId,
        'receipt_num': receiptNum,
        'receipt_code': receiptCode ?? '',
        'created_at': now,
        'total': total,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
      };

      if (_ordersHasTotalAmount) {
        orderRow['total_amount'] = total;
      }
      if (_orderColumns.contains('status')) {
        orderRow['status'] = 'completed';
      }

      for (final entry in _requiredOrderCols.entries) {
        orderRow.putIfAbsent(
          entry.key,
          () => _defaultValueForSqlType(entry.value),
        );
      }

      final orderId = await txn.insert('orders', orderRow);

      for (final item in items) {
        final itemRow = <String, Object?>{
          'order_id': orderId,
          'product_name': item.product.name,
          'qty': item.qty,
          'price': item.product.price,
        };

        if (_orderItemColumns.contains('product_id')) {
          itemRow['product_id'] = item.product.id;
        }
        if (_orderItemColumns.contains('unit_price')) {
          itemRow['unit_price'] = item.product.price;
        }
        if (_orderItemColumns.contains('price_at_sale')) {
          itemRow['price_at_sale'] = item.product.price;
        }
        if (_orderItemColumns.contains('total_price')) {
          itemRow['total_price'] = item.totalPrice;
        }
        if (_orderItemColumns.contains('subtotal')) {
          itemRow['subtotal'] = item.totalPrice;
        }

        for (final entry in _requiredOrderItemCols.entries) {
          itemRow.putIfAbsent(
            entry.key,
            () => _defaultValueForSqlType(entry.value),
          );
        }

        await txn.insert('order_items', itemRow);
      }

      return receiptNum;
    });
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> addExpense({
    required int shiftId,
    required String title,
    required int amount,
    required String source,
  }) async {
    final db = await database;
    await db.insert('expenses', {
      'shift_id': shiftId,
      'created_at': DateTime.now().toIso8601String(),
      'title': title,
      'amount': amount,
      'source': source,
    });
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<List<ExpenseEntity>> getShiftExpenses(int shiftId) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'id DESC',
    );
    return rows
        .map(
          (e) => ExpenseEntity(
            id: e['id'] as int,
            shiftId: e['shift_id'] as int,
            createdAt: e['created_at'] as String,
            title: e['title'] as String,
            amount: e['amount'] as int,
            source: e['source'] as String,
          ),
        )
        .toList();
  }

  Future<ShiftSummaryEntity> getShiftSummary(int shiftId) async {
    final db = await database;
    final shiftRows = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
      limit: 1,
    );

    final shiftRow = shiftRows.first;
    final shift = ShiftEntity(
      id: shiftRow['id'] as int,
      openedAt: shiftRow['opened_at'] as String,
      closedAt: shiftRow['closed_at'] as String?,
      openingCash: shiftRow['opening_cash'] as int,
      closingCash: shiftRow['closing_cash'] as int?,
      status: shiftRow['status'] as String,
    );

    final orderRows = await db.query(
      'orders',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
    );

    int cardSales = 0;
    int cashSales = 0;
    int oplata24Sales = 0;
    for (final o in orderRows) {
      final total = (o['total'] as int?) ?? (o['total_amount'] as int?) ?? 0;
      final method = o['payment_method'] as String;
      if (method == 'card') {
        cardSales += total;
      } else if (method == 'oplata24') {
        oplata24Sales += total;
      } else {
        cashSales += total;
      }
    }

    final expenseRows = await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
    );

    int cashExpenses = 0;
    int cardExpenses = 0;
    for (final e in expenseRows) {
      final amount = e['amount'] as int;
      final src = e['source'] as String;
      if (src == 'cash_drawer' || src == 'cash') {
        cashExpenses += amount;
      } else {
        cardExpenses += amount;
      }
    }

    final cashOpTotals = await getShiftCashOpTotals(shiftId);

    final topRows = await db.rawQuery('''
      SELECT oi.product_name, SUM(oi.qty) AS total_qty
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      WHERE o.shift_id = ?
      GROUP BY oi.product_name
      ORDER BY total_qty DESC
    ''', [shiftId]);

    final topProducts = <String, int>{};
    for (final row in topRows) {
      topProducts[row['product_name'] as String] = (row['total_qty'] as int?) ?? 0;
    }

    final expectedCash = shift.openingCash +
        cashSales +
        cashOpTotals.serviceIn -
        cashOpTotals.serviceOut -
        cashExpenses;

    return ShiftSummaryEntity(
      shift: shift,
      ordersCount: orderRows.length,
      cardSales: cardSales,
      cashSales: cashSales,
      oplata24Sales: oplata24Sales,
      totalSales: cardSales + cashSales + oplata24Sales,
      cashExpenses: cashExpenses,
      cardExpenses: cardExpenses,
      expectedCashInDrawer: expectedCash,
      topProducts: topProducts,
    );
  }

  Future<List<OrderHistoryEntity>> getShiftOrders(int shiftId) async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'id DESC',
    );

    final result = <OrderHistoryEntity>[];
    for (final o in orderRows) {
      final orderId = o['id'] as int;
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final items = itemRows
          .map(
            (i) => OrderItemEntity(
              productName: i['product_name'] as String,
              qty: i['qty'] as int,
              price: (i['price'] as int?) ??
                  (i['unit_price'] as int?) ??
                  (i['price_at_sale'] as int?) ??
                  0,
            ),
          )
          .toList();

      final orderTotal =
          (o['total'] as int?) ?? (o['total_amount'] as int?) ?? 0;

      result.add(
        OrderHistoryEntity(
          id: orderId,
          receiptNum: o['receipt_num'] as int,
          receiptCode: (o['receipt_code'] as String?) ?? '',
          createdAt: o['created_at'] as String,
          totalAmount: orderTotal,
          paymentMethod: o['payment_method'] as String,
          transactionId: o['transaction_id'] as String?,
          items: items,
        ),
      );
    }

    return result;
  }

  Future<void> closeShift({
    required int shiftId,
    required int closingCash,
  }) async {
    final db = await database;
    await db.update(
      'shifts',
      {
        'closed_at': DateTime.now().toIso8601String(),
        'closing_cash': closingCash,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  // ==================== ЗАКУПКИ ТА НАКЛАДНІ ====================

  Future<int> createPurchase({
    required DateTime purchaseDate,
    required String supplier,
    String? note,
    required DbRowList items,
  }) async {
    final db = await database;
    final dateStr =
        '${purchaseDate.year.toString().padLeft(4, '0')}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}';

    final totalAmount = items.fold<int>(
      0,
      (sum, item) => sum + (item['total_price'] as int),
    );

    return db.transaction((txn) async {
      final purchaseId = await txn.insert('purchases', {
        'purchase_date': dateStr,
        'supplier': supplier.trim(),
        'note': note?.trim(),
        'total_amount': totalAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'name': item['name'],
          'category': item['category'],
          'qty': item['qty'],
          'unit': item['unit'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        });
      }

      return purchaseId;
    });
  }

  Future<void> updatePurchase({
    required int purchaseId,
    required DateTime purchaseDate,
    required String supplier,
    String? note,
    required DbRowList items,
  }) async {
    final db = await database;
    final dateStr =
        '${purchaseDate.year.toString().padLeft(4, '0')}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}';

    final totalAmount = items.fold<int>(
      0,
      (sum, item) => sum + (item['total_price'] as int),
    );

    await db.transaction((txn) async {
      await txn.update(
        'purchases',
        {
          'purchase_date': dateStr,
          'supplier': supplier.trim(),
          'note': note?.trim(),
          'total_amount': totalAmount,
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      await txn.delete(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      for (final item in items) {
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'name': item['name'],
          'category': item['category'],
          'qty': item['qty'],
          'unit': item['unit'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        });
      }
    });
  }

  DbRowListFuture getPurchasesByMonth({
    required int year,
    required int month,
  }) async {
    final db = await database;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-%';

    final purchaseRows = await db.query(
      'purchases',
      where: 'purchase_date LIKE ?',
      whereArgs: [prefix],
      orderBy: 'purchase_date DESC, id DESC',
    );

    final result = <DbRow>[];
    for (final pRow in purchaseRows) {
      final id = pRow['id'] as int;
      final itemRows = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
      result.add({
        ...pRow,
        'items': itemRows,
      });
    }
    return result;
  }

  Future<void> deletePurchase(int purchaseId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );
      await txn.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
    });
  }

  // ==================== ЩАСЛИВІ ПЕРЕДБАЧЕННЯ ====================

  Future<bool> isFortuneEnabled() async {
    final db = await database;
    final rows = await db.query(
      'pos_settings',
      where: 'key = ?',
      whereArgs: ['fortune_enabled'],
      limit: 1,
    );
    if (rows.isEmpty) return true;
    return rows.first['value'] == '1';
  }

  Future<void> setFortuneEnabled(bool enabled) async {
    final db = await database;
    await db.insert(
      'pos_settings',
      {
        'key': 'fortune_enabled',
        'value': enabled ? '1' : '0',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  DbRowListFuture getCustomFortunes() async {
    final db = await database;
    return db.query('fortunes', orderBy: 'id DESC');
  }

  Future<void> addCustomFortune(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final db = await database;
    await db.insert('fortunes', {'text': clean, 'is_active': 1});
  }

  Future<void> deleteCustomFortune(int id) async {
    final db = await database;
    await db.delete('fortunes', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getRandomFortuneForReceipt() async {
    final enabled = await isFortuneEnabled();
    if (!enabled) return null;

    final customRows = await getCustomFortunes();
    final customTexts = customRows
        .where((r) => (r['is_active'] as int? ?? 1) == 1)
        .map((r) => r['text'] as String)
        .toList();

    return FortuneGenerator.generate(customFortunes: customTexts);
  }
}