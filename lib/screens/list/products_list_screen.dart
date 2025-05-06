import 'dart:io';
import 'package:flutter/material.dart';
import '../../interfaces/list_interface.dart';
import '../add/add_products_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;

class ProductsListScreen extends DocumentListInterface {
  const ProductsListScreen({
    Key? key,
    required int userRole,
    required int userId,
  }) : super(key: key, userRole: userRole, userId: userId);

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends DocumentListState<ProductsListScreen> {
  @override
  String get tableName => 'Products';

  @override
  String get primaryKey => 'product_id';

  @override
  Map<String, String> get columnTranslations => {
        'product_id': 'ID товара',
        'name': 'Наименование',
        'category_name': 'Категория',
        'supplier_name': 'Поставщик',
        'price': 'Цена',
        'quantity': 'Количество',
      };

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> suppliers = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadPermissions();
    _loadRelatedData();
  }

  Future<void> _loadRelatedData() async {
    final db = await dbHelper.database;
    categories = await db.query('Categories');
    suppliers = await db.query('Suppliers');
    setState(() {});
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
        p.product_id,
        p.name,
        p.category_id,
        p.supplier_id,
        c.name as category_name,
        s.name as supplier_name,
        c.category_id as category_id_original,
        s.supplier_id as supplier_id_original,
        p.price,
        p.quantity
      FROM Products p
      LEFT JOIN Categories c ON p.category_id = c.category_id
      LEFT JOIN Suppliers s ON p.supplier_id = s.supplier_id
      ORDER BY p.product_id
    ''');

    setState(() {
      tableData = data.map((row) {
        final newRow = Map<String, dynamic>.from(row);
        // Заменяем ID на названия для отображения
        newRow['category_id'] = row['category_name'] ?? 'Нет категории';
        newRow['supplier_id'] = row['supplier_name'] ?? 'Нет поставщика';
        return newRow;
      }).toList();
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
            builder: (context) => AddProductsScreen(),
          ),
        );
        fetchData();
      },
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
    final formKey = GlobalKey<FormState>();
    final editedData = Map<String, dynamic>.from(row);
    int? selectedCategoryId = row['category_id_original'] as int?;
    int? selectedSupplierId = row['supplier_id_original'] as int?;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Редактировать товар'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: row['name']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Наименование',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['name'] = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['price']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Цена',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      editedData['price'] = double.tryParse(value) ?? 0,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['quantity']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Количество',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      editedData['quantity'] = int.tryParse(value) ?? 0,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['category_id'] as int?,
                      child: Text(category['name'] as String? ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                      editedData['category_id'] = value;
                      editedData['category_id_original'] = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSupplierId,
                  decoration: const InputDecoration(
                    labelText: 'Поставщик',
                    border: OutlineInputBorder(),
                  ),
                  items: suppliers.map((supplier) {
                    return DropdownMenuItem<int>(
                      value: supplier['supplier_id'] as int?,
                      child: Text(supplier['name'] as String? ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSupplierId = value;
                      editedData['supplier_id'] = value;
                      editedData['supplier_id_original'] = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _updateItem(editedData);
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItem(Map<String, dynamic> item) async {
    final db = await dbHelper.database;
    
    // Создаем копию данных для обновления
    final updateData = Map<String, dynamic>.from(item);
    
    // Удаляем поля, которых нет в таблице
    updateData.remove('category_name');
    updateData.remove('supplier_name');
    
    // Используем оригинальные ID для category_id и supplier_id
    if (item['category_id_original'] != null) {
      updateData['category_id'] = item['category_id_original'];
    }
    if (item['supplier_id_original'] != null) {
      updateData['supplier_id'] = item['supplier_id_original'];
    }
    
    // Удаляем оригинальные ID после использования
    updateData.remove('category_id_original');
    updateData.remove('supplier_id_original');

    await db.update(
      tableName,
      updateData,
      where: '$primaryKey = ?',
      whereArgs: [item[primaryKey]],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запись успешно обновлена')),
    );

    fetchData();
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = excel_lib.Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Товары'];

      // Добавляем заголовки
      final headers = [
        'Наименование',
        'Количество',
        'Цена за единицу',
        'Общая сумма',
        'Категория',
        'Поставщик',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: i, rowIndex: 0))
            .value = excel_lib.TextCellValue(headers[i]);
      }

      // Заполняем данные
      for (var i = 0; i < filteredData.length; i++) {
        final product = filteredData[i];
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
            .value = excel_lib.TextCellValue(
                product['category_name']?.toString() ?? 'Нет категории');
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 5, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(
                product['supplier_name']?.toString() ?? 'Нет поставщика');
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите папку для сохранения Excel файла',
      );

      if (selectedDirectory == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экспорт отменен')),
        );
        return;
      }

      final now = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      final filePath =
          '$selectedDirectory${Platform.pathSeparator}товары_$now.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании Excel файла: $e')),
      );
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список товаров'),
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
                                icon: const Icon(Icons.edit),
                                onPressed: () => showEditDialog(row),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(row['product_id']?.toString() ?? '')),
                        DataCell(Text(row['name']?.toString() ?? '')),
                        DataCell(Text(row['category_id']?.toString() ?? 'Нет категории')),
                        DataCell(Text(row['supplier_id']?.toString() ?? 'Нет поставщика')),
                        DataCell(Text(row['price']?.toString() ?? '')),
                        DataCell(Text(row['quantity']?.toString() ?? '')),
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