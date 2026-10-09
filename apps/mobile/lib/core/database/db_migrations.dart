import 'package:sqflite/sqflite.dart';

class DbMigrations {
  static Future<void> createSchema(Database db, int version) async {
    // 1. Journals Table (قيود اليومية)
    await db.execute('''
      CREATE TABLE journals (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Ledger Table (الأستاذ العام / أطراف القيد)
    await db.execute('''
      CREATE TABLE ledger (
        id TEXT PRIMARY KEY,
        journal_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        is_debit INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (journal_id) REFERENCES journals (id) ON DELETE CASCADE
      )
    ''');

    // 3. Contacts Table (جهات الاتصال)
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Items Table (الأصناف)
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        stock_quantity INTEGER DEFAULT 0,
        average_cost REAL DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 5. Item Batches Table (الدفعات)
    await db.execute('''
      CREATE TABLE item_batches (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost REAL NOT NULL,
        expiry_date TEXT,
        supplier_id TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> upgradeSchema(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }
}
