import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddInventoryScreen extends StatefulWidget {
  @override
  _AddInventoryScreenState createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  int? _warehouseId;
  int? _productId;
  int _quantity = 0;

  // Списки для выбора склада и товара
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadWarehousesAndProducts();
  }

  // Загрузка складов и товаров из базы данных
  Future<void> _loadWarehousesAndProducts() async {
    final db = await dbHelper.database;
    final warehouses = await db.query('Warehouses');
    final products = await db.query('Products');
    setState(() {
      _warehouses = warehouses;
      _products = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить инвентарь'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _warehouseId,
                decoration: InputDecoration(labelText: 'Склад'),
                items: _warehouses.map((warehouse) {
                  return DropdownMenuItem<int>(
                    value: warehouse['warehouse_id'],
                    child: Text(warehouse['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _warehouseId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите склад';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _productId,
                decoration: InputDecoration(labelText: 'Товар'),
                items: _products.map((product) {
                  return DropdownMenuItem<int>(
                    value: product['product_id'],
                    child: Text(product['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _productId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите товар';
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
                child: Text('Добавить инвентарь'),
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
        // Вставляем данные в таблицу Inventory
        await db.insert(
          'Inventory',
          {
            'warehouse_id': _warehouseId,
            'product_id': _productId,
            'quantity': _quantity,
            // Поле last_updated заполнится автоматически
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Инвентарь успешно добавлен!')),
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