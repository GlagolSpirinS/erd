import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Импорт для Firestore
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Предполагается, что он у вас уже есть

class AddCategoriesScreen extends StatefulWidget {
  final int currentUserRole;

  AddCategoriesScreen({required this.currentUserRole});

  @override
  _AddCategoriesScreenState createState() => _AddCategoriesScreenState();
}

class _AddCategoriesScreenState extends State<AddCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  String _name = '';
  String _description = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Categories',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания категорий')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить категорию')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название категории'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название категории';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Описание'),
                maxLines: 3,
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить категорию'),
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

      final db = FirebaseFirestore.instance; // Получаем экземпляр Firestore

      try {
        // Добавляем новую запись в коллекцию "categories"
        await db.collection("categories").add({
          "name": _name,
          "description": _description,
          "createdAt": FieldValue.serverTimestamp(), // временная метка от сервера
        });

        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Категория успешно добавлена в Firebase!')),
        );

        // Очистка формы (опционально)
        setState(() {
          _name = '';
          _description = '';
        });

        // Возвращаемся обратно
        Navigator.pop(context);
      } catch (e) {
        // Обработка ошибок
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении категории: $e')),
        );
      }
    }
  }
}