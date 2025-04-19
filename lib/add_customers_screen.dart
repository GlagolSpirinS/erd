import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddCustomersScreen extends StatefulWidget {
  final int currentUserRole;

  AddCustomersScreen({required this.currentUserRole});

  @override
  _AddCustomersScreenState createState() => _AddCustomersScreenState();
}

class _AddCustomersScreenState extends State<AddCustomersScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Поля для хранения данных из формы
  String _name = '';
  String _contactName = '';
  String _phone = '';
  String _email = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await dbHelper.checkRolePermission(
      widget.currentUserRole,
      'Customers',
      'create',
    );

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания клиентов')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить клиента')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название компании'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя клиента';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Контактное лицо'),
                onSaved: (value) {
                  _contactName = value ?? '';
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMaskFormatter],
                onChanged: (value) {
                  _phone = _phoneMaskFormatter.getUnmaskedText();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  if (!_phoneMaskFormatter.isFill()) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (value) {
                  _email = value ?? '';
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Адрес'),
                onSaved: (value) {
                  _address = value ?? '';
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить клиента'),
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
        // Вставляем данные в таблицу Customers
        await db.insert('Customers', {
          'name': _name,
          'contact_name': _contactName,
          'phone': _phone,
          'email': _email,
          'address': _address,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Клиент успешно добавлен!')));

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
