import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Добавлено для Firebase
import 'package:firebase_core/firebase_core.dart';   // Добавлено для инициализации Firebase

class AddOrdersScreen extends StatefulWidget {
  final int currentUserRole;

  AddOrdersScreen({required this.currentUserRole});

  @override
  _AddOrdersScreenState createState() => _AddOrdersScreenState();
}

class _AddOrdersScreenState extends State<AddOrdersScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  int? _customerId;
  int? _userId;
  OrderStatus _status = OrderStatus.awaitingConfirmation;
  String _selectedCategory = OrderStatus.categories.first;

  // Списки для выбора клиента и пользователя
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadCustomersAndUsers();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Orders',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания заказов')),
      );
      Navigator.pop(context);
    }
  }

  // Загрузка клиентов и пользователей из базы данных
  Future<void> _loadCustomersAndUsers() async {
    final db = await dbHelper.database;
    final customers = await db.query('Customers');
    final users = await db.query('Users');
    setState(() {
      _customers = customers;
      _users = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить заказ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _customerId,
                decoration: InputDecoration(labelText: 'Клиент'),
                items:
                    _customers.map((customer) {
                      return DropdownMenuItem<int>(
                        value: customer['customer_id'],
                        child: Text(customer['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _customerId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите клиента';
                  }
                  return null;
                },
              ),
              SizedBox(height: 5),
              DropdownButtonFormField<int>(
                value: _userId,
                decoration: InputDecoration(labelText: 'Пользователь'),
                items:
                    _users.map((user) {
                      return DropdownMenuItem<int>(
                        value: user['user_id'],
                        child: Text(user['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _userId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите пользователя';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Категория статуса'),
                items:
                    OrderStatus.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    // Сбрасываем статус на первый в новой категории
                    _status = OrderStatus.getByCategory(value).first;
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<OrderStatus>(
                value: _status,
                decoration: InputDecoration(labelText: 'Статус заказа'),
                items:
                    OrderStatus.getByCategory(_selectedCategory).map((status) {
                      return DropdownMenuItem<OrderStatus>(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить заказ'),
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
        await db.insert('Orders', {
          'customer_id': _customerId,
          'user_id': _userId,
          'status': _status.displayName,
          // Поле order_date заполнится автоматически
        });

        // Отправка данных в Firebase Firestore
        await FirebaseFirestore.instance.collection('orders').add({
          'customer_id': _customerId,
          'user_id': _userId,
          'status': _status.displayName,
          'order_date': FieldValue.serverTimestamp(), // Автоматическое время
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Заказ успешно добавлен!')),
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