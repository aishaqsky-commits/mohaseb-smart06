import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class ContactRepository {
  final AppDatabase _dbHelper;
  final Uuid _uuid = const Uuid();

  // In-memory fallback / cache for Web & fast offline access
  static final List<Map<String, dynamic>> _inMemoryContacts = [
    {
      'id': 'c1',
      'name': 'أحمد سالم (عميل)',
      'type': 'عميل',
      'phone': '771234567',
      'balance': 25000.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'c2',
      'name': 'شركة النور للمواد الغذائية (مورد)',
      'type': 'مورد',
      'phone': '733987654',
      'balance': -45000.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'c3',
      'name': 'محسن علي (موظف)',
      'type': 'موظف',
      'phone': '711554433',
      'balance': 0.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'c4',
      'name': 'مؤسسة البركة التجارية (عميل)',
      'type': 'عميل',
      'phone': '770011223',
      'balance': 12000.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'c5',
      'name': 'محلات الصداقة للبلاستيك (مورد)',
      'type': 'مورد',
      'phone': '775566778',
      'balance': -18000.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  ContactRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<String> addContact({
    required String name,
    required String type,
    String? phone,
    double initialBalance = 0.0,
  }) async {
    final contactId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final newContact = {
      'id': contactId,
      'name': name,
      'type': type,
      'phone': phone ?? '',
      'balance': initialBalance,
      'sync_status': 0,
      'updated_at': now,
    };

    _inMemoryContacts.insert(0, newContact);

    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        await db.insert(
          'contacts',
          newContact,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {
        // Fallback to memory
      }
    }

    return contactId;
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        final data = await db.query('contacts', orderBy: 'updated_at DESC');
        if (data.isNotEmpty) return data;
      } catch (_) {
        // Fallback to memory
      }
    }
    return List.from(_inMemoryContacts);
  }

  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    if (query.trim().isEmpty) return getAllContacts();
    
    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        final data = await db.query(
          'contacts',
          where: 'name LIKE ?',
          whereArgs: ['%$query%'],
          orderBy: 'updated_at DESC',
        );
        if (data.isNotEmpty) return data;
      } catch (_) {
        // Fallback to memory
      }
    }

    return _inMemoryContacts
        .where((c) => (c['name'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
