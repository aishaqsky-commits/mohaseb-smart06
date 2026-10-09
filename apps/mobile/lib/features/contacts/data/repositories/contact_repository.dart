import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class ContactRepository {
  final AppDatabase _dbHelper;
  final Uuid _uuid = const Uuid();

  ContactRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<String> addContact({
    required String name,
    required String type,
    double initialBalance = 0.0,
  }) async {
    final db = await _dbHelper.database;
    final contactId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'contacts',
      {
        'id': contactId,
        'name': name,
        'type': type,
        'balance': initialBalance,
        'sync_status': 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return contactId;
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final db = await _dbHelper.database;
    return await db.query('contacts', orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    final db = await _dbHelper.database;
    return await db.query(
      'contacts',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
  }
}
