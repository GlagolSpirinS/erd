import 'package:flutter/material.dart';
import '../../database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddSupplierScreen extends StatefulWidget {
  final int currentUserRole;

  AddSupplierScreen({required this.currentUserRole});

  @override
  _AddSupplierScreenState createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  late String _name;
  late String _contactName;
  late String _phone;
  late String _email;
  late String _address;

  @override
  void initState() {
    super.initState();
    _initFields();
    _checkPermissions();
  }

  void _initFields() {
    _name = '';
    _contactName = '';
    _phone = '';
    _email = '';
    _address = '';
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Suppliers',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У вас нет прав для создания поставщиков'),
        ),
      );
      Navigator.pop(context);
    }
  }

  bool _isValidEmail(String? email) {
    if (email == null || email.isEmpty) return true; // Email не обязателен
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = await dbHelper.database;

      try {
        await db.insert('Suppliers', {
          'name': _name,
          'contact_name': _contactName,
          'phone': _phone,
          'email': _email,
          'address': _address,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Поставщик успешно добавлен!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить поставщика')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Название поставщика'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название поставщика';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Контактное лицо'),
                onSaved: (value) => _contactName = value ?? '',
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMaskFormatter],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  if (!_phoneMaskFormatter.isFill()) {
                    return 'Введите полный номер телефона';
                  }
                  return null;
                },
                onSaved: (_) {
                  _phone = '+7${_phoneMaskFormatter.getUnmaskedText()}';
                },
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
                    return 'Введите корректный email адрес';
                  }
                  return null;
                },
                onSaved: (value) => _email = value ?? '',
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Адрес'),
                onSaved: (value) => _address = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Добавить поставщика'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
