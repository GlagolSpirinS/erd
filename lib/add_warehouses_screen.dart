import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddWarehousesScreen extends StatefulWidget {
  final int currentUserRole;

  AddWarehousesScreen({required this.currentUserRole});

  @override
  _AddWarehousesScreenState createState() => _AddWarehousesScreenState();
}

class _AddWarehousesScreenState extends State<AddWarehousesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  String _name = '';
  String _location = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Warehouses',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания складов')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить склад')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название склада'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название склада';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Местоположение'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите местоположение';
                  }
                  return null;
                },
                onSaved: (value) {
                  _location = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить склад'),
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
        // Вставляем данные в таблицу Warehouses
        await db.insert('Warehouses', {'name': _name, 'location': _location});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Склад успешно добавлен!')));

        // Возвращаемся к списку заказов
        Navigator.pop(context);
      } catch (e) {
        // Обработка ошибок
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    }
  }
}
