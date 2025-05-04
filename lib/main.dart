import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'database_management_screen.dart';
import 'package:excel/excel.dart' as excel_lib;

void main() async {
  try {
    print('Initializing application...');

    // Сначала инициализируем Flutter bindings
    print('Initializing Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter bindings initialized successfully');

    // Инициализация FFI для работы с SQLite на Windows
    print('Initializing SQLite FFI...');
    if (kIsWeb) {
      // Use web implementation on the web
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // Use ffi on desktop platforms
      if (Platform.isLinux || Platform.isWindows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }
    print('SQLite FFI initialized successfully');

    // Инициализация Firebase после Flutter bindings
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

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
      'Накладная',
      'Журнал действий',
    ];

    final Map<String, String> tableMapping = {
      'Роли': 'Roles',
      'Пользователи': 'Users',
      'Поставщики': 'Suppliers',
      'Категории': 'Categories',
      'Товары': 'Products',
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
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DatabaseManagementScreen(),
                  ),
                );
              },
              tooltip: 'Управление базой данных',
            ),
        ],
      ),
      drawer: _isLoading
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
                                builder: (context) => table == 'Журнал действий'
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
      body: _isLoading
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

  TableDataScreen({
    required this.tableName,
    required this.userRole,
    required this.UserId,
  });

  @override
  _TableDataScreenState createState() => _TableDataScreenState();
}

