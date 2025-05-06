import 'dart:io';
import 'package:flutter/material.dart';
import '../../interfaces/list_interface.dart';
import '../add/add_transactions_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;

class TransactionsListScreen extends DocumentListInterface {
  const TransactionsListScreen({
    Key? key,
    required int userRole,
    required int userId,
  }) : super(key: key, userRole: userRole, userId: userId);

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends DocumentListState<TransactionsListScreen> {
  @override
  String get tableName => 'Transactions';

  @override
  String get primaryKey => 'transaction_id';

  @override
  Map<String, String> get columnTranslations => {
        'transaction_id': 'ID накладной',
        'product_name': 'Наименование товара',
        'transaction_type': 'Тип',
        'quantity': 'Количество',
        'transaction_date': 'Дата',
        'user_name': 'Пользователь',
      };

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.userRole,
      tableName,
      'create',
    );
    setState(() {
      canCreate = hasPermission;
    });
  }

  @override
  Future<void> fetchData() async {
    final db = await dbHelper.database;
    final data = await db.rawQuery('''
      SELECT 
        t.transaction_id,
        p.name as product_name,
        t.transaction_type,
        t.quantity,
        t.transaction_date,
        u.name || ' ' || u.surname as user_name
      FROM Transactions t
      LEFT JOIN Products p ON t.product_id = p.product_id
      LEFT JOIN Users u ON t.user_id = u.user_id
      ORDER BY t.transaction_date DESC
    ''');

    setState(() {
      tableData = data;
      filteredData = tableData;
    });
  }

  @override
  Widget buildAddButton() {
    if (!canCreate) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionsScreen(
              currentUserRole: widget.userRole,
              currentUserId: widget.userId,
            ),
          ),
        );
        fetchData();
      },
    );
  }

  @override
  Widget buildExtraActions() {
    if (!canCreate) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.file_download),
      onPressed: _exportToExcel,
      tooltip: 'Экспорт в Excel',
    );
  }

  @override
  Future<void> deleteSelected() async {
    final db = await dbHelper.database;
    final selectedData = selectedRows
        .map((index) => filteredData[index])
        .where((row) => row[primaryKey] != null)
        .toList();

    if (selectedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите записи для удаления.')),
      );
      return;
    }

    final selectedIds = selectedData.map((row) => row[primaryKey]).toList();

    await db.delete(
      tableName,
      where: '$primaryKey IN (${List.filled(selectedIds.length, '?').join(',')})',
      whereArgs: selectedIds,
    );

    // Обновляем количество товаров
    for (var transaction in selectedData) {
      final productData = await db.query(
        'Products',
        columns: ['product_id', 'quantity'],
        where: 'name = ?',
        whereArgs: [transaction['product_name']],
      );

      if (productData.isNotEmpty) {
        final currentQuantity = productData.first['quantity'] as int;
        final transactionQuantity = transaction['quantity'] as int;
        final newQuantity = transaction['transaction_type'] == 'Приход'
            ? currentQuantity - transactionQuantity
            : currentQuantity + transactionQuantity;

        await db.update(
          'Products',
          {'quantity': newQuantity},
          where: 'product_id = ?',
          whereArgs: [productData.first['product_id']],
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Удалено ${selectedIds.length} записей.')),
    );

    setState(() {
      selectedRows.clear();
    });
    fetchData();
  }

  @override
  Future<void> showEditDialog(Map<String, dynamic> row) async {
    // Редактирование накладных не поддерживается
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование накладных не поддерживается')),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = excel_lib.Excel.createExcel();
      excel.delete('Sheet1');

      final sheet = excel['Накладные'];

      // Добавляем заголовки
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel_lib.TextCellValue('ID');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = excel_lib.TextCellValue('Товар');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = excel_lib.TextCellValue('Тип');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
          .value = excel_lib.TextCellValue('Количество');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
          .value = excel_lib.TextCellValue('Дата');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0))
          .value = excel_lib.TextCellValue('Пользователь');

      // Заполняем данные
      for (var i = 0; i < filteredData.length; i++) {
        final transaction = filteredData[i];
        
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(transaction['transaction_id'].toString());
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(transaction['product_name']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(transaction['transaction_type']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
            .value = excel_lib.IntCellValue(transaction['quantity'] as int);
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(transaction['transaction_date']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(transaction['user_name']?.toString() ?? '');
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите папку для сохранения Excel файла',
      );

      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экспорт отменен')),
        );
        return;
      }

      final now = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      final filePath = '$selectedDirectory${Platform.pathSeparator}накладные_$now.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Файл Excel сохранен'),
              Text(
                filePath,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании Excel файла: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список накладных'),
        actions: [
          if (selectedRows.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSelected,
            ),
          buildAddButton(),
          buildExtraActions(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F5F5)), // Синий фон заголовка
                    headingTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // Белый текст
                  columns: [
                    const DataColumn(
                      label: Text('Действия'),
                    ),
                    ...columnTranslations.values.map(
                      (header) => DataColumn(
                        label: Text(header),
                        onSort: (columnIndex, ascending) {
                          final column = columnTranslations.keys
                              .elementAt(columnIndex - 1);
                          setState(() {
                            if (sortColumn == column) {
                              sortAscending = !sortAscending;
                            } else {
                              sortColumn = column;
                              sortAscending = true;
                            }
                            filteredData.sort((a, b) {
                              final aValue = a[column];
                              final bValue = b[column];
                              return sortAscending
                                  ? Comparable.compare(
                                      aValue.toString(), bValue.toString())
                                  : Comparable.compare(
                                      bValue.toString(), aValue.toString());
                            });
                          });
                        },
                      ),
                    ),
                  ],
                  rows: filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return DataRow(
                      selected: selectedRows.contains(index),
                      onSelectChanged: (selected) {
                        setState(() {
                          if (selected ?? false) {
                            selectedRows.add(index);
                          } else {
                            selectedRows.remove(index);
                          }
                        });
                      },
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                color: Colors.blue,
                                onPressed: () => showEditDialog(row),
                              ),
                            ],
                          ),
                        ),
                        ...columnTranslations.keys.map((key) => 
                          DataCell(Text(row[key]?.toString() ?? ''))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 