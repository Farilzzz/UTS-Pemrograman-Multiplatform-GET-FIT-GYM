import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/workout_session.dart';
import 'package:aplikasi_gym/model/workout_exercise.dart';

class MockRelationalDatabaseExecutor implements DatabaseExecutor {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> exercises = [];
  int nextSessionId = 1;
  int nextExerciseId = 1;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final row = Map<String, dynamic>.from(values);
    if (table == DatabaseHelper.sessionTableName) {
      final id = nextSessionId++;
      row['id'] = id;
      sessions.add(row);
      return id;
    } else if (table == DatabaseHelper.exerciseTableName) {
      final id = nextExerciseId++;
      row['id'] = id;
      exercises.add(row);
      return id;
    }
    return 1;
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
    if (table == DatabaseHelper.sessionTableName) {
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final id = whereArgs.first;
        return sessions.where((s) => s['id'] == id).toList();
      }
      return List.from(sessions);
    } else if (table == DatabaseHelper.exerciseTableName) {
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final sessionId = whereArgs.first;
        final matching = exercises.where((e) => e['session_id'] == sessionId).toList();
        matching.sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
        return matching;
      }
      return List.from(exercises);
    }
    return [];
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (table == DatabaseHelper.sessionTableName && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      final idx = sessions.indexWhere((s) => s['id'] == id);
      if (idx != -1) {
        sessions[idx].addAll(values);
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      if (table == DatabaseHelper.sessionTableName) {
        sessions.removeWhere((s) => s['id'] == id);
        exercises.removeWhere((e) => e['session_id'] == id);
        return 1;
      } else if (table == DatabaseHelper.exerciseTableName) {
        final before = exercises.length;
        exercises.removeWhere((e) => e['session_id'] == id);
        return before - exercises.length;
      }
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRelationalDatabaseExecutor mockDb;
  late DatabaseHelper helper;

  setUp(() {
    mockDb = MockRelationalDatabaseExecutor();
    helper = DatabaseHelper.withExecutor(mockDb);
  });

  test('insertSessionWithExercises saves header and exercises in one atomic flow', () async {
    final session = WorkoutSession(
      title: 'Push Day Alpha',
      scheduledDate: '2026-10-23',
      status: 'planned',
      createdAt: '2026-10-23T08:00:00Z',
      exercises: const [
        WorkoutExercise(
          exerciseName: 'Bench Press',
          targetMuscle: 'Pectorals',
          equipment: 'Barbell',
          sets: 3,
          reps: 12,
          weight: 60.0,
        ),
        WorkoutExercise(
          exerciseName: 'Incline Dumbbell Press',
          targetMuscle: 'Upper Chest',
          equipment: 'Dumbbell',
          sets: 3,
          reps: 10,
          weight: 22.5,
        ),
        WorkoutExercise(
          exerciseName: 'Cable Pushdown',
          targetMuscle: 'Triceps',
          equipment: 'Cable',
          sets: 3,
          reps: 15,
          weight: 20.0,
        ),
      ],
    );

    final sessionId = await helper.insertSessionWithExercises(session);
    expect(sessionId, 1);
    expect(mockDb.sessions.length, 1);
    expect(mockDb.exercises.length, 3);

    // Verify session
    expect(mockDb.sessions.first['title'], 'Push Day Alpha');
    expect(mockDb.sessions.first['status'], 'planned');

    // Verify exercise positions and foreign key
    expect(mockDb.exercises[0]['session_id'], 1);
    expect(mockDb.exercises[0]['exercise_name'], 'Bench Press');
    expect(mockDb.exercises[0]['position'], 0);

    expect(mockDb.exercises[1]['session_id'], 1);
    expect(mockDb.exercises[1]['exercise_name'], 'Incline Dumbbell Press');
    expect(mockDb.exercises[1]['position'], 1);

    expect(mockDb.exercises[2]['session_id'], 1);
    expect(mockDb.exercises[2]['exercise_name'], 'Cable Pushdown');
    expect(mockDb.exercises[2]['position'], 2);
  });

  test('getSessionById loads session and its child exercises in order', () async {
    final session = WorkoutSession(
      title: 'Leg Day Blast',
      scheduledDate: '2026-10-24',
      status: 'planned',
      createdAt: '2026-10-23T09:00:00Z',
      exercises: const [
        WorkoutExercise(exerciseName: 'Squat', sets: 4, reps: 8, weight: 100),
        WorkoutExercise(exerciseName: 'Leg Press', sets: 3, reps: 12, weight: 150),
      ],
    );

    final id = await helper.insertSessionWithExercises(session);
    final retrieved = await helper.getSessionById(id);

    expect(retrieved, isNotNull);
    expect(retrieved!.title, 'Leg Day Blast');
    expect(retrieved.exercises.length, 2);
    expect(retrieved.exercises[0].exerciseName, 'Squat');
    expect(retrieved.exercises[1].exerciseName, 'Leg Press');
  });

  test('updateSessionStatus transitions between planned and completed with timestamp', () async {
    final session = WorkoutSession(
      title: 'Pull Day',
      scheduledDate: '2026-10-25',
      status: 'planned',
      createdAt: '2026-10-23T10:00:00Z',
      exercises: const [
        WorkoutExercise(exerciseName: 'Pull-up', sets: 3, reps: 10),
      ],
    );
    final id = await helper.insertSessionWithExercises(session);

    // Mark as completed
    final completedTime = DateTime.now().toIso8601String();
    await helper.updateSessionStatus(id, 'completed', completedAt: completedTime);

    final completedSession = await helper.getSessionById(id);
    expect(completedSession!.status, 'completed');
    expect(completedSession.isCompleted, isTrue);
    expect(completedSession.completedAt, completedTime);

    // Toggle back to planned
    await helper.updateSessionStatus(id, 'planned');
    final plannedSession = await helper.getSessionById(id);
    expect(plannedSession!.status, 'planned');
    expect(plannedSession.isPlanned, isTrue);
    expect(plannedSession.completedAt, isNull);
  });

  test('deleteSession deletes session and cascades to related exercises', () async {
    final id = await helper.insertSessionWithExercises(
      WorkoutSession(
        title: 'Quick Core',
        scheduledDate: '2026-10-26',
        createdAt: '2026-10-23T11:00:00Z',
        exercises: const [
          WorkoutExercise(exerciseName: 'Plank', sets: 3, reps: 60),
          WorkoutExercise(exerciseName: 'Crunches', sets: 3, reps: 20),
        ],
      ),
    );

    expect(mockDb.sessions.length, 1);
    expect(mockDb.exercises.length, 2);

    final deletedCount = await helper.deleteSession(id);
    expect(deletedCount, 1);
    expect(mockDb.sessions.isEmpty, isTrue);
    expect(mockDb.exercises.isEmpty, isTrue);
  });
}
