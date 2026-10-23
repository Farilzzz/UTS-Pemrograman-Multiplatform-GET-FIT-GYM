import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';

class FakeDatabaseExecutor implements DatabaseExecutor {
  String? lastAction;
  String? lastTable;
  Map<String, Object?>? lastValues;
  String? lastWhere;
  List<Object?>? lastWhereArgs;
  String? lastOrderBy;
  List<Map<String, Object?>> queryResult = [];

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    lastAction = 'insert';
    lastTable = table;
    lastValues = values;
    return 101;
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
    lastAction = 'query';
    lastTable = table;
    lastWhere = where;
    lastWhereArgs = whereArgs;
    lastOrderBy = orderBy;
    return queryResult;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    lastAction = 'update';
    lastTable = table;
    lastValues = values;
    lastWhere = where;
    lastWhereArgs = whereArgs;
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    lastAction = 'delete';
    lastTable = table;
    lastWhere = where;
    lastWhereArgs = whereArgs;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDatabaseExecutor fakeDb;
  late DatabaseHelper helper;

  setUp(() {
    fakeDb = FakeDatabaseExecutor();
    helper = DatabaseHelper.withExecutor(fakeDb);
  });

  test(
    'DatabaseHelper uses parameterized whereArgs for getById, update, and delete',
    () async {
      const log = LocalWorkoutLog(
        id: 7,
        exerciseName: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 60.0,
        workoutDate: '2026-10-22',
        notes: 'Heavy set',
      );

      // Insert
      final insertedId = await helper.insertWorkoutLog(log);
      expect(insertedId, 101);
      expect(fakeDb.lastAction, 'insert');
      expect(fakeDb.lastTable, DatabaseHelper.tableName);
      expect(fakeDb.lastValues?['exercise_name'], 'Bench Press');
      expect(fakeDb.lastValues!.containsKey('id'), isFalse);

      // Query All
      fakeDb.queryResult = [log.toMap()];
      final list = await helper.getAllWorkoutLogs();
      expect(list.length, 1);
      expect(list.first.exerciseName, 'Bench Press');
      expect(fakeDb.lastOrderBy, contains('workout_date DESC'));

      // Get by ID (Parameterized)
      await helper.getWorkoutLogById(7);
      expect(fakeDb.lastWhere, 'id = ?');
      expect(fakeDb.lastWhereArgs, [7]);

      // Update (Parameterized)
      final rowsUpdated = await helper.updateWorkoutLog(log);
      expect(rowsUpdated, 1);
      expect(fakeDb.lastWhere, 'id = ?');
      expect(fakeDb.lastWhereArgs, [7]);

      // Delete (Parameterized)
      final rowsDeleted = await helper.deleteWorkoutLog(7);
      expect(rowsDeleted, 1);
      expect(fakeDb.lastWhere, 'id = ?');
      expect(fakeDb.lastWhereArgs, [7]);
    },
  );
}
