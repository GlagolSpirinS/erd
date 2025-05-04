import 'package:flutter/material.dart';
import 'database_helper.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({Key? key}) : super(key: key);

  @override
  _AdminLogsScreenState createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedAction = 'Все';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _actionTypes = [
    'Все',
    'Создание пользователя',
    'Обновление пользователя',
    'Удаление пользователя',
    'Вход в систему',
    'Выход из системы',
    'Создание роли',
    'Обновление роли',
    'Удаление роли',
    'Создание поставщика',
    'Обновление поставщика',
    'Удаление поставщика',
    'Создание категории',
    'Обновление категории',
    'Удаление категории',
    'Создание товара',
    'Обновление товара',
    'Удаление товара',
    'Создание склада',
    'Обновление склада',
    'Удаление склада',
    'Создание инвентаря',
    'Обновление инвентаря',
    'Удаление инвентаря',
    'Создание клиента',
    'Обновление клиента',
    'Удаление клиента',
    'Создание заказа',
    'Обновление заказа',
    'Удаление заказа',
    'Создание детали заказа',
    'Обновление детали заказа',
    'Удаление детали заказа',
    'Создание Накладная',
    'Обновление Накладная',
    'Удаление Накладная',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_selectedAction == 'Все') {
        final logs = await _dbHelper.getLogs();
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      } else {
        final logs = await _dbHelper.getLogsByAction(_selectedAction);
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке логов: $e')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadLogsByDateRange();
    }
  }

  Future<void> _loadLogsByDateRange() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final logs = await _dbHelper.getLogsByDateRange(_startDate!, _endDate!);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке логов: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал действий'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedAction,
                    items: _actionTypes.map((String action) {
                      return DropdownMenuItem<String>(
                        value: action,
                        child: Text(action),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAction = newValue;
                        });
                        _loadLogs();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate != null && _endDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Выбрать период'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('Нет записей в журнале'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              title: Text(log['action']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Пользователь: ${log['username']}'),
                                  if (log['details'] != null)
                                    Text('Детали: ${log['details']}'),
                                  Text(
                                    'Время: ${DateTime.parse(log['timestamp']).toLocal().toString().split('.')[0]}',
                                  ),
                                ],
                              ),
                              leading: Icon(_getActionIcon(log['action'])),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'Создание пользователя':
        return Icons.person_add;
      case 'Обновление пользователя':
        return Icons.edit;
      case 'Удаление пользователя':
        return Icons.person_remove;
      case 'Вход в систему':
        return Icons.login;
      case 'Выход из системы':
        return Icons.logout;
      case 'Создание роли':
      case 'Создание поставщика':
      case 'Создание категории':
      case 'Создание товара':
      case 'Создание склада':
      case 'Создание инвентаря':
      case 'Создание клиента':
      case 'Создание заказа':
      case 'Создание детали заказа':
      case 'Создание Накладная':
        return Icons.add_circle;
      case 'Обновление роли':
      case 'Обновление поставщика':
      case 'Обновление категории':
      case 'Обновление товара':
      case 'Обновление склада':
      case 'Обновление инвентаря':
      case 'Обновление клиента':
      case 'Обновление заказа':
      case 'Обновление детали заказа':
      case 'Обновление Накладная':
        return Icons.edit;
      case 'Удаление роли':
      case 'Удаление поставщика':
      case 'Удаление категории':
      case 'Удаление товара':
      case 'Удаление склада':
      case 'Удаление инвентаря':
      case 'Удаление клиента':
      case 'Удаление заказа':
      case 'Удаление детали заказа':
      case 'Удаление Накладная':
        return Icons.delete;
      default:
        return Icons.history;
    }
  }
} 