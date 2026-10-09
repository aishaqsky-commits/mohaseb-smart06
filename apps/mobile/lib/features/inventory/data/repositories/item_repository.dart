import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class ItemRepository {
  final AppDatabase _dbHelper;
  final Uuid _uuid = const Uuid();

  ItemRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<String> addItem({
    required String name,
    String category = '',
    int initialQuantity = 0,
    double initialCost = 0.0,
  }) async {
    final db = await _dbHelper.database;
    final itemId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'items',
      {
        'id': itemId,
        'name': name,
        'category': category,
        'stock_quantity': initialQuantity,
        'average_cost': initialCost,
        'sync_status': 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return itemId;
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await _dbHelper.database;
    return await db.query('items', orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    final db = await _dbHelper.database;
    return await db.query(
      'items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
  }
}
