import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class ItemRepository {
  final AppDatabase _dbHelper;
  final Uuid _uuid = const Uuid();

  // In-memory fallback / cache for Web & fast offline access
  static final List<Map<String, dynamic>> _inMemoryItems = [
    {
      'id': 'i1',
      'name': '🥤 بيبسي عائلي 2.25 لتر',
      'category': 'مشروبات غازية',
      'stock_quantity': 45,
      'average_cost': 120.0,
      'selling_price': 150.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'i2',
      'name': '🌾 أرز الشعلان مزة 10 كجم',
      'category': 'مواد تموينية',
      'stock_quantity': 20,
      'average_cost': 1450.0,
      'selling_price': 1650.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'i3',
      'name': '🍳 زيت طهي عافية ذرة 1.5 لتر',
      'category': 'زيوت وسمن',
      'stock_quantity': 35,
      'average_cost': 320.0,
      'selling_price': 380.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'i4',
      'name': '🥛 حليب الممتاز مجفف 900 جرام',
      'category': 'ألبان وأجبان',
      'stock_quantity': 18,
      'average_cost': 480.0,
      'selling_price': 550.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'i5',
      'name': '🍬 سكر الأسرة ناعم 5 كجم',
      'category': 'مواد تموينية',
      'stock_quantity': 14,
      'average_cost': 410.0,
      'selling_price': 470.0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  ItemRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<String> addItem({
    required String name,
    String category = '',
    int initialQuantity = 0,
    double initialCost = 0.0,
  }) async {
    final itemId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final newItem = {
      'id': itemId,
      'name': name,
      'category': category,
      'stock_quantity': initialQuantity,
      'average_cost': initialCost,
      'sync_status': 0,
      'updated_at': now,
    };

    _inMemoryItems.insert(0, newItem);

    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        await db.insert(
          'items',
          newItem,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {
        // Fallback to memory
      }
    }

    return itemId;
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        final data = await db.query('items', orderBy: 'updated_at DESC');
        if (data.isNotEmpty) return data;
      } catch (_) {
        // Fallback to memory
      }
    }
    return List.from(_inMemoryItems);
  }

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    if (query.trim().isEmpty) return getAllItems();

    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        final data = await db.query(
          'items',
          where: 'name LIKE ?',
          whereArgs: ['%$query%'],
          orderBy: 'updated_at DESC',
        );
        if (data.isNotEmpty) return data;
      } catch (_) {
        // Fallback to memory
      }
    }

    return _inMemoryItems
        .where((i) => (i['name'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
