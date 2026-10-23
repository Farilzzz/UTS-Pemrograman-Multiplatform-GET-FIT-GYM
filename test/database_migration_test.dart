import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';

class MigrationRecordingDb implements DatabaseExecutor {
  final List<String> executedStatements = [];
  final Map<String, List<Map<String, Object?>>> tables = {};

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return tables[table] ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('databaseVersion is 3 and columnExerciseId is exercise_id', () {
    expect(DatabaseHelper.databaseVersion, 3);
    expect(DatabaseHelper.columnExerciseId, 'exercise_id');
  });

  test('onUpgrade from version 1 to 2 executes ALTER TABLE ADD COLUMN exercise_id TEXT', () async {
    final mockDb = MigrationRecordingDb();
    await DatabaseHelper.onUpgrade(mockDb, 1, 2);

    expect(
      mockDb.executedStatements.any((sql) =>
          sql.contains('ALTER TABLE local_workout_logs ADD COLUMN exercise_id TEXT')),
      isTrue,
    );
  });

  test('onUpgrade from version 2 to 3 creates workout_sessions and workout_exercises tables', () async {
    final mockDb = MigrationRecordingDb();
    await DatabaseHelper.onUpgrade(mockDb, 2, 3);

    expect(
      mockDb.executedStatements.any((sql) =>
          sql.contains('CREATE TABLE IF NOT EXISTS workout_sessions')),
      isTrue,
    );
    expect(
      mockDb.executedStatements.any((sql) =>
          sql.contains('CREATE TABLE IF NOT EXISTS workout_exercises')),
      isTrue,
    );
  });

  test('DatabaseHelper decodes migrated row with null exerciseId preserving old data', () async {
    final mockDb = MigrationRecordingDb();
    mockDb.tables[DatabaseHelper.tableName] = [
      {
        'id': 1,
        'exercise_name': 'Barbell Squat QA',
        'sets': 4,
        'reps': 10,
        'weight': 87.5,
        'workout_date': '2026-10-22',
        'notes': 'Sesi lokal testing persistence must survive',
        'exercise_id': null,
      }
    ];

    final helper = DatabaseHelper.withExecutor(mockDb);
    final logs = await helper.getAllWorkoutLogs();

    expect(logs.length, 1);
    final row = logs.first;
    expect(row.id, 1);
    expect(row.exerciseName, 'Barbell Squat QA');
    expect(row.sets, 4);
    expect(row.reps, 10);
    expect(row.weight, 87.5);
    expect(row.workoutDate, '2026-10-22');
    expect(row.notes, 'Sesi lokal testing persistence must survive');
    expect(row.exerciseId, isNull);
  });
}
