import 'package:flutter/material.dart';
import '../../interfaces/list_interface.dart';
import '../add/add_user_screen.dart';

class UsersListScreen extends DocumentListInterface {
  const UsersListScreen({
    Key? key,
    required int userRole,
    required int userId,
  }) : super(key: key, userRole: userRole, userId: userId);

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends DocumentListState<UsersListScreen> {
  @override
  String get tableName => 'Users';

  @override
  String get primaryKey => 'user_id';

  @override
  Map<String, String> get columnTranslations => {
        'user_id': 'ID пользователя',
        'name': 'Имя',
        'surname': 'Фамилия',
        'password': 'Пароль',
        'created_at': 'Дата создания',
        'role_id': 'Роль',
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
        u.user_id,
        u.name,
        u.surname,
        u.password,
        u.created_at,
        u.role_id,
        r.role_name
      FROM Users u
      LEFT JOIN Roles r ON u.role_id = r.role_id
    ''');

    setState(() {
      tableData = data.map((row) {
        final newRow = Map<String, dynamic>.from(row);
        newRow['role_name'] = row['role_name'] ?? 'Роль не указана';
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
            builder: (context) =>
                AddUserScreen(currentUserRole: widget.userRole),
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

    // Логируем удаление пользователей
    for (var row in selectedData) {
      await dbHelper.logUserDeletion(
        row[primaryKey],
        '${row['name']} ${row['surname']}',
      );
    }

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
    List<Map<String, dynamic>> roles = [];
    int? selectedRoleId;

    final db = await dbHelper.database;
    roles = await db.query('Roles');
    selectedRoleId = row['role_id'] is String
        ? int.tryParse(row['role_id'])
        : row['role_id'] as int?;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Редактировать пользователя'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: row['name']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['name'] = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: row['surname']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => editedData['surname'] = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Обязательное поле' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Роль',
                    border: OutlineInputBorder(),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem<int>(
                      value: role['role_id'] as int?,
                      child: Text(role['role_name'] as String? ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRoleId = value;
                      editedData['role_id'] = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Выберите роль' : null,
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
    updateData.remove('role_name');

    // Логируем обновление пользователя
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

  @override
  Widget buildExtraActions() {
    if (!canCreate) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список пользователей'),
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
                        ...columnTranslations.keys.map(
                          (key) => DataCell(
                            Text(row[key]?.toString() ?? ''),
                          ),
                        ),
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