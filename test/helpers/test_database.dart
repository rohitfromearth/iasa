import 'package:iasa/core/constants/app_constants.dart';
import 'package:iasa/core/constants/database_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initTestDatabaseFactory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<Database> createTestDatabase() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: AppConstants.databaseVersion,
      singleInstance: false,
      onConfigure: (db) async {
        await db.execute(DatabaseConstants.enableForeignKeys);
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final statement in DatabaseConstants.schemaV1Statements) {
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
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
      },
    ),
  );
}

Future<Database> createLegacyTestDatabase({required int version}) async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: version,
      singleInstance: false,
      onConfigure: (db) async {
        await db.execute(DatabaseConstants.enableForeignKeys);
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final statement in DatabaseConstants.schemaV1Statements) {
          if (statement.contains(DatabaseConstants.tablePendingSubmissionPhotos) ||
              statement.contains(
                DatabaseConstants.tablePendingSubmissionAttachments,
              ) ||
              statement.contains(DatabaseConstants.idxPendingPhotoSubmissionId) ||
              statement.contains(
                DatabaseConstants.idxPendingAttachmentSubmissionId,
              )) {
            continue;
          }
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE ${DatabaseConstants.tableCases} '
            'ADD COLUMN ${DatabaseConstants.colOnlineStatus} TEXT',
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
      },
    ),
  );
}
