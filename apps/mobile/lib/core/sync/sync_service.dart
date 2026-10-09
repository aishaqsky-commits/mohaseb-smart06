import '../database/app_database.dart';
import 'dart:async';

class SyncService {
  final AppDatabase _dbHelper;

  SyncService({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<void> syncPendingData() async {
    final db = await _dbHelper.database;

    // 1. Fetch pending journals (sync_status = 0)
    final pendingJournals = await db.query(
      'journals',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    if (pendingJournals.isEmpty) return;

    // 2. Map journals with their ledger entries
    List<Map<String, dynamic>> payload = [];
    for (var j in pendingJournals) {
      final ledgerEntries = await db.query(
        'ledger',
        where: 'journal_id = ?',
        whereArgs: [j['id']],
      );

      payload.add({
        'journal': j,
        'ledger': ledgerEntries,
      });
    }

    try {
      // 3. Mock API Call
      await Future.delayed(const Duration(seconds: 2));
      bool apiSuccess = true; // Simulating successful sync

      if (apiSuccess) {
        // 4. Update sync_status to 1 (Synced)
        await db.transaction((txn) async {
          for (var p in payload) {
            await txn.update(
              'journals',
              {'sync_status': 1},
              where: 'id = ?',
              whereArgs: [p['journal']['id']],
            );
          }
        });
      }
    } catch (e) {
      // 5. Update sync_status to 2 (Conflict/Error) if specific error
      await db.transaction((txn) async {
        for (var p in payload) {
          await txn.update(
            'journals',
            {'sync_status': 2},
            where: 'id = ?',
            whereArgs: [p['journal']['id']],
          );
        }
      });
    }
  }

  // A method to start background periodic sync (Simplified)
  void startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      // Call sync
      syncPendingData();
    });
  }
}
