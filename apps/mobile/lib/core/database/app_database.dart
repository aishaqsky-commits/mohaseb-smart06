import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_migrations.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mohaseb_smart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: DbMigrations.createSchema,
      onUpgrade: DbMigrations.upgradeSchema,
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
