import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Добавлено для Firebase
import 'package:firebase_core/firebase_core.dart';   // Добавлено для инициализации Firebase

class AddOrderDetailsScreen extends StatefulWidget {
  final int currentUserRole;

  AddOrderDetailsScreen({required this.currentUserRole});

  @override
  _AddOrderDetailsScreenState createState() => _AddOrderDetailsScreenState();
}

class _AddOrderDetailsScreenState extends State<AddOrderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  int? _orderId;
  int? _productId;
  int _quantity = 0;
  double _price = 0.0;

  // Списки для выбора заказа и товара
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadOrdersAndProducts();
    _checkPermissions();
  }

  // Загрузка заказов и товаров из базы данных
  Future<void> _loadOrdersAndProducts() async {
    final db = await dbHelper.database;
    final orders = await db.query('Orders');
    final products = await db.query('Products');
    setState(() {
      _orders = orders;
      _products = products;
    });
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Order_Details',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У вас нет прав для создания деталей заказа'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить детали заказа')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _orderId,
                decoration: InputDecoration(labelText: 'Заказ'),
                items:
                    _orders.map((order) {
                      return DropdownMenuItem<int>(
                        value: order['order_id'],
                        child: Text('Заказ #${order['order_id']}'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _orderId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите заказ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 5),
              DropdownButtonFormField<int>(
                value: _productId,
                decoration: InputDecoration(labelText: 'Товар'),
                items:
                    _products.map((product) {
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
              SizedBox(height: 5),
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
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Цена'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
                onSaved: (value) {
                  _price = double.parse(value!);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить детали заказа'),
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
        // Локальное сохранение в SQLite
        await db.insert('Order_Details', {
          'order_id': _orderId,
          'product_id': _productId,
          'quantity': _quantity,
          'price': _price,
        });

        // Отправка данных в Firebase Firestore
        await FirebaseFirestore.instance.collection('order_details').add({
          'order_id': _orderId,
          'product_id': _productId,
          'quantity': _quantity,
          'price': _price,
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Детали заказа успешно добавлены!')),
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