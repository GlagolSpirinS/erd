import 'package:flutter/material.dart';
import 'database_helper.dart';

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
  List<String> tables = [
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
    for (var table in tables) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              Expanded(
                child: ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return _buildTablePermissions(table);
                  },
                ),
              ),
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

  Widget _buildTablePermissions(String table) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tableNamesRu[table] ?? table,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: Text('Просмотр'),
              value: _permissions[table]!['view']!,
              onChanged: (bool value) {
                setState(() {
                  _permissions[table]!['view'] = value;
                  if (!value) {
                    // Если отключаем просмотр, отключаем и все остальные разрешения
                    _permissions[table]!['create'] = false;
                    _permissions[table]!['update'] = false;
                    _permissions[table]!['delete'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text('Создание'),
              value: _permissions[table]!['create']!,
              onChanged: _permissions[table]!['view']!
                  ? (bool value) {
                      setState(() {
                        _permissions[table]!['create'] = value;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              title: Text('Редактирование'),
              value: _permissions[table]!['update']!,
              onChanged: _permissions[table]!['view']!
                  ? (bool value) {
                      setState(() {
                        _permissions[table]!['update'] = value;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              title: Text('Удаление'),
              value: _permissions[table]!['delete']!,
              onChanged: _permissions[table]!['view']!
                  ? (bool value) {
                      setState(() {
                        _permissions[table]!['delete'] = value;
                      });
                    }
                  : null,
            ),
          ],
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
          // Вставляем новую роль
          final roleId = await txn.insert('Roles', {
            'role_name': _roleName,
          });

          // Вставляем разрешения для роли
          for (var table in tables) {
            await txn.insert('RolePermissions', {
              'role_id': roleId,
              'table_name': table,
              'can_view': _permissions[table]!['view']! ? 1 : 0,
              'can_create': _permissions[table]!['create']! ? 1 : 0,
              'can_update': _permissions[table]!['update']! ? 1 : 0,
              'can_delete': _permissions[table]!['delete']! ? 1 : 0,
            });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Роль успешно добавлена!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }
}

final Map<String, String> _tableNamesRu = {
  'Users': 'Пользователи',
  'Roles': 'Роли',
  'Suppliers': 'Поставщики',
  'Categories': 'Категории',
  'Products': 'Товары',
  'Transactions': 'Накладная',
  'Logs': 'Журнал действий',
};
