import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/constants/database_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  test('schema v3 migration adds media tables', () async {
    final db = await createLegacyTestDatabase(version: 2);

    for (final statement in DatabaseConstants.schemaV3MigrationStatements) {
      await db.execute(statement);
    }

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final tableNames = tables.map((row) => row['name'] as String).toList();

    expect(tableNames, contains(DatabaseConstants.tablePendingSubmissionPhotos));
    expect(
      tableNames,
      contains(DatabaseConstants.tablePendingSubmissionAttachments),
    );

    await db.close();
  });
}
