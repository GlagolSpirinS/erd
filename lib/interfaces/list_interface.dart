import 'package:flutter/material.dart';
import '../database_helper.dart';

abstract class DocumentListInterface extends StatefulWidget {
  final int userRole;
  final int userId;

  const DocumentListInterface({
    Key? key,
    required this.userRole,
    required this.userId,
  }) : super(key: key);
}

abstract class DocumentListState<T extends DocumentListInterface> extends State<T> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> filteredData = [];
  Set<int> selectedRows = {};
  String searchQuery = '';
  bool canCreate = false;
  String? sortColumn;
  bool sortAscending = true;

  // Методы, которые должны быть реализованы в каждом списке
  String get tableName;
  String get primaryKey;
  Map<String, String> get columnTranslations;
  Widget buildAddButton();
  Future<void> fetchData();
  Future<void> deleteSelected();
  Future<void> showEditDialog(Map<String, dynamic> row);
  Widget buildExtraActions();
} 