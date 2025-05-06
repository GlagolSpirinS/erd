import 'dart:io';
import 'package:flutter/material.dart';
import '../../interfaces/list_interface.dart';
import '../add/add_role_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;

class RolesListScreen extends DocumentListInterface {
  const RolesListScreen({
    Key? key,
    required int userRole,
    required int userId,
  }) : super(key: key, userRole: userRole, userId: userId);

  @override
  State<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends DocumentListState<RolesListScreen> {
  @override
  String get tableName => 'Roles';

  @override
  String get primaryKey => 'role_id';

  @override
  Map<String, String> get columnTranslations => {
        'role_id': 'ID роли',
        'role_name': 'Наименование',
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
            builder: (context) => AddRoleScreen(
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

    // Проверяем, есть ли пользователи с выбранными ролями
    for (var role in selectedData) {
      final users = await db.query(
        'Users',
        where: 'role_id = ?',
        whereArgs: [role[primaryKey]],
      );

      if (users.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Роль "${role['role_name']}" не может быть удалена, так как она назначена пользователям.',
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
        title: const Text('Редактировать роль'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: row['role_name']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Наименование',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['role_name'] = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
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
                await _updateRole(editedData);
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRole(Map<String, dynamic> role) async {
    final db = await dbHelper.database;

    await db.update(
      tableName,
      role,
      where: '$primaryKey = ?',
      whereArgs: [role[primaryKey]],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Роль успешно обновлена')),
    );

    fetchData();
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = excel_lib.Excel.createExcel();
      excel.delete('Sheet1');

      final sheet = excel['Роли'];

      // Добавляем заголовки
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel_lib.TextCellValue('ID');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = excel_lib.TextCellValue('Наименование');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = excel_lib.TextCellValue('Количество пользователей');

      // Получаем данные из базы
      final db = await dbHelper.database;
      final roles = await db.rawQuery('''
        SELECT r.*, COUNT(u.user_id) as user_count
        FROM Roles r
        LEFT JOIN Users u ON r.role_id = u.role_id
        GROUP BY r.role_id
      ''');

      // Заполняем данные
      for (var i = 0; i < roles.length; i++) {
        final role = roles[i];
        
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(role['role_id'].toString());
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = excel_lib.TextCellValue(role['role_name']?.toString() ?? '');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = excel_lib.IntCellValue(role['user_count'] as int);
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
      final filePath = '$selectedDirectory${Platform.pathSeparator}роли_$now.xlsx';

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
        title: const Text('Список ролей'),
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