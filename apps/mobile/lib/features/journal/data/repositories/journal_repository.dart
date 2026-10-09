import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class JournalRepository {
  final AppDatabase _dbHelper;
  final Uuid _uuid = const Uuid();

  static final List<Map<String, dynamic>> _inMemoryJournals = [];

  JournalRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<String> saveJournalEntry({
    required String templateId,
    required double totalAmount,
    required List<Map<String, dynamic>> ledgerEntries,
    String? description,
  }) async {
    final journalId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final journalRecord = {
      'id': journalId,
      'template_id': templateId,
      'description': description ?? '',
      'date': now,
      'total_amount': totalAmount,
      'sync_status': 0, // Pending sync
      'created_at': now,
      'ledger': ledgerEntries,
    };

    _inMemoryJournals.insert(0, journalRecord);

    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          // 1. Insert Journal
          await txn.insert(
            'journals',
            {
              'id': journalId,
              'template_id': templateId,
              'description': description ?? '',
              'date': now,
              'total_amount': totalAmount,
              'sync_status': 0,
              'created_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 2. Insert Ledger Entries
          for (var entry in ledgerEntries) {
            await txn.insert(
              'ledger',
              {
                'id': _uuid.v4(),
                'journal_id': journalId,
                'account_id': entry['account_id'],
                'is_debit': entry['is_debit'] ? 1 : 0,
                'amount': entry['amount'],
              },
            );
          }
        });
      } catch (_) {
        // Fallback to memory
      }
    }

    return journalId;
  }

  Future<List<Map<String, dynamic>>> getPendingJournals() async {
    if (!kIsWeb) {
      try {
        final db = await _dbHelper.database;
        final data = await db.query(
          'journals',
          where: 'sync_status = ?',
          whereArgs: [0],
        );
        if (data.isNotEmpty) return data;
      } catch (_) {
        // Fallback to memory
      }
    }
    return List.from(_inMemoryJournals);
  }
}
