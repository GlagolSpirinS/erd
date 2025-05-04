import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';
import 'firebase_service.dart';
import 'login_screen.dart';

class DatabaseManagementScreen extends StatefulWidget {
  @override
  _DatabaseManagementScreenState createState() => _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление базой данных'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildManagementCard(
              title: 'Облачное хранилище',
              icon: Icons.cloud,
              children: [
                _buildActionButton(
                  icon: Icons.cloud_upload,
                  label: 'Загрузить в Cloud Firestore',
                  onPressed: () => _showCloudUploadDialog(context),
                ),
                SizedBox(height: 8),
                _buildActionButton(
                  icon: Icons.cloud_download,
                  label: 'Загрузить из Cloud Firestore',
                  onPressed: () => _showCloudDownloadDialog(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildManagementCard(
              title: 'Локальное хранилище',
              icon: Icons.storage,
              children: [
                _buildActionButton(
                  icon: Icons.backup,
                  label: 'Создать резервную копию',
                  onPressed: () => _showBackupDialog(context),
                ),
                SizedBox(height: 8),
                _buildActionButton(
                  icon: Icons.restore,
                  label: 'Восстановить из резервной копии',
                  onPressed: () => _showRestoreDialog(context),
                ),
              ],
            ),
            Spacer(),
            _buildActionButton(
              icon: Icons.logout,
              label: 'Выйти из системы',
              color: Colors.red,
              foregroundColor: Colors.white,
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(this.context).primaryColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Color? foregroundColor,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _showBackupDialog(BuildContext context) async {
    final String? selectedPath = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите директорию для сохранения'),
          content: Text(
            'Резервная копия базы данных будет сохранена в выбранную директорию',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String? path = await _selectDirectory();
                if (path != null) {
                  Navigator.pop(context, path);
                }
              },
              child: Text('Выбрать'),
            ),
          ],
        );
      },
    );

    if (selectedPath != null) {
      final String backupPath = join(
        selectedPath,
        'app_database_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      final bool success = await _dbHelper.backupDatabase(backupPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Резервная копия успешно создана'
                : 'Ошибка при создании резервной копии',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<String?> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите директорию для сохранения резервной копии',
      );
      return selectedDirectory;
    } catch (e) {
      print('Error selecting directory: $e');
      return null;
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final String? selectedPath = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Восстановление из резервной копии'),
          content: Text(
            'Выберите файл резервной копии для восстановления. Текущие данные будут заменены.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String? path = await _selectBackupFile(context);
                if (path != null) {
                  Navigator.pop(context, path);
                }
              },
              child: Text('Выбрать'),
            ),
          ],
        );
      },
    );

    if (selectedPath != null) {
      final bool success = await _dbHelper.restoreDatabase(selectedPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'База данных успешно восстановлена'
                : 'Ошибка при восстановлении базы данных',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  Future<String?> _selectBackupFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Выберите файл резервной копии',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!file.path!.toLowerCase().endsWith('.db')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пожалуйста, выберите файл с расширением .db'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
        return file.path;
      }
      return null;
    } catch (e) {
      print('Error selecting backup file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _showCloudUploadDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Загрузка в Cloud Firestore'),
          content: Text(
            'Вы уверены, что хотите загрузить все данные в Cloud Firestore? '
            'Это может занять некоторое время.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Загрузить'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator());
          },
        );

        await _firebaseService.uploadToFirestore();
        Navigator.pop(context); // Закрываем индикатор загрузки

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Данные успешно загружены в Cloud Firestore'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCloudDownloadDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Загрузка из Cloud Firestore'),
          content: Text(
            'Вы уверены, что хотите загрузить все данные из Cloud Firestore? '
            'Это действие заменит все текущие данные в локальной базе данных.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Загрузить'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator());
          },
        );

        await _firebaseService.downloadFromFirestore();
        Navigator.pop(context); // Закрываем индикатор загрузки

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Данные успешно загружены из Cloud Firestore'),
            backgroundColor: Colors.green,
          ),
        );

        // Перезагружаем приложение
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } catch (e) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 