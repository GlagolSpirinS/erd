import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'add_customers_screen.dart';
import 'add_order_details_screen.dart';
import 'add_orders_screen.dart';
import 'add_products_screen.dart';
import 'add_suppliers_screen.dart';
import 'add_transactions_screen.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'add_user_screen.dart';
import 'add_role_screen.dart';
import 'add_categories_screen.dart';
import 'charts_widget.dart';
import 'login_screen.dart';
import 'admin_logs_screen.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  try {
    print('Initializing application...');

    // Инициализация FFI для работы с SQLite на Windows
    print('Initializing SQLite FFI...');
    sqfliteFfiInit();

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      if (Platform.isWindows || Platform.isAndroid) {
        databaseFactory = databaseFactoryFfi;
        sqfliteFfiInit();
      }
    }

    databaseFactory = databaseFactoryFfi;
    print('SQLite FFI initialized successfully');

    print('Initializing Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter bindings initialized successfully');

    print('Creating database helper...');
    final dbHelper = DatabaseHelper();
    print('Database helper created successfully');

    // Инициализируем базу данных
    print('Initializing database...');
    await dbHelper.database;
    print('Database initialized successfully');

    print('Starting application...');
    runApp(MyApp());
  } catch (e, stackTrace) {
    print('Error initializing application: $e');
    print('Stack trace: $stackTrace');

    // В случае ошибки инициализации, показываем сообщение об ошибке
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Ошибка инициализации приложения',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Пожалуйста, перезапустите приложение.\nЕсли проблема сохраняется, обратитесь к администратору.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Детали ошибки: $e',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196F3),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF03A9F4),
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
          error: Color(0xFFB00020),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int userRole;
  final int UserId;

  HomeScreen({required this.userRole, required this.UserId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _availableTables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

  Future<void> _loadAvailableTables() async {
    final allTables = [
      'Роли',
      'Пользователи',
      'Поставщики',
      'Категории',
      'Товары',
      'Склады',
      'Инвентарь',
      'Клиенты',
      'Заказы',
      'Детали заказов',
      'Накладная',
      'Журнал действий',
    ];

    final Map<String, String> tableMapping = {
      'Роли': 'Roles',
      'Пользователи': 'Users',
      'Поставщики': 'Suppliers',
      'Категории': 'Categories',
      'Товары': 'Products',
      'Склады': 'Warehouses',
      'Инвентарь': 'Inventory',
      'Клиенты': 'Customers',
      'Заказы': 'Orders',
      'Детали заказов': 'Order_Details',
      'Накладная': 'Transactions',
      'Журнал действий': 'Logs',
    };

    List<String> availableTables = [];

    for (var table in allTables) {
      final hasPermission = await _dbHelper.checkRolePermission(
        widget.userRole,
        tableMapping[table]!,
        'view',
      );
      if (hasPermission) {
        availableTables.add(table);
      }
    }

    setState(() {
      _availableTables = availableTables;
      _isLoading = false;
    });
  }

  IconData _getTableIcon(String table) {
    switch (table) {
      case 'Роли':
        return Icons.security;
      case 'Пользователи':
        return Icons.people;
      case 'Поставщики':
        return Icons.local_shipping;
      case 'Категории':
        return Icons.category;
      case 'Товары':
        return Icons.inventory;
      case 'Склады':
        return Icons.warehouse;
      case 'Инвентарь':
        return Icons.inventory_2;
      case 'Клиенты':
        return Icons.person;
      case 'Заказы':
        return Icons.shopping_cart;
      case 'Детали заказов':
        return Icons.receipt_long;
      case 'Накладная':
        return Icons.swap_horiz;
      case 'Журнал действий':
        return Icons.history;
      default:
        return Icons.table_chart;
    }
  }

  Widget _buildDashboardHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Панель управления',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Добро пожаловать в систему управления складом',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context) {
    return Padding(padding: EdgeInsets.all(16), child: ChartsWidget());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Система управления складом'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (widget.userRole == 1)
            IconButton(
              icon: Icon(Icons.backup),
              onPressed: () => _showBackupDialog(context),
              tooltip: 'Создать резервную копию',
            ),
          if (widget.userRole == 1)
            IconButton(
              icon: Icon(Icons.restore),
              onPressed: () => _showRestoreDialog(context),
              tooltip: 'Восстановить из резервной копии',
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            tooltip: 'Выйти',
          ),
        ],
      ),
      drawer:
          _isLoading
              ? null
              : Drawer(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.warehouse,
                                size: 35,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Система управления складом',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._availableTables.map((table) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getTableIcon(table),
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(
                              table,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          table == 'Журнал действий'
                                              ? const AdminLogsScreen()
                                              : TableDataScreen(
                                                tableName: table,
                                                userRole: widget.userRole,
                                                UserId: widget.UserId,
                                              ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDashboardHeader(context),
                      _buildCharts(context),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _showBackupDialog(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    // Показываем диалог выбора директории
    final String? selectedPath = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите директорию для сохранения'),
          content: Text(
            'Резервная копия базы данных будет сохранена в выбранную директорию',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Здесь будет логика выбора директории
                // Для Windows можно использовать стандартный диалог выбора директории
                final String? path = await _selectDirectory();
                if (path != null) {
                  Navigator.pop(context, path);
                }
              },
              child: Text('Выбрать'),
            ),
          ],
        );
      },
    );

    if (selectedPath != null) {
      final String backupPath = join(
        selectedPath,
        'app_database_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      final bool success = await dbHelper.backupDatabase(backupPath);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Резервная копия успешно создана'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании резервной копии'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите директорию для сохранения резервной копии',
      );
      return selectedDirectory;
    } catch (e) {
      print('Error selecting directory: $e');
      return null;
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    // Показываем диалог выбора файла резервной копии
    final String? selectedPath = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Восстановление из резервной копии'),
          content: Text(
            'Выберите файл резервной копии для восстановления. Текущие данные будут заменены.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String? path = await _selectBackupFile(context);
                if (path != null) {
                  Navigator.pop(context, path);
                }
              },
              child: Text('Выбрать'),
            ),
          ],
        );
      },
    );

    if (selectedPath != null) {
      final bool success = await dbHelper.restoreDatabase(selectedPath);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('База данных успешно восстановлена'),
            backgroundColor: Colors.green,
          ),
        );
        // Перезапускаем приложение для применения изменений
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при восстановлении базы данных'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _selectBackupFile(BuildContext context) async {
    try {
      FilePickerResult? result;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, use a more specific file picker configuration
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Выберите файл резервной копии',
          allowMultiple: false,
          withData: false,
          withReadStream: false,
        );
      } else {
        // For desktop platforms, use the standard configuration
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Выберите файл резервной копии',
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!file.path!.toLowerCase().endsWith('.db')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пожалуйста, выберите файл с расширением .db'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
        return file.path;
      } else {
        // Show error message if no file was selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл не выбран'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } catch (e) {
      print('Error selecting backup file: $e');
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}

