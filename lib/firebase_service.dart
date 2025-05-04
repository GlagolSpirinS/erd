import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database_helper.dart';
import 'firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Загрузка данных в Cloud Firestore
  Future<void> uploadToFirestore() async {
    try {
      final db = await _databaseHelper.database;
      final batch = _firestore.batch();
      
      // Получаем все данные из локальной базы
      final categories = await db.query('Categories');
      final products = await db.query('Products');
      final suppliers = await db.query('Suppliers');
      final transactions = await db.query('Transactions');
      final users = await db.query('Users');
      final roles = await db.query('Roles');
      final rolePermissions = await db.query('RolePermissions');
      final logs = await db.query('Logs');

      // Функция для проверки существования документа и его обновления
      Future<void> processDocument(CollectionReference collection, String docId, Map<String, dynamic> data) async {
        final docRef = collection.doc(docId);
        final docSnapshot = await docRef.get();
        
        if (!docSnapshot.exists) {
          // Документ не существует - добавляем его
          batch.set(docRef, data);
        } else {
          // Документ существует - проверяем, есть ли изменения
          final existingData = docSnapshot.data() as Map<String, dynamic>;
          bool hasChanges = false;
          
          data.forEach((key, value) {
            if (existingData[key] != value) {
              hasChanges = true;
            }
          });
          
          if (hasChanges) {
            batch.update(docRef, data);
          }
        }
      }

      // Обрабатываем каждую коллекцию
      for (var category in categories) {
        await processDocument(
          _firestore.collection('categories'),
          category['category_id'].toString(),
          category
        );
      }

      for (var product in products) {
        await processDocument(
          _firestore.collection('products'),
          product['product_id'].toString(),
          product
        );
      }

      for (var supplier in suppliers) {
        await processDocument(
          _firestore.collection('suppliers'),
          supplier['supplier_id'].toString(),
          supplier
        );
      }

      for (var transaction in transactions) {
        await processDocument(
          _firestore.collection('transactions'),
          transaction['transaction_id'].toString(),
          transaction
        );
      }

      for (var user in users) {
        await processDocument(
          _firestore.collection('users'),
          user['user_id'].toString(),
          user
        );
      }

      for (var role in roles) {
        await processDocument(
          _firestore.collection('roles'),
          role['role_id'].toString(),
          role
        );
      }

      for (var permission in rolePermissions) {
        await processDocument(
          _firestore.collection('rolePermissions'),
          permission['permission_id'].toString(),
          permission
        );
      }

      for (var log in logs) {
        await processDocument(
          _firestore.collection('logs'),
          log['log_id'].toString(),
          log
        );
      }

      // Применяем все изменения
      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка при загрузке данных в Firestore: $e');
    }
  }

  // Загрузка данных из Cloud Firestore
  Future<void> downloadFromFirestore() async {
    try {
      final db = await _databaseHelper.database;
      
      // Очищаем все таблицы
      await db.delete('Logs');
      await db.delete('Products');
      await db.delete('Categories');
      await db.delete('Suppliers');
      await db.delete('RolePermissions');
      await db.delete('Users');
      await db.delete('Roles');
      await db.delete('Transactions');

      // Получаем данные из всех коллекций
      final categories = await _firestore.collection('categories').get();
      final products = await _firestore.collection('products').get();
      final suppliers = await _firestore.collection('suppliers').get();
      final transactions = await _firestore.collection('transactions').get();
      final users = await _firestore.collection('users').get();
      final roles = await _firestore.collection('roles').get();
      final rolePermissions = await _firestore.collection('rolePermissions').get();
      final logs = await _firestore.collection('logs').get();

      // Сохраняем данные в локальную базу
      for (var doc in roles.docs) {
        await db.insert('Roles', doc.data());
      }

      for (var doc in users.docs) {
        await db.insert('Users', doc.data());
      }

      for (var doc in rolePermissions.docs) {
        await db.insert('RolePermissions', doc.data());
      }

      for (var doc in categories.docs) {
        await db.insert('Categories', doc.data());
      }

      for (var doc in suppliers.docs) {
        await db.insert('Suppliers', doc.data());
      }

      for (var doc in products.docs) {
        await db.insert('Products', doc.data());
      }

      for (var doc in transactions.docs) {
        await db.insert('Transactions', doc.data());
      }

      for (var doc in logs.docs) {
        await db.insert('Logs', doc.data());
      }
    } catch (e) {
      throw Exception('Ошибка при загрузке данных из Firestore: $e');
    }
  }
} 