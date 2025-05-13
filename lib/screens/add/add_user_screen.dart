import 'package:flutter/material.dart';
import '../../database_helper.dart';

class AddUserScreen extends StatefulWidget {
  final int currentUserRole;

  AddUserScreen({required this.currentUserRole});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  String _name = '';
  String _surname = '';
  String _password = '';
  int? _roleId;

  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> roles = await db.query('Roles');
    setState(() {
      _roles = roles;
      if (_roles.isNotEmpty) {
        _roleId = _roles[0]['role_id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить пользователя')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Логин
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Логин',
                  helperText: 'Только буквы, минимум 3 символа',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите логин';
                  }
                  if (value.length < 3) {
                    return 'Логин должен быть не менее 3 символов';
                  }
                  final nameRegex = RegExp(r'^[a-zA-Zа-яА-ЯёЁ]+$');
                  if (!nameRegex.hasMatch(value)) {
                    return 'Логин должен содержать только буквы';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 15),

              // Фамилия
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Фамилия',
                  helperText: 'Только буквы, минимум 3 символа',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  if (value.length < 3) {
                    return 'Фамилия должна быть не менее 3 символов';
                  }
                  final surnameRegex = RegExp(r'^[a-zA-Zа-яА-ЯёЁ]+$');
                  if (!surnameRegex.hasMatch(value)) {
                    return 'Фамилия должна содержать только буквы';
                  }
                  return null;
                },
                onSaved: (value) {
                  _surname = value!;
                },
              ),
              SizedBox(height: 15),

              // Пароль
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  helperText:
                      'Минимум 8 символов, 1 заглавная, 1 строчная, 1 цифра, 1 спецсимвол',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 8) {
                    return 'Пароль должен быть не менее 8 символов';
                  }
                  final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
                  final hasLower = RegExp(r'[a-z]').hasMatch(value);
                  final hasDigit = RegExp(r'[0-9]').hasMatch(value);
                  final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

                  if (!(hasUpper && hasLower && hasDigit && hasSpecial)) {
                    return 'Пароль должен содержать:\n- Заглавную букву\n- Строчную букву\n- Цифру\n- Специальный символ';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 15),

              // Роль
              _roles.isEmpty
                  ? CircularProgressIndicator()
                  : DropdownButtonFormField<int>(
                      value: _roleId,
                      decoration: InputDecoration(labelText: 'Роль'),
                      items: _roles.map((role) {
                        return DropdownMenuItem<int>(
                          value: role['role_id'],
                          child: Text(role['role_name'] ?? 'Неизвестная роль'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _roleId = value;
                        });
                      },
                    ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Добавить пользователя'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final hasPermission = await dbHelper.checkRolePermission(
        widget.currentUserRole,
        'Users',
        'create',
      );

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('У вас нет прав для создания пользователей')),
        );
        return;
      }

      try {
        final db = await dbHelper.database;
        final userId = await db.insert('Users', {
          'name': _name,
          'surname': _surname,
          'password': _password,
          'role_id': _roleId,
        });

        await dbHelper.logUserCreation(userId, '$_name $_surname');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пользователь успешно добавлен')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении пользователя: $e')),
        );
      }
    }
  }
}