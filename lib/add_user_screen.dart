import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Добавлено для Firebase
import 'package:firebase_core/firebase_core.dart';   // Добавлено для инициализации Firebase

class AddUserScreen extends StatefulWidget {
  final int currentUserRole;

  AddUserScreen({required this.currentUserRole});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Поля для хранения данных из формы
  String _name = '';
  String _surname = '';
  String _password = '';
  int? _roleId; // Изначально роль не выбрана

  List<Map<String, dynamic>> _roles = []; // Список ролей

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  // Загрузка ролей из базы данных
  Future<void> _loadRoles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> roles = await db.query('Roles');
    setState(() {
      _roles = roles;
      if (_roles.isNotEmpty) {
        _roleId = _roles[0]['role_id']; // Устанавливаем первую роль по умолчанию
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
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Логин',
                  helperText: 'Это имя будет использоваться для входа в систему',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите логин';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  return null;
                },
                onSaved: (value) {
                  _surname = value!;
                },
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 15),
              _roles.isEmpty
                  ? CircularProgressIndicator()
                  : DropdownButtonFormField<int>(
                      value: _roleId,
                      decoration: InputDecoration(labelText: 'Роль'),
                      items: _roles.map((role) {
                        return DropdownMenuItem<int>(
                          value: role['role_id'],
                          child: Text(
                            role['role_name'] ?? 'Неизвестная роль',
                          ),
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

      // Проверяем права доступа
      final hasPermission = await dbHelper.checkRolePermission(
        widget.currentUserRole,
        'Users',
        'create',
      );

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('У вас нет прав для создания пользователей'),
          ),
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

        // Логируем создание пользователя
        await dbHelper.logUserCreation(userId, '$_name $_surname');

        // Отправляем данные в Firebase
        if (_roleId != null) {
          await FirebaseFirestore.instance.collection('users').add({
            'name': _name,
            'surname': _surname,
            'role_id': _roleId,
            'created_at': FieldValue.serverTimestamp(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: Роль пользователя не указана')),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь успешно добавлен')),
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