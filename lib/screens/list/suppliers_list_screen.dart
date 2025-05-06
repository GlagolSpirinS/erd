import 'dart:io';
import 'package:flutter/material.dart';
import '../../interfaces/list_interface.dart';
import '../add/add_supplier_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;

class SuppliersListScreen extends DocumentListInterface {
  const SuppliersListScreen({
    Key? key,
    required int userRole,
    required int userId,
  }) : super(key: key, userRole: userRole, userId: userId);

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends DocumentListState<SuppliersListScreen> {
  @override
  String get tableName => 'Suppliers';

  @override
  String get primaryKey => 'supplier_id';

  @override
  Map<String, String> get columnTranslations => {
        'supplier_id': 'ID поставщика',
        'name': 'Наименование',
        'contact_name': 'Контактное лицо',
        'phone': 'Телефон',
        'email': 'Email',
        'address': 'Адрес',
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
    final data = await db.query(
      tableName,
      orderBy: primaryKey,
    );

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
            builder: (context) => AddSupplierScreen(
              currentUserRole: widget.userRole,
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

    // Проверяем, есть ли товары, связанные с выбранными поставщиками
    for (var supplier in selectedData) {
      final products = await db.query(
        'Products',
        where: 'supplier_id = ?',
        whereArgs: [supplier[primaryKey]],
      );

      if (products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Поставщик "${supplier['name']}" не может быть удален, так как с ним связаны товары.',
            ),
          ),
        );
        return;
      }
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

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Редактировать поставщика'),
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
                  initialValue: row['contact_name']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Контактное лицо',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['contact_name'] = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['phone']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['phone'] = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['email']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['email'] = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['address']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Адрес',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => editedData['address'] = value,
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
                await _updateSupplier(editedData);
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSupplier(Map<String, dynamic> supplier) async {
    final db = await dbHelper.database;

    await db.update(
      tableName,
      supplier,
      where: '$primaryKey = ?',
      whereArgs: [supplier[primaryKey]],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Поставщик успешно обновлен')),
    );

    fetchData();
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = excel_lib.Excel.createExcel();
      excel.delete('Sheet1');

      final sheet = excel['Поставщики'];

      // Добавляем заголовки
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel_lib.TextCellValue('ID');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = excel_lib.TextCellValue('Наименование');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = excel_lib.TextCellValue('Контактное лицо');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
          .value = excel_lib.TextCellValue('Телефон');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
          .value = excel_lib.TextCellValue('Email');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0))
          .value = excel_lib.TextCellValue('Адрес');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0))
          .value = excel_lib.TextCellValue('Количество товаров');

      // Получаем данные из базы
      final db = await dbHelper.database;
      final suppliers = await db.rawQuery('''
        SELECT s.*, COUNT(p.product_id) as product_count
        FROM Suppliers s
        LEFT JOIN Products p ON s.supplier_id = p.supplier_id
        GROUP BY s.supplier_id
      ''');

      // Заполняем данные
      for (var i = 0; i < suppliers.length; i++) {
        final supplier = suppliers[i];
        
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['supplier_id'].toString());
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['name']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['contact_name']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['phone']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['email']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(supplier['address']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1))
            .value = excel_lib.IntCellValue(supplier['product_count'] as int);
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
      final filePath = '$selectedDirectory${Platform.pathSeparator}поставщики_$now.xlsx';

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
        title: const Text('Список поставщиков'),
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