class ChartData {
  final String warehouseName;
  final int totalQuantity;

  ChartData(this.warehouseName, this.totalQuantity);
}

class TableDataScreen extends StatefulWidget {
  final String tableName;
  final int userRole;
  final int UserId;

  TableDataScreen({required this.tableName, required this.userRole, required this.UserId});

  @override
  _TableDataScreenState createState() => _TableDataScreenState();
}

class _TableDataScreenState extends State<TableDataScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> filteredData = [];
  Map<int, bool> selectedItems = {};
  String searchQuery = '';
  String sortColumn = '';
  bool sortAscending = true;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;

  final translations = {
    'role_id': 'ID роли',
    'role_name': 'Название роли',

    'user_id': 'ID пользователя',
    'name': 'Имя',
    'surname': 'Фамилия',
    'password': 'Пароль',
    'created_at': 'Дата создания',

    'supplier_id': 'ID поставщика',
    'contact_name': 'Контактное лицо',
    'phone': 'Телефон',
    'email': 'Электронная почта',
    'address': 'Адрес',

    'category_id': 'ID категории',
    'description': 'Описание',

    'product_id': 'ID товара',
    'price': 'Цена',
    'unit': 'Количество',

    'warehouse_id': 'ID склада',
    'location': 'Местоположение',

    'inventory_id': 'ID инвентаря',
    'quantity': 'Количество',
    'last_updated': 'Последнее обновление',

    'customer_id': 'ID клиента',

    'order_id': 'ID заказа',
    'order_date': 'Дата заказа',
    'status': 'Статус',

    'order_detail_id': 'ID детали заказа',

    'transaction_id': 'ID Накладная',
    'inventory_id': 'ID инвентаря',
    'transaction_type': 'Тип накладной',
    'transaction_date': 'Дата накладной',
  };

  @override
  void initState() {
    super.initState();
    fetchTableData();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final englishTableName = _getEnglishTableName(widget.tableName);
    final canCreate = await dbHelper.checkRolePermission(
      widget.userRole,
      englishTableName,
      'create',
    );
    final canUpdate = await dbHelper.checkRolePermission(
      widget.userRole,
      englishTableName,
      'update',
    );
    final canDelete = await dbHelper.checkRolePermission(
      widget.userRole,
      englishTableName,
      'delete',
    );

    setState(() {
      _canCreate = canCreate;
      _canUpdate = canUpdate;
      _canDelete = canDelete;
    });
  }

  void filterAndSortData() {
    // First filter the data based on search query
    filteredData =
        tableData.where((row) {
          if (searchQuery.isEmpty) return true;

          return row.values.any(
            (value) => value.toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          );
        }).toList();

    // Then sort the filtered data if a sort column is selected
    if (sortColumn.isNotEmpty) {
      filteredData.sort((a, b) {
        final aValue = a[sortColumn]?.toString().toLowerCase() ?? '';
        final bValue = b[sortColumn]?.toString().toLowerCase() ?? '';

        if (sortAscending) {
          return aValue.compareTo(bValue);
        } else {
          return bValue.compareTo(aValue);
        }
      });
    }
  }

  Future<void> fetchTableData() async {
    final db = await dbHelper.database;
    final String englishTableName = _getEnglishTableName(widget.tableName);
    final data = await db.query(englishTableName);
    setState(() {
      tableData = data;
      selectedItems = {};
      filterAndSortData();
    });
  }

  void _handleSort(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
      filterAndSortData();
    });
  }

  // Метод для преобразования русского названия таблицы в английское
  String _getEnglishTableName(String russianTableName) {
    switch (russianTableName) {
      case 'Роли':
        return 'Roles';
      case 'Пользователи':
        return 'Users';
      case 'Поставщики':
        return 'Suppliers';
      case 'Категории':
        return 'Categories';
      case 'Товары':
        return 'Products';
      case 'Склады':
        return 'Warehouses';
      case 'Инвентарь':
        return 'Inventory';
      case 'Клиенты':
        return 'Customers';
      case 'Заказы':
        return 'Orders';
      case 'Детали заказов':
        return 'Order_Details';
      case 'Накладная':
        return 'Transactions';
      case 'Журнал действий':
        return 'Logs';
      default:
        throw Exception('Неизвестная таблица: $russianTableName');
    }
  }

  String getPrimaryKey(String tableName) {
    switch (tableName) {
      case 'Роли':
        return 'role_id';
      case 'Пользователи':
        return 'user_id';
      case 'Поставщики':
        return 'supplier_id';
      case 'Категории':
        return 'category_id';
      case 'Товары':
        return 'product_id';
      case 'Склады':
        return 'warehouse_id';
      case 'Инвентарь':
        return 'inventory_id';
      case 'Клиенты':
        return 'customer_id';
      case 'Заказы':
        return 'order_id';
      case 'Детали заказов':
        return 'order_detail_id';
      case 'Накладная':
        return 'transaction_id';
      default:
        throw Exception('Неизвестная таблица: $tableName');
    }
  }

  Future<void> _deleteSelectedItems() async {
    final db = await dbHelper.database;
    final primaryKey = getPrimaryKey(widget.tableName);

    final selectedIds =
        selectedItems.entries
            .where(
              (entry) =>
                  entry.value && tableData[entry.key][primaryKey] != null,
            )
            .map((entry) => tableData[entry.key][primaryKey])
            .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Выберите записи для удаления.')));
      return;
    }

    // Преобразуем русское название таблицы в английское
    final String englishTableName = _getEnglishTableName(widget.tableName);

    // Логируем удаление пользователей
    if (widget.tableName == 'Пользователи') {
      for (var id in selectedIds) {
        final user = tableData.firstWhere((row) => row[primaryKey] == id);
        await dbHelper.logUserDeletion(
          id,
          '${user['name']} ${user['surname']}',
        );
      }
    }

    await db.delete(
      englishTableName,
      where:
          '$primaryKey IN (${List.filled(selectedIds.length, '?').join(',')})',
      whereArgs: selectedIds,
    );

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('Удалено ${selectedIds.length} записей.')),
    );

    fetchTableData(); // Обновляем данные после удаления
  }

  Future<void> _updateItem(Map<String, dynamic> item) async {
    final db = await dbHelper.database;
    final primaryKey = getPrimaryKey(widget.tableName);
    final String englishTableName = _getEnglishTableName(widget.tableName);

    // Логируем обновление пользователя
    if (widget.tableName == 'Пользователи') {
      final oldUser = tableData.firstWhere(
        (row) => row[primaryKey] == item[primaryKey],
      );
      final changes = _getUserChanges(oldUser, item);
      if (changes.isNotEmpty) {
        await dbHelper.logUserUpdate(
          item[primaryKey],
          '${item['name']} ${item['surname']}',
          changes,
        );
      }
    }

    await db.update(
      englishTableName,
      item,
      where: '$primaryKey = ?',
      whereArgs: [item[primaryKey]],
    );

    ScaffoldMessenger.of(
      this.context,
    ).showSnackBar(SnackBar(content: Text('Запись успешно обновлена')));

    fetchTableData(); // Обновляем данные после изменения
  }

  String _getUserChanges(
    Map<String, dynamic> oldUser,
    Map<String, dynamic> newUser,
  ) {
    List<String> changes = [];

    if (oldUser['name'] != newUser['name']) {
      changes.add('Имя: ${oldUser['name']} -> ${newUser['name']}');
    }
    if (oldUser['surname'] != newUser['surname']) {
      changes.add('Фамилия: ${oldUser['surname']} -> ${newUser['surname']}');
    }
    if (oldUser['role_id'] != newUser['role_id']) {
      changes.add('Роль: ${oldUser['role_id']} -> ${newUser['role_id']}');
    }

    return changes.join(', ');
  }

  // Метод для получения заголовка записи
  String getDisplayTitle(Map<String, dynamic> row, String tableName) {
    switch (tableName) {
      case 'Пользователи':
        return row['name']?.toString() ?? 'Пользователь ${row['user_id']}';
      case 'Товары':
        return row['name']?.toString() ?? 'Товар ${row['product_id']}';
      case 'Клиенты':
        return row['name']?.toString() ?? 'Клиент ${row['customer_id']}';
      case 'Роли':
        return row['role_name']?.toString() ?? 'Роль ${row['role_id']}';
      case 'Поставщики':
        return row['name']?.toString() ?? 'Поставщик ${row['supplier_id']}';
      case 'Категории':
        return row['name']?.toString() ?? 'Категория ${row['category_id']}';
      case 'Склады':
        return row['name']?.toString() ?? 'Склад ${row['warehouse_id']}';
      case 'Инвентарь':
        return 'Инвентарь ${row['inventory_id']}';
      case 'Заказы':
        return 'Заказ ${row['order_id']}';
      case 'Детали заказов':
        return 'Деталь заказа ${row['order_detail_id']}';
      case 'Накладная':
        return 'Транзакция ${row['transaction_id']}';
      default:
        return 'Запись ${row['id'] ?? 'N/A'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Данные таблицы: ${widget.tableName}'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Кнопка удаления записей
          IconButton(icon: Icon(Icons.delete), onPressed: _deleteSelectedItems),
          // Кнопки добавления
          if (widget.tableName == "Накладная")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddTransactionsScreen(
                            currentUserRole: widget.userRole, currentUserId: widget.UserId,
                          ),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Детали заказов")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddOrderDetailsScreen(
                            currentUserRole: widget.userRole,
                          ),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Заказы")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddOrdersScreen(currentUserRole: widget.userRole),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Клиенты")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddCustomersScreen(
                            currentUserRole: widget.userRole,
                          ),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Товары")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductsScreen(),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Категории")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddCategoriesScreen(
                            currentUserRole: widget.userRole,
                          ),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Поставщики")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddSupplierScreen(
                            currentUserRole: widget.userRole,
                          ),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == "Роли")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddRoleScreen(currentUserRole: widget.userRole),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
          if (widget.tableName == 'Пользователи')
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddUserScreen(currentUserRole: widget.userRole),
                    ),
                  );
                  fetchTableData(); // Обновляем данные после возврата
                },
              ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with improved design
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              filterAndSortData();
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterAndSortData();
                });
              },
            ),
          ),
          // Column headers with improved design
          if (filteredData.isNotEmpty)
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      filteredData[0].keys.map((key) {
                        final displayKey = translations[key] ?? key;
                        return Container(
                          width: 200,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _handleSort(key),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    displayKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                if (sortColumn == key)
                                  Icon(
                                    sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          // Data list with improved design
          Expanded(
            child:
                filteredData.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Нет данных в таблице',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final row = filteredData[index];
                        final isSelected = selectedItems[index] ?? false;
                        final primaryKey = getPrimaryKey(widget.tableName);

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ExpansionTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedItems[index] = value ?? false;
                                });
                              },
                            ),
                            title: Text(
                              getDisplayTitle(row, widget.tableName),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    ...row.entries.map((entry) {
                                      final displayKey =
                                          translations[entry.key] ?? entry.key;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 120,
                                              child: Text(
                                                displayKey,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                entry.value?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: Icon(Icons.edit),
                                          label: Text('Редактировать'),
                                          onPressed:
                                              () =>
                                                  _showEditDialog(context, row),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Добавляем метод для отображения диалога редактирования
  Future<void> _showEditDialog(
    BuildContext context,
    Map<String, dynamic> row,
  ) async {
    final formKey = GlobalKey<FormState>();
    final editedData = Map<String, dynamic>.from(row);
    List<Map<String, dynamic>> roles = [];
    int? selectedRoleId;

    // Загружаем список ролей, если редактируем пользователя
    if (widget.tableName == 'Пользователи') {
      final db = await dbHelper.database;
      roles = await db.query('Roles');
      selectedRoleId = row['role_id'];
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Редактировать запись'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      row.entries.map((entry) {
                        final displayKey = translations[entry.key] ?? entry.key;

                        // Пропускаем автоматически генерируемые поля
                        if (entry.key == 'created_at' ||
                            entry.key == 'last_updated' ||
                            entry.key == 'transaction_date' ||
                            entry.key == 'order_date') {
                          return SizedBox.shrink();
                        }

                        // Специальная обработка для роли пользователя
                        if (widget.tableName == 'Пользователи' &&
                            entry.key == 'role_id') {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: DropdownButtonFormField<int>(
                              value: selectedRoleId,
                              decoration: InputDecoration(
                                labelText: 'Роль',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  roles.map((role) {
                                    return DropdownMenuItem<int>(
                                      value: role['role_id'],
                                      child: Text(
                                        role['role_name'] ??
                                            'Роль ${role['role_id']}',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRoleId = value;
                                  editedData['role_id'] = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Выберите роль';
                                }
                                return null;
                              },
                            ),
                          );
                        }

                        // Для остальных полей используем стандартный TextFormField
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: TextFormField(
                            initialValue: entry.value?.toString() ?? '',
                            decoration: InputDecoration(
                              labelText: displayKey,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              editedData[entry.key] = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Поле не может быть пустым';
                              }
                              return null;
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await _updateItem(editedData);
                    Navigator.pop(context);
                  }
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
    );
  }
}
