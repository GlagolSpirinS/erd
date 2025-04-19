import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddTransactionsScreen extends StatefulWidget {
  final int currentUserRole;

  AddTransactionsScreen({required this.currentUserRole});

  @override
  _AddTransactionsScreenState createState() => _AddTransactionsScreenState();
}

class _AddTransactionsScreenState extends State<AddTransactionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  int? _inventoryId;
  String _transactionType = '';
  int _quantity = 0;

  // Список для выбора инвентаря
  List<Map<String, dynamic>> _inventory = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Transactions',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания транзакций')),
      );
      Navigator.pop(context);
    }
  }

  // Загрузка инвентаря из базы данных
  Future<void> _loadInventory() async {
    final db = await dbHelper.database;
    final inventory = await db.query('Inventory');
    setState(() {
      _inventory = inventory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить транзакцию')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _inventoryId,
                decoration: InputDecoration(labelText: 'Инвентарь'),
                items:
                    _inventory.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['inventory_id'],
                        child: Text('Инвентарь #${item['inventory_id']}'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _inventoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите инвентарь';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Тип транзакции (приход/расход)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите тип транзакции';
                  }
                  return null;
                },
                onSaved: (value) {
                  _transactionType = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Количество'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
                onSaved: (value) {
                  _quantity = int.parse(value!);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить транзакцию'),
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
        // Вставляем данные в таблицу Transactions
        await db.insert('Transactions', {
          'inventory_id': _inventoryId,
          'transaction_type': _transactionType,
          'quantity': _quantity,
          // Поле transaction_date заполнится автоматически
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Транзакция успешно добавлена!')),
        );

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
