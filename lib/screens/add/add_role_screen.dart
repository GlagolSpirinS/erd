import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../database_helper.dart';

class AddRoleScreen extends StatefulWidget {
  final int currentUserRole;

  AddRoleScreen({required this.currentUserRole});

  @override
  _AddRoleScreenState createState() => _AddRoleScreenState();
}

class _AddRoleScreenState extends State<AddRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поле для хранения названия роли
  String _roleName = '';

  // Список таблиц и их разрешений
  final List<String> _tables = [
    'Users',
    'Roles',
    'Suppliers',
    'Categories',
    'Products',
    'Transactions',
    'Logs',
  ];

  // Map для хранения разрешений для каждой таблицы
  Map<String, Map<String, bool>> _permissions = {};

  @override
  void initState() {
    super.initState();
    // Инициализация разрешений для каждой таблицы
    for (var table in _tables) {
      _permissions[table] = {
        'view': false,
        'create': false,
        'update': false,
        'delete': false,
      };
    }
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Roles',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания ролей')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить роль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название роли'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название роли';
                  }
                  return null;
                },
                onSaved: (value) {
                  _roleName = value!;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Права доступа к таблицам:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ..._tables
                  .map(
                    (table) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tableNamesRu[table] ?? table,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Выдать доступ к таблице'),
                                value: _permissions[table]!['view'],
                                onChanged: (bool? value) {
                                  setState(() {
                                    _permissions[table]!['view'] = value!;
                                    // Если доступ отключен, сбрасываем все другие разрешения
                                    if (!value) {
                                      _permissions[table]!['create'] = false;
                                      _permissions[table]!['update'] = false;
                                      _permissions[table]!['delete'] = false;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_permissions[table]!['view']!)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RadioListTile<String>(
                                  title: Text('Только чтение'),
                                  value: 'read_only',
                                  groupValue: _getAccessType(table),
                                  onChanged: (value) {
                                    setState(() {
                                      _permissions[table]!['create'] = false;
                                      _permissions[table]!['update'] = false;
                                      _permissions[table]!['delete'] = false;
                                    });
                                  },
                                ),
                                RadioListTile<String>(
                                  title: Text('Полный доступ'),
                                  value: 'full_access',
                                  groupValue: _getAccessType(table),
                                  onChanged: (value) {
                                    setState(() {
                                      _permissions[table]!['create'] = true;
                                      _permissions[table]!['update'] = true;
                                      _permissions[table]!['delete'] = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        // Divider(),
                      ],
                    ),
                  )
                  .toList(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить роль'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = await dbHelper.database;

      try {
        // Начинаем транзакцию
        await db.transaction((txn) async {
          // Вставляем данные в таблицу Roles
          final roleId = await txn.insert('Roles', {
            'role_name': _roleName,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Вставляем разрешения для каждой таблицы
          for (var table in _tables) {
            if (_permissions[table]!['view']! ||
                _permissions[table]!['create']! ||
                _permissions[table]!['update']! ||
                _permissions[table]!['delete']!) {
              await txn.insert('RolePermissions', {
                'role_id': roleId,
                'table_name': table,
                'can_view': _permissions[table]!['view']! ? 1 : 0,
                'can_create': _permissions[table]!['create']! ? 1 : 0,
                'can_update': _permissions[table]!['update']! ? 1 : 0,
                'can_delete': _permissions[table]!['delete']! ? 1 : 0,
              });
            }
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Роль успешно добавлена!')));

        // Возвращаемся к списку заказов
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    }
  }

  // Добавляем новый метод для определения типа доступа
  String _getAccessType(String table) {
    if (_permissions[table]!['create']! ||
        _permissions[table]!['update']! ||
        _permissions[table]!['delete']!) {
      return 'full_access';
    }
    return 'read_only';
  }
}

  final Map<String, String> _tableNamesRu = {
    'Users': 'Пользователи',
    'Roles': 'Роли',
    'Suppliers': 'Поставщики',
    'Categories': 'Категории',
    'Products': 'Продукты',
    'Transactions': 'Транзакции',
    'Logs': 'Логи',
  };