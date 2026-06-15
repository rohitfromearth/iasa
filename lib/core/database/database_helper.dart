import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/database_constants.dart';

/// Singleton SQLite database accessor.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute(DatabaseConstants.enableForeignKeys);
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in DatabaseConstants.schemaV1Statements) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableCases} '
        'ADD COLUMN ${DatabaseConstants.colOnlineStatus} TEXT',
      );
      await db.execute(
        'UPDATE ${DatabaseConstants.tableCases} '
        'SET ${DatabaseConstants.colOnlineStatus} = ${DatabaseConstants.colStatus}',
      );
    }
    if (oldVersion < 3) {
      final batch = db.batch();
      for (final statement in DatabaseConstants.schemaV3MigrationStatements) {
        batch.execute(statement);
      }
      await batch.commit(noResult: true);
    }
    if (oldVersion < 4) {
      for (final statement in DatabaseConstants.schemaV4MigrationStatements) {
        await db.execute(statement);
      }
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