class _TableDataScreenState extends State<TableDataScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> filteredData = [];
  Set<int> selectedRows = {};
  String searchQuery = '';
  bool _canCreate = false;
  String? _sortColumn;
  bool _sortAscending = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

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
    'customer_id': 'ID клиента',
    'transaction_id': 'ID Накладная',
    'transaction_type': 'Тип накладной',
    'transaction_date': 'Дата накладной',
    'category_name': 'Название категории',
    'supplier_name': 'Название поставщика',
    'quantity': 'Количество',
    'category_id_original': 'ID категории',
    'supplier_id_original': 'ID поставщика',
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

    setState(() {
      _canCreate = canCreate;
    });
  }

  Future<void> fetchTableData() async {
    final db = await dbHelper.database;
    final String englishTableName = _getEnglishTableName(widget.tableName);

    if (englishTableName == 'Products') {
      final data = await db.rawQuery('''
        SELECT 
          p.*,
          c.name as category_name,
          s.name as supplier_name,
          c.category_id,
          s.supplier_id
        FROM Products p
        LEFT JOIN Categories c ON p.category_id = c.category_id
        LEFT JOIN Suppliers s ON p.supplier_id = s.supplier_id
      ''');

      setState(() {
        tableData = data.map((row) {
          final newRow = Map<String, dynamic>.from(row);
          newRow['category_id'] = row['category_name'] ?? 'Нет категории';
          newRow['supplier_id'] = row['supplier_name'] ?? 'Нет поставщика';
          return newRow;
        }).toList();
        filteredData = tableData;
      });
    } else if (englishTableName == 'Transactions') {
      final data = await db.rawQuery('''
        SELECT 
          t.transaction_id,
          p.name as product_id,
          t.transaction_type,
          t.quantity,
          t.transaction_date,
          u.name || ' ' || u.surname as user_id
        FROM Transactions t
        LEFT JOIN Products p ON t.product_id = p.product_id
        LEFT JOIN Users u ON t.user_id = u.user_id
      ''');

      setState(() {
        tableData = data.map((row) {
          return Map<String, dynamic>.from(row);
        }).toList();
        filteredData = tableData;
      });
    } else {
      final data = await db.query(englishTableName);
      setState(() {
        tableData = data;
        filteredData = tableData;
      });
    }
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }

      // Создаем новый список для сортировки
      filteredData = List<Map<String, dynamic>>.from(filteredData);

      filteredData.sort((a, b) {
        final aValue = a[column];
        final bValue = b[column];

        // Обработка null значений
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;

        // Сортировка чисел
        if (aValue is num && bValue is num) {
          return _sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        }

        // Сортировка дат
        if (aValue is DateTime && bValue is DateTime) {
          return _sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        }

        // Сортировка строк с учетом регистра
        final aString = aValue.toString().toLowerCase();
        final bString = bValue.toString().toLowerCase();
        return _sortAscending
            ? aString.compareTo(bString)
            : bString.compareTo(aString);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Данные таблицы: ${widget.tableName}'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (selectedRows.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedItems,
            ),
          // Кнопки добавления
          if (widget.tableName == "Накладная")
            if (_canCreate)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionsScreen(
                            currentUserRole: widget.userRole,
                            currentUserId: widget.UserId,
                          ),
                        ),
                      );
                      fetchTableData();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.file_download),
                    onPressed: _exportTransactionsToExcel,
                    tooltip: 'Экспорт в Excel',
                  ),
                ],
              ),
          if (widget.tableName == "Товары")
            if (_canCreate)
              Row(
                children: [
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
                  IconButton(
                    icon: Icon(Icons.file_download),
                    onPressed: _exportToExcel,
                    tooltip: 'Экспорт в Excel',
                  ),
                ],
              ),
          if (widget.tableName == "Категории")
            if (_canCreate)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCategoriesScreen(
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
                      builder: (context) => AddSupplierScreen(
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
                      builder: (context) =>
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
                      builder: (context) =>
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
          // Поисковая строка
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon:
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Theme.of(context).primaryColor),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            filteredData = tableData;
                          });
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filteredData = tableData.where((row) {
                    return row.values.any((value) => value
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()));
                  }).toList();
                });
              },
            ),
          ),
          // Таблица данных
          Expanded(
            child: filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Нет данных в таблице',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _verticalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовки
                          Container(
                            color: Colors.grey[100],
                            child: Row(
                              children: [
                                // Чекбокс и кнопка редактирования
                                Container(
                                  width: 100,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    'Действия',
                                    style: TextStyle(
                                      color: Color(
                                          0xFF2196F3), // Устанавливаем нужный цвет
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...filteredData[0].keys.map((key) {
                                  final displayKey = translations[key] ?? key;
                                  return InkWell(
                                    onTap: () => _sort(key),
                                    child: Container(
                                      width: 200,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayKey,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_sortColumn == key)
                                            Icon(
                                              _sortAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          // Данные
                          ...filteredData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final row = entry.value;
                            return Material(
                              color: selectedRows.contains(index)
                                  ? Colors.blue[50]
                                  : Colors.white,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (selectedRows.contains(index)) {
                                      selectedRows.remove(index);
                                    } else {
                                      selectedRows.add(index);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Чекбокс и кнопка редактирования
                                      Container(
                                        width: 100,
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value:
                                                  selectedRows.contains(index),
                                              onChanged: (selected) {
                                                setState(() {
                                                  if (selected ?? false) {
                                                    selectedRows.add(index);
                                                  } else {
                                                    selectedRows.remove(index);
                                                  }
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit, size: 20),
                                              onPressed: () =>
                                                  _showEditDialog(context, row),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...row.values.map((dynamic value) {
                                        return Container(
                                          width: 200,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Text(
                                            value?.toString() ?? '',
                                            style: TextStyle(
                                                color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        child: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'details') {
                                              _showDocumentDetailsDialog(
                                                  context, row);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'details',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline,
                                                      size: 18,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                  SizedBox(width: 8),
                                                  Text('Подробнее'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    final db = await dbHelper.database;
    final primaryKey = getPrimaryKey(widget.tableName);

    final selectedData = selectedRows
        .map((index) => filteredData[index])
        .where((row) => row[primaryKey] != null)
        .toList();

    if (selectedData.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Выберите записи для удаления.')),
      );
      return;
    }

    final selectedIds = selectedData.map((row) => row[primaryKey]).toList();
    final englishTableName = _getEnglishTableName(widget.tableName);

    // Логируем удаление пользователей
    if (widget.tableName == 'Пользователи') {
      for (var row in selectedData) {
        await dbHelper.logUserDeletion(
          row[primaryKey],
          '${row['name']} ${row['surname']}',
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

    setState(() {
      selectedRows.clear();
    });
    fetchTableData(); // Обновляем данные после удаления
  }

  Future<void> _showEditDialog(
      BuildContext context, Map<String, dynamic> row) async {
    final formKey = GlobalKey<FormState>();
    final editedData = Map<String, dynamic>.from(row);

    List<Map<String, dynamic>> categories = [];
    List<Map<String, dynamic>> suppliers = [];
    int? selectedCategoryId;
    int? selectedSupplierId;

    List<Map<String, dynamic>> roles = [];
    int? selectedRoleId;

    // Загружаем список ролей, если редактируем пользователя
    if (widget.tableName == 'Пользователи') {
      final db = await dbHelper.database;
      roles = await db.query('Roles');
      selectedRoleId = row['role_id'] as int?;
    }

    if (widget.tableName == 'Товары') {
      final db = await dbHelper.database;
      categories = await db.query('Categories');
      suppliers = await db.query('Suppliers');
      // Используем оригинальные ID для начальных значений
      selectedCategoryId = row['category_id_original'] as int?;
      selectedSupplierId = row['supplier_id_original'] as int?;
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Редактировать запись'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: row.entries.map((entry) {
                final displayKey = translations[entry.key] ?? entry.key;

                // Пропускаем служебные поля
                if (entry.key.endsWith('_original') ||
                    entry.key == 'created_at' ||
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
                      items: roles.map((role) {
                        return DropdownMenuItem<int>(
                          value: role['role_id'] as int?,
                          child: Text(
                            (role['role_name'] as String?) ??
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

                // Специальная обработка для категории товара
                if (widget.tableName == 'Товары' &&
                    entry.key == 'category_id') {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['category_id'] as int?,
                          child: Text((category['name'] as String?) ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                          editedData['category_id'] = value;
                        });
                      },
                    ),
                  );
                }

                // Специальная обработка для поставщика товара
                if (widget.tableName == 'Товары' &&
                    entry.key == 'supplier_id') {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: DropdownButtonFormField<int>(
                      value: selectedSupplierId,
                      decoration: InputDecoration(
                        labelText: 'Поставщик',
                        border: OutlineInputBorder(),
                      ),
                      items: suppliers.map((supplier) {
                        return DropdownMenuItem<int>(
                          value: supplier['supplier_id'] as int?,
                          child: Text((supplier['name'] as String?) ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSupplierId = value;
                          editedData['supplier_id'] = value;
                        });
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Восстанавливаем оригинальные ID перед сохранением
                if (widget.tableName == 'Товары') {
                  editedData['category_id'] = selectedCategoryId;
                  editedData['supplier_id'] = selectedSupplierId;
                }
                await _updateItem(editedData);
                Navigator.pop(dialogContext);
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
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

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('Запись успешно обновлена')),
    );

    fetchTableData();
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
        return '${row['name']?.toString() ?? 'Пользователь'} ${row['surname']?.toString() ?? ''} (ID: ${row['user_id']})';
      case 'Товары':
        final categoryName =
            row['category_name'] ?? 'Категория ${row['category_id']}';
        final supplierName =
            row['supplier_name'] ?? 'Поставщик ${row['supplier_id']}';
        final quantity = row['quantity']?.toString() ?? '0';
        final price = row['price']?.toString() ?? '0';
        return '${row['name']?.toString() ?? 'Товар'} | Кол-во: $quantity | Цена: $price₽ | $categoryName | $supplierName';
      case 'Клиенты':
        return '${row['name']?.toString() ?? 'Клиент'} | ${row['email'] ?? 'Email не указан'} | ${row['phone'] ?? 'Телефон не указан'}';
      case 'Роли':
        return '${row['role_name']?.toString() ?? 'Роль'} (ID: ${row['role_id']})';
      case 'Поставщики':
        return '${row['name']?.toString() ?? 'Поставщик'} | ${row['contact_name'] ?? 'Контакт не указан'} | ${row['phone'] ?? 'Телефон не указан'}';
      case 'Категории':
        return '${row['name']?.toString() ?? 'Категория'} | ${row['description'] ?? 'Описание отсутствует'}';
      case 'Накладная':
        final date = row['transaction_date']?.toString() ?? 'Дата не указана';
        final type = row['transaction_type']?.toString() ?? 'Тип не указан';
        final quantity = row['quantity']?.toString() ?? '0';
        return 'Накладная №${row['transaction_id']} | $type | Кол-во: $quantity | Дата: $date';
      default:
        return 'Запись ${row['id'] ?? 'N/A'}';
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
      case 'Клиенты':
        return 'customer_id';
      case 'Накладная':
        return 'transaction_id';
      default:
        throw Exception('Неизвестная таблица: $tableName');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = excel_lib.Excel.createExcel();

      // Удаляем стандартный лист Sheet1
      excel.delete('Sheet1');

      // Создаем лист Товары
      final sheet = excel['Товары'];

      // Добавляем заголовки
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel_lib.TextCellValue('Наименование');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = excel_lib.TextCellValue('Количество');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = excel_lib.TextCellValue('Цена за единицу');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
          .value = excel_lib.TextCellValue('Общая сумма');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
          .value = excel_lib.TextCellValue('Поставщик');

      // Получаем данные из базы
      final db = await DatabaseHelper.instance.database;
      final products = await db.rawQuery('''
        SELECT p.name, p.quantity, p.price, s.name as supplier_name
        FROM Products p
        LEFT JOIN Suppliers s ON p.supplier_id = s.supplier_id
      ''');

      // Заполняем данные
      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        final quantity = product['quantity'] as int;
        final price = (product['price'] is int)
            ? (product['price'] as int).toDouble()
            : product['price'] as double;
        final totalAmount = quantity * price;

        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(product['name']?.toString() ?? '');
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: i + 1))
            .value = excel_lib.IntCellValue(quantity);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: i + 1))
            .value = excel_lib.DoubleCellValue(price);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: i + 1))
            .value = excel_lib.DoubleCellValue(totalAmount);
        sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: 4, rowIndex: i + 1))
                .value =
            excel_lib.TextCellValue(
                product['supplier_name']?.toString() ?? 'Нет поставщика');
      }

      // Запрашиваем у пользователя директорию для сохранения
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите папку для сохранения Excel файла',
      );

      if (selectedDirectory == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Экспорт отменен')),
        );
        return;
      }

      // Формируем имя файла с текущей датой и временем
      final now = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      final filePath =
          '$selectedDirectory${Platform.pathSeparator}товары_$now.xlsx';

      // Сохраняем файл
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Файл Excel сохранен'),
              Text(
                filePath,
                style: TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Ошибка при создании Excel файла: $e')),
      );
    }
  }

  Future<void> _exportTransactionsToExcel() async {
    // Показываем диалог выбора типа накладной
    final String? transactionType = await showDialog<String>(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите тип накладной'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.arrow_downward, color: Colors.green),
                title: Text('Приходные накладные'),
                onTap: () => Navigator.pop(context, 'Приход'),
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Colors.red),
                title: Text('Расходные накладные'),
                onTap: () => Navigator.pop(context, 'Расход'),
              ),
            ],
          ),
        );
      },
    );

    if (transactionType == null) return; // Пользователь отменил выбор

    try {
      final excel = excel_lib.Excel.createExcel();

      // Удаляем стандартный лист Sheet1
      excel.delete('Sheet1');

      // Создаем лист с соответствующим названием
      final sheetName = transactionType == 'Приход'
          ? 'Приходные накладные'
          : 'Расходные накладные';
      final sheet = excel[sheetName];

      // Добавляем заголовки
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel_lib.TextCellValue('ID Накладной');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = excel_lib.TextCellValue('Дата');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = excel_lib.TextCellValue('Товар');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
          .value = excel_lib.TextCellValue('Количество');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
          .value = excel_lib.TextCellValue('Цена за единицу');
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0))
          .value = excel_lib.TextCellValue('Общая сумма');

      // Получаем данные из базы с фильтрацией по типу
      final db = await DatabaseHelper.instance.database;
      final transactions = await db.rawQuery('''
        SELECT t.transaction_id, t.transaction_date,
               p.name as product_name, t.quantity, p.price
        FROM Transactions t
        LEFT JOIN Products p ON t.product_id = p.product_id
        WHERE t.transaction_type = ?
        ORDER BY t.transaction_date DESC
      ''', [transactionType]);

      // Заполняем данные
      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final quantity = transaction['quantity'] as int;
        final price = (transaction['price'] is int)
            ? (transaction['price'] as int).toDouble()
            : transaction['price'] as double;
        final totalAmount = quantity * price;

        sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: 0, rowIndex: i + 1))
                .value =
            excel_lib.TextCellValue(
                transaction['transaction_id']?.toString() ?? '');
        sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: 1, rowIndex: i + 1))
                .value =
            excel_lib.TextCellValue(
                transaction['transaction_date']?.toString() ?? '');
        sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: 2, rowIndex: i + 1))
                .value =
            excel_lib.TextCellValue(
                transaction['product_name']?.toString() ?? '');
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: i + 1))
            .value = excel_lib.IntCellValue(quantity);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 4, rowIndex: i + 1))
            .value = excel_lib.DoubleCellValue(price);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 5, rowIndex: i + 1))
            .value = excel_lib.DoubleCellValue(totalAmount);
      }

      // Добавляем итоговую строку
      final lastRow = transactions.length + 1;
      sheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: lastRow))
          .value = excel_lib.TextCellValue('ИТОГО:');

      // Формула для подсчета общей суммы
      sheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 5, rowIndex: lastRow))
          .value = excel_lib.DoubleCellValue(transactions.fold<double>(
        0,
        (sum, transaction) {
          final quantity = transaction['quantity'] as int;
          final price = (transaction['price'] is int)
              ? (transaction['price'] as int).toDouble()
              : transaction['price'] as double;
          return sum + (quantity * price);
        },
      ));

      // Запрашиваем у пользователя директорию для сохранения
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите папку для сохранения Excel файла',
      );

      if (selectedDirectory == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Экспорт отменен')),
        );
        return;
      }

      // Формируем имя файла с текущей датой и временем
      final now = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      final fileName = transactionType == 'Приход' ? 'приходные' : 'расходные';
      final filePath =
          '$selectedDirectory${Platform.pathSeparator}${fileName}_накладные_$now.xlsx';

      // Сохраняем файл
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Файл Excel сохранен'),
              Text(
                filePath,
                style: TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Ошибка при создании Excel файла: $e')),
      );
    }
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
      case 'Накладная':
        return 'Transactions';
      case 'Журнал действий':
        return 'Logs';
      default:
        throw Exception('Неизвестная таблица: $russianTableName');
    }
  }

  void _showDocumentDetailsDialog(
      BuildContext context, Map<String, dynamic> row) {
    final String displayTitle = getDisplayTitle(row, widget.tableName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(displayTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: row.entries.map((entry) {
              final displayKey = translations[entry.key] ?? entry.key;
              final value = entry.value?.toString() ?? '—';
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$displayKey:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(value),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Закрыть'),
          )
        ],
      ),
    );
  }
}
