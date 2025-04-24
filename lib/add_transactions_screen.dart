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
  int? _productId;
  String _transactionType = 'Приход'; // По умолчанию "Приход"
  int _quantity = 0;

  // Список для выбора продуктов
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  // Загрузка продуктов из базы данных
  Future<void> _loadProducts() async {
    final db = await dbHelper.database;
    final products = await db.query('Products');
    setState(() {
      _products = products;
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
                value: _productId,
                decoration: InputDecoration(labelText: 'Продукт'),
                items: _products.map((item) {
                  return DropdownMenuItem<int>(
                    value: item['product_id'],
                    child: Text('${item['name']} (ID: ${item['product_id']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _productId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите продукт';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: InputDecoration(labelText: 'Тип транзакции'),
                items: ['Приход', 'Расход'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _transactionType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите тип транзакции';
                  }
                  return null;
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
        // Получаем текущее количество продукта
        final product = await db.query(
          'Products',
          where: 'product_id = ?',
          whereArgs: [_productId],
        );

        if (product.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Продукт не найден')),
          );
          return;
        }

        int currentQuantity = product.first['quantity'] as int;

        // Обновляем количество продукта в зависимости от типа транзакции
        int newQuantity = _transactionType == 'Приход'
            ? currentQuantity + _quantity
            : currentQuantity - _quantity;

        if (newQuantity < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Недостаточно товара для расхода')),
          );
          return;
        }

        // Обновляем таблицу Products
        await db.update(
          'Products',
          {'quantity': newQuantity},
          where: 'product_id = ?',
          whereArgs: [_productId],
        );

        // Вставляем данные в таблицу Transactions
        await db.insert('Transactions', {
          'product_id': _productId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }
}