import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddProductsScreen extends StatefulWidget {
  @override
  _AddProductsScreenState createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  String _name = '';
  int? _categoryId;
  int? _supplierId;
  double _price = 0.0;
  String _unit = '';

  // Списки для выбора категории и поставщика
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndSuppliers();
  }

  // Загрузка категорий и поставщиков из базы данных
  Future<void> _loadCategoriesAndSuppliers() async {
    final db = await dbHelper.database;
    final categories = await db.query('Categories');
    final suppliers = await db.query('Suppliers');
    setState(() {
      _categories = categories;
      _suppliers = suppliers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить товар')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название товара'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название товара';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 5),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: InputDecoration(labelText: 'Категория'),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['category_id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите категорию';
                  }
                  return null;
                },
              ),
              SizedBox(height: 5),
              DropdownButtonFormField<int>(
                value: _supplierId,
                decoration: InputDecoration(labelText: 'Поставщик'),
                items:
                    _suppliers.map((supplier) {
                      return DropdownMenuItem<int>(
                        value: supplier['supplier_id'],
                        child: Text(supplier['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _supplierId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите поставщика';
                  }
                  return null;
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
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Единица измерения'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите единицу измерения';
                  }
                  return null;
                },
                onSaved: (value) {
                  _unit = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить товар'),
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
        // Вставляем данные в таблицу Products
        await db.insert('Products', {
          'name': _name,
          'category_id': _categoryId,
          'supplier_id': _supplierId,
          'price': _price,
          'unit': _unit,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Товар успешно добавлен!')));

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
