import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Get the application documents directory
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'app_database.db');

      // Open the database
      return await openDatabase(
        path,
        version: 5,
        onCreate: (Database db, int version) async {
          print('Creating new database...');
          // Create tables and insert initial data
          await _onCreate(db, version);
          print('Database created successfully');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          print('Upgrading database from version $oldVersion to $newVersion');
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE Users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
            );
              await db.execute('DROP TABLE IF EXISTS Warehouses');
              await db.execute('DROP TABLE IF EXISTS Inventory');
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE RolePermissions (
                permission_id INTEGER PRIMARY KEY AUTOINCREMENT,
                role_id INTEGER NOT NULL,
                table_name TEXT NOT NULL,
                can_view BOOLEAN DEFAULT 0,
                can_create BOOLEAN DEFAULT 0,
                can_update BOOLEAN DEFAULT 0,
                can_delete BOOLEAN DEFAULT 0,
                FOREIGN KEY (role_id) REFERENCES Roles (role_id) ON DELETE CASCADE,
                UNIQUE(role_id, table_name)
              )
            ''');
          }
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      // If an error occurs, try to delete the database file and create it again
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'app_database.db');
      final File dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      // Retry creating the database
      return await openDatabase(
        path,
        version: 3,
        onCreate: (Database db, int version) async {
          print('Retrying database creation...');
          await _onCreate(db, version);
          print('Database created successfully on retry');
        },
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создание таблиц
    await db.execute('''
      CREATE TABLE Roles (
        role_id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_name TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE RolePermissions (
        permission_id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id INTEGER NOT NULL,
        table_name TEXT NOT NULL,
        can_view BOOLEAN DEFAULT 0,
        can_create BOOLEAN DEFAULT 0,
        can_update BOOLEAN DEFAULT 0,
        can_delete BOOLEAN DEFAULT 0,
        FOREIGN KEY (role_id) REFERENCES Roles (role_id) ON DELETE CASCADE,
        UNIQUE(role_id, table_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE Logs (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        surname TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (role_id) REFERENCES Roles (role_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES Products (product_id),
        FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Suppliers (
        supplier_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Products (
        product_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        supplier_id INTEGER,
        price NUMERIC(10,2) NOT NULL,
        quantity INTEGER,
        FOREIGN KEY (category_id) REFERENCES Categories (category_id) ON DELETE SET NULL,
        FOREIGN KEY (supplier_id) REFERENCES Suppliers (supplier_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Customers (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        user_id INTEGER,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES Customers (customer_id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Order_Details (
        order_detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        product_id INTEGER,
        quantity INTEGER NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        FOREIGN KEY (order_id) REFERENCES Orders (order_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES Products (product_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Temp_Transactions (
          transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          transaction_type TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          user_id INTEGER NOT NULL,
          FOREIGN KEY (product_id) REFERENCES Products (product_id),
          FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE
      )
    ''');

    // Вставка начальных данных
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      print('Inserting initial data...');

      // Добавляем роли
      final adminRoleId = await db.insert('Roles', {
        'role_name': 'Администратор',
      });
      print('Created admin role with ID: $adminRoleId');

      final userRoleId = await db.insert('Roles', {
        'role_name': 'Пользователь',
      });
      print('Created user role with ID: $userRoleId');

      // Добавляем все разрешения для роли администратора
      final tables = [
        'Users',
        'Roles',
        'Suppliers',
        'Categories',
        'Products',
        'Customers',
        'Orders',
        'Order_Details',
        'Transactions',
        'Logs',
      ];

      for (var table in tables) {
        await db.insert('RolePermissions', {
          'role_id': adminRoleId,
          'table_name': table,
          'can_view': 1,
          'can_create': 1,
          'can_update': 1,
          'can_delete': 1,
        });
      }
      print('Added all permissions for admin role');

      // Добавляем пользователей
      await db.insert('Users', {
        'name': 'admin',
        'surname': 'admin',
        'password': 'admin123',
        'role_id': adminRoleId,
      });
      print('Created admin user');

      await db.insert('Users', {
        'name': 'user',
        'surname': 'user',
        'password': 'user123',
        'role_id': userRoleId,
      });
      print('Created regular user');

      print('Initial data insertion completed successfully');
    } catch (e) {
      print('Error inserting initial data: $e');
      throw e; // Пробрасываем ошибку дальше для обработки
    }
  }

  // Получить продажи по категориям
  Future<List<CategorySales>> getCategorySales() async {
    final db = await this.database;
    final result = await db.rawQuery('''
      SELECT c.name as categoryName, SUM(od.quantity) as salesCount
      FROM Order_Details od
      JOIN Products p ON od.product_id = p.product_id
      JOIN Categories c ON p.category_id = c.category_id
      GROUP BY c.category_id
    ''');

    return result
        .map(
          (e) => CategorySales(
            e['categoryName'] as String,
            e['salesCount'] as int,
          ),
        )
        .toList();
  }

  // Получить распределение заказов по статусам
  Future<List<OrderStatus>> getOrderStatusDistribution() async {
    final db = await this.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM Orders
      GROUP BY status
    ''');

    return result
        .map((e) => OrderStatus(e['status'] as String, e['count'] as int))
        .toList();
  }

  Future<List<TransactionType>> getTransactionTypes() async {
    final db = await this.database;
    final result = await db.rawQuery('''
      SELECT transaction_type as type, SUM(quantity) as amount
      FROM Transactions
      GROUP BY transaction_type
    ''');

    return result
        .map((e) => TransactionType(e['type'] as String, e['amount'] as int))
        .toList();
  }

  Future<List<ProductPriceByCategory>> getProductPricesByCategory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.name as category_name, AVG(p.price) as avg_price
      FROM Categories c
      LEFT JOIN Products p ON c.category_id = p.category_id
      GROUP BY c.category_id, c.name
    ''');

    return List.generate(maps.length, (i) {
      return ProductPriceByCategory(
        maps[i]['category_name'],
        maps[i]['avg_price'] ?? 0.0,
      );
    });
  }

  Future<List<SupplierDistribution>> getSupplierDistribution() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.name as supplier_name, COUNT(p.product_id) as product_count
      FROM Suppliers s
      LEFT JOIN Products p ON s.supplier_id = p.supplier_id
      GROUP BY s.supplier_id, s.name
    ''');

    return List.generate(maps.length, (i) {
      return SupplierDistribution(
        maps[i]['supplier_name'],
        maps[i]['product_count'],
      );
    });
  }

  Future<List<MonthlySales>> getMonthlySales() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', o.order_date) as month,
        SUM(od.quantity * od.price) as total_sales
      FROM Orders o
      JOIN Order_Details od ON o.order_id = od.order_id
      GROUP BY strftime('%Y-%m', o.order_date)
      ORDER BY month DESC
      LIMIT 12
    ''');

    return List.generate(maps.length, (i) {
      return MonthlySales(maps[i]['month'], maps[i]['total_sales'] ?? 0.0);
    });
  }

  Future<List<CustomerOrders>> getCustomerOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.name as customer_name, COUNT(o.order_id) as order_count
      FROM Customers c
      LEFT JOIN Orders o ON c.customer_id = o.customer_id
      GROUP BY c.customer_id, c.name
      ORDER BY order_count DESC
      LIMIT 10
    ''');

    return List.generate(maps.length, (i) {
      return CustomerOrders(maps[i]['customer_name'], maps[i]['order_count']);
    });
  }

  Future<bool> backupDatabase(String destinationPath) async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = join(documentsDirectory.path, 'app_database.db');
      final File sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw Exception('Source database file does not exist');
      }

      // Create a copy of the database file
      await sourceFile.copy(destinationPath);
      return true;
    } catch (e) {
      print('Error backing up database: $e');
      return false;
    }
  }

  Future<bool> restoreDatabase(String backupPath) async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = join(documentsDirectory.path, 'app_database.db');
      final File backupFile = File(backupPath);
      final File dbFile = File(dbPath);

      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist');
      }

      // Close the database connection if it's open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the current database file if it exists
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Copy the backup file to the database location
      await backupFile.copy(dbPath);

      // Reinitialize the database
      _database = await _initDatabase();
      return true;
    } catch (e) {
      print('Error restoring database: $e');
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDirectory.path, 'app_database.db');
    final File dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    _database = null;
  }

  // Методы для работы с логами
  Future<void> addLog(int userId, String action, {String? details}) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logUserAction(
    int userId,
    String action,
    String entityType, {
    String? details,
  }) async {
    await addLog(userId, action, details: '$entityType: $details');
  }

  Future<void> logUserCreation(int userId, String username) async {
    await logUserAction(
      userId,
      'Создание пользователя',
      'Пользователь',
      details: 'Создан новый пользователь: $username',
    );
  }

  Future<void> logUserUpdate(
    int userId,
    String username,
    String changes,
  ) async {
    await logUserAction(
      userId,
      'Обновление пользователя',
      'Пользователь',
      details: 'Обновлен пользователь: $username. Изменения: $changes',
    );
  }

  Future<void> logUserDeletion(int userId, String username) async {
    await logUserAction(
      userId,
      'Удаление пользователя',
      'Пользователь',
      details: 'Удален пользователь: $username',
    );
  }

  Future<void> logUserLogin(int userId, String username) async {
    await logUserAction(
      userId,
      'Вход в систему',
      'Пользователь',
      details: 'Успешный вход пользователя: $username',
    );
  }

  Future<void> logUserLogout(int userId, String username) async {
    await logUserAction(
      userId,
      'Выход из системы',
      'Пользователь',
      details: 'Выход пользователя: $username',
    );
  }

  // В классе DatabaseHelper добавьте методы:
  Future<Object?> getCategoryName(int categoryId) async {
    final db = await database;
    final result = await db.query('Categories', where: 'category_id = ?', whereArgs: [categoryId]);
    return result.isNotEmpty ? result.first['name'] : null;
  }

  Future<Object?> getSupplierName(int supplierId) async {
    final db = await database;
    final result = await db.query('Suppliers', where: 'supplier_id = ?', whereArgs: [supplierId]);
    return result.isNotEmpty ? result.first['name'] : null;
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, 
        CASE 
          WHEN u.user_id IS NULL THEN 'Удаленный пользователь'
          ELSE u.name || ' ' || u.surname 
        END as username 
      FROM Logs l 
      LEFT JOIN Users u ON l.user_id = u.user_id 
      ORDER BY l.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getLogsByUserId(int userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT l.*, 
        CASE 
          WHEN u.user_id IS NULL THEN 'Удаленный пользователь'
          ELSE u.name || ' ' || u.surname 
        END as username 
      FROM Logs l 
      LEFT JOIN Users u ON l.user_id = u.user_id 
      WHERE l.user_id = ? 
      ORDER BY l.timestamp DESC
    ''',
      [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getLogsByAction(String action) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT l.*, 
        CASE 
          WHEN u.user_id IS NULL THEN 'Удаленный пользователь'
          ELSE u.name || ' ' || u.surname 
        END as username 
      FROM Logs l 
      LEFT JOIN Users u ON l.user_id = u.user_id 
      WHERE l.action = ? 
      ORDER BY l.timestamp DESC
    ''',
      [action],
    );
  }

  Future<List<Map<String, dynamic>>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT l.*, 
        CASE 
          WHEN u.user_id IS NULL THEN 'Удаленный пользователь'
          ELSE u.name || ' ' || u.surname 
        END as username 
      FROM Logs l 
      LEFT JOIN Users u ON l.user_id = u.user_id 
      WHERE l.timestamp BETWEEN ? AND ?
      ORDER BY l.timestamp DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'Users',
      where: 'name = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (users.isNotEmpty) {
      return users[0];
    }
    return null;
  }

  Future<void> logDataChange({
    required int userId,
    required String action,
    required String tableName,
    required int recordId,
    required String oldData,
    required String newData,
  }) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'old_data': oldData,
      'new_data': newData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logRoleAction(int userId, String action, String details) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logSupplierAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logCategoryAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logProductAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logWarehouseAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logInventoryAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logCustomerAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logOrderAction(int userId, String action, String details) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logOrderDetailAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<void> logTransactionAction(
    int userId,
    String action,
    String details,
  ) async {
    final db = await database;
    await db.insert('Logs', {
      'user_id': userId,
      'action': action,
      'details': details,
    });
  }

  Future<int> insertRole(Map<String, dynamic> role, int userId) async {
    final db = await database;
    final id = await db.insert('Roles', role);
    await logRoleAction(
      userId,
      'Создание роли',
      'Создана роль: ${role['role_name']}',
    );
    return id;
  }

  Future<int> updateRole(int id, Map<String, dynamic> role, int userId) async {
    final db = await database;
    final result = await db.update(
      'Roles',
      role,
      where: 'role_id = ?',
      whereArgs: [id],
    );
    await logRoleAction(
      userId,
      'Обновление роли',
      'Обновлена роль: ${role['role_name']}',
    );
    return result;
  }

  Future<int> deleteRole(int id, int userId) async {
    final db = await database;
    final role = await db.query('Roles', where: 'role_id = ?', whereArgs: [id]);
    final result = await db.delete(
      'Roles',
      where: 'role_id = ?',
      whereArgs: [id],
    );
    if (role.isNotEmpty) {
      await logRoleAction(
        userId,
        'Удаление роли',
        'Удалена роль: ${role.first['role_name']}',
      );
    }
    return result;
  }

  Future<int> insertSupplier(Map<String, dynamic> supplier, int userId) async {
    final db = await database;
    final id = await db.insert('Suppliers', supplier);
    await logSupplierAction(
      userId,
      'Создание поставщика',
      'Создан поставщик: ${supplier['name']}',
    );
    return id;
  }

  Future<int> updateSupplier(
    int id,
    Map<String, dynamic> supplier,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Suppliers',
      supplier,
      where: 'supplier_id = ?',
      whereArgs: [id],
    );
    await logSupplierAction(
      userId,
      'Обновление поставщика',
      'Обновлен поставщик: ${supplier['name']}',
    );
    return result;
  }

  Future<int> deleteSupplier(int id, int userId) async {
    final db = await database;
    final supplier = await db.query(
      'Suppliers',
      where: 'supplier_id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'Suppliers',
      where: 'supplier_id = ?',
      whereArgs: [id],
    );
    if (supplier.isNotEmpty) {
      await logSupplierAction(
        userId,
        'Удаление поставщика',
        'Удален поставщик: ${supplier.first['name']}',
      );
    }
    return result;
  }

  Future<int> insertCategory(Map<String, dynamic> category, int userId) async {
    final db = await database;
    final id = await db.insert('Categories', category);
    await logCategoryAction(
      userId,
      'Создание категории',
      'Создана категория: ${category['name']}',
    );
    return id;
  }

  Future<int> updateCategory(
    int id,
    Map<String, dynamic> category,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Categories',
      category,
      where: 'category_id = ?',
      whereArgs: [id],
    );
    await logCategoryAction(
      userId,
      'Обновление категории',
      'Обновлена категория: ${category['name']}',
    );
    return result;
  }

  Future<int> deleteCategory(int id, int userId) async {
    final db = await database;
    final category = await db.query(
      'Categories',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'Categories',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    if (category.isNotEmpty) {
      await logCategoryAction(
        userId,
        'Удаление категории',
        'Удалена категория: ${category.first['name']}',
      );
    }
    return result;
  }

  Future<int> insertProduct(Map<String, dynamic> product, int userId) async {
    final db = await database;
    final id = await db.insert('Products', product);
    await logProductAction(
      userId,
      'Создание товара',
      'Создан товар: ${product['name']}',
    );
    return id;
  }

  Future<int> updateProduct(
    int id,
    Map<String, dynamic> product,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Products',
      product,
      where: 'product_id = ?',
      whereArgs: [id],
    );
    await logProductAction(
      userId,
      'Обновление товара',
      'Обновлен товар: ${product['name']}',
    );
    return result;
  }

  Future<int> deleteProduct(int id, int userId) async {
    final db = await database;
    final product = await db.query(
      'Products',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'Products',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    if (product.isNotEmpty) {
      await logProductAction(
        userId,
        'Удаление товара',
        'Удален товар: ${product.first['name']}',
      );
    }
    return result;
  }

  Future<int> insertCustomer(Map<String, dynamic> customer, int userId) async {
    final db = await database;
    final id = await db.insert('Customers', customer);
    await logCustomerAction(
      userId,
      'Создание клиента',
      'Создан клиент: ${customer['name']}',
    );
    return id;
  }

  Future<int> updateCustomer(
    int id,
    Map<String, dynamic> customer,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Customers',
      customer,
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    await logCustomerAction(
      userId,
      'Обновление клиента',
      'Обновлен клиент: ${customer['name']}',
    );
    return result;
  }

  Future<int> deleteCustomer(int id, int userId) async {
    final db = await database;
    final customer = await db.query(
      'Customers',
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'Customers',
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    if (customer.isNotEmpty) {
      await logCustomerAction(
        userId,
        'Удаление клиента',
        'Удален клиент: ${customer.first['name']}',
      );
    }
    return result;
  }

  Future<int> insertOrder(Map<String, dynamic> order, int userId) async {
    final db = await database;
    final id = await db.insert('Orders', order);
    await logOrderAction(userId, 'Создание заказа', 'Создан заказ #$id');
    return id;
  }

  Future<int> updateOrder(
    int id,
    Map<String, dynamic> order,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Orders',
      order,
      where: 'order_id = ?',
      whereArgs: [id],
    );
    await logOrderAction(userId, 'Обновление заказа', 'Обновлен заказ #$id');
    return result;
  }

  Future<int> deleteOrder(int id, int userId) async {
    final db = await database;
    final result = await db.delete(
      'Orders',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    await logOrderAction(userId, 'Удаление заказа', 'Удален заказ #$id');
    return result;
  }

  Future<int> insertOrderDetail(
    Map<String, dynamic> orderDetail,
    int userId,
  ) async {
    final db = await database;
    final id = await db.insert('Order_Details', orderDetail);
    await logOrderDetailAction(
      userId,
      'Создание детали заказа',
      'Создана деталь заказа #${orderDetail['order_id']}',
    );
    return id;
  }

  Future<int> updateOrderDetail(
    int id,
    Map<String, dynamic> orderDetail,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Order_Details',
      orderDetail,
      where: 'order_detail_id = ?',
      whereArgs: [id],
    );
    await logOrderDetailAction(
      userId,
      'Обновление детали заказа',
      'Обновлена деталь заказа #${orderDetail['order_id']}',
    );
    return result;
  }

  Future<int> deleteOrderDetail(int id, int userId) async {
    final db = await database;
    final orderDetail = await db.query(
      'Order_Details',
      where: 'order_detail_id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'Order_Details',
      where: 'order_detail_id = ?',
      whereArgs: [id],
    );
    if (orderDetail.isNotEmpty) {
      await logOrderDetailAction(
        userId,
        'Удаление детали заказа',
        'Удалена деталь заказа #${orderDetail.first['order_id']}',
      );
    }
    return result;
  }

  Future<int> insertTransaction(
    Map<String, dynamic> transaction,
    int userId,
  ) async {
    final db = await database;
    final id = await db.insert('Transactions', transaction);
    await logTransactionAction(
      userId,
      'Создание Накладная',
      'Создана транзакция #$id',
    );
    return id;
  }

  Future<int> updateTransaction(
    int id,
    Map<String, dynamic> transaction,
    int userId,
  ) async {
    final db = await database;
    final result = await db.update(
      'Transactions',
      transaction,
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    await logTransactionAction(
      userId,
      'Обновление Накладная',
      'Обновлена транзакция #$id',
    );
    return result;
  }

  Future<int> deleteTransaction(int id, int userId) async {
    final db = await database;
    final result = await db.delete(
      'Transactions',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    await logTransactionAction(
      userId,
      'Удаление Накладная',
      'Удалена транзакция #$id',
    );
    return result;
  }

  Future<bool> checkRolePermission(
    int roleId,
    String tableName,
    String permissionType,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> permissions = await db.query(
      'RolePermissions',
      where: 'role_id = ? AND table_name = ?',
      whereArgs: [roleId, tableName],
    );

    if (permissions.isEmpty) {
      return false;
    }

    final permission = permissions.first;
    switch (permissionType) {
      case 'view':
        return permission['can_view'] == 1;
      case 'create':
        return permission['can_create'] == 1;
      case 'update':
        return permission['can_update'] == 1;
      case 'delete':
        return permission['can_delete'] == 1;
      default:
        return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRolePermissions(int roleId) async {
    final db = await database;
    return await db.query(
      'RolePermissions',
      where: 'role_id = ?',
      whereArgs: [roleId],
    );
  }
}
