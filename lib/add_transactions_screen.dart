import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Добавлено для Firebase
import 'package:firebase_core/firebase_core.dart';   // Добавлено для инициализации Firebase

class AddTransactionsScreen extends StatefulWidget {
  final int currentUserRole;
  final int currentUserId;

  AddTransactionsScreen({required this.currentUserRole, required this.currentUserId});

  @override
  _AddTransactionsScreenState createState() => _AddTransactionsScreenState();
}

class _AddTransactionsScreenState extends State<AddTransactionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Список для хранения выбранных товаров
  List<Map<String, dynamic>> _selectedProducts = [];

  // Список для выбора продуктов
  List<Map<String, dynamic>> _products = [];

  // Тип транзакции (по умолчанию "Приход")
  String _transactionType = 'Приход';

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

  // Добавление товара в список выбранных
  void _addProductToSelected(int productId) {
    final product = _products.firstWhere((p) => p['product_id'] == productId);

    // Проверяем, нет ли уже такого товара в списке
    if (_selectedProducts.any((p) => p['product_id'] == productId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Товар уже добавлен')),
      );
      return;
    }

    setState(() {
      _selectedProducts.add({
        'product_id': product['product_id'],
        'name': product['name'],
        'quantity': 0, // Начальное количество
      });
    });
  }

  // Удаление товара из списка выбранных
  void _removeProductFromSelected(int productId) {
    setState(() {
      _selectedProducts.removeWhere((p) => p['product_id'] == productId);
    });
  }

  // Обновление количества товара
  void _updateProductQuantity(int productId, String quantityText) {
    final newQuantity = int.tryParse(quantityText) ?? 0;

    setState(() {
      final product = _selectedProducts.firstWhere((p) => p['product_id'] == productId);
      product['quantity'] = newQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить накладную')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: 'Выберите продукт'),
                      items: _products.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['product_id'],
                          child: Text('${item['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _addProductToSelected(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Выберите продукт';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Тип транзакции'),
                      value: _transactionType,
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
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _selectedProducts[index];
                    return ListTile(
                      title: Text(
                        'Товар: ${product['name']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: product['quantity'].toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Количество',
                                  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                ),
                                onChanged: (value) {
                                  _updateProductQuantity(product['product_id'], value);
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _removeProductFromSelected(product['product_id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить накладную'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавьте хотя бы один товар')),
      );
      return;
    }

    final db = await dbHelper.database;

    try {
      for (var product in _selectedProducts) {
        final productId = product['product_id'];
        final quantity = product['quantity'];

        if (quantity <= 0) {
          continue; // Пропускаем товары с нулевым количеством
        }

        // Получаем текущее количество продукта
        final productData = await db.query(
          'Products',
          where: 'product_id = ?',
          whereArgs: [productId],
        );

        if (productData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Продукт с ID $productId не найден')),
          );
          continue;
        }

        int currentQuantity = productData.first['quantity'] as int;
        num newQuantity;

        if (_transactionType == 'Приход') {
          newQuantity = currentQuantity + quantity;
        } else {
          newQuantity = currentQuantity - quantity;
          if (newQuantity < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Недостаточно товара для списания')),
            );
            continue;
          }
        }

        // Обновляем таблицу Products
        await db.update(
          'Products',
          {'quantity': newQuantity},
          where: 'product_id = ?',
          whereArgs: [productId],
        );

        // Вставляем данные в таблицу Transactions
        await db.insert('Transactions', {
          'product_id': productId,
          'transaction_type': _transactionType,
          'quantity': quantity,
          'user_id': widget.currentUserId,
        });

        // Отправка данных в Firebase Firestore
        await FirebaseFirestore.instance.collection('transactions').add({
          'product_id': productId,
          'transaction_type': _transactionType,
          'quantity': quantity,
          'user_id': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Обновляем или создаём запись о продукте в Firebase (опционально)
        await FirebaseFirestore.instance.collection('products').doc(productId.toString()).set({
          'quantity': newQuantity,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Транзакции успешно добавлены!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }
}