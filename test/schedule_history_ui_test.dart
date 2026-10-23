import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/view/schedule/schedule_history_page.dart';

class _FakeHistoryDbExecutor implements DatabaseExecutor {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> exercises = [];

  _FakeHistoryDbExecutor() {
    sessions.addAll([
      {
        'id': 1,
        'title': 'Push Day Target',
        'scheduled_date': '2026-10-23',
        'status': 'planned',
        'created_at': '2026-10-23T07:00:00Z',
        'completed_at': null,
      },
      {
        'id': 2,
        'title': 'Leg Day Completed',
        'scheduled_date': '2026-10-22',
        'status': 'completed',
        'created_at': '2026-10-22T07:00:00Z',
        'completed_at': '2026-10-22T08:30:00Z',
      },
    ]);

    exercises.addAll([
      {
        'id': 1,
        'session_id': 1,
        'exercise_api_id': 'bench_press',
        'exercise_name': 'Bench Press',
        'target_muscle': 'Chest',
        'equipment': 'Barbell',
        'sets': 3,
        'reps': 12,
        'weight': 60.0,
        'notes': '',
        'position': 0,
      },
      {
        'id': 2,
        'session_id': 2,
        'exercise_api_id': 'squat',
        'exercise_name': 'Barbell Squat',
        'target_muscle': 'Quads',
        'equipment': 'Barbell',
        'sets': 4,
        'reps': 10,
        'weight': 100.0,
        'notes': '',
        'position': 0,
      },
    ]);
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
        final status = whereArgs.first;
        return sessions.where((s) => s['status'] == status).toList();
      }
      return List.from(sessions);
    } else if (table == DatabaseHelper.exerciseTableName) {
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final sId = whereArgs.first;
        return exercises.where((e) => e['session_id'] == sId).toList();
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
    if (whereArgs != null && whereArgs.isNotEmpty) {
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
      sessions.removeWhere((s) => s['id'] == id);
      exercises.removeWhere((e) => e['session_id'] == id);
      return 1;
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ScheduleHistoryPage renders planned and completed tabs accurately', (tester) async {
    final fakeDb = _FakeHistoryDbExecutor();
    final dbHelper = DatabaseHelper.withExecutor(fakeDb);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleHistoryPage(databaseHelper: dbHelper),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('Jadwal & Riwayat'), findsOneWidget);
    expect(find.text('Jadwal Latihan'), findsOneWidget);
    expect(find.text('Riwayat Latihan'), findsOneWidget);

    // Initial Tab: Planned
    expect(find.text('Push Day Target'), findsOneWidget);
    expect(find.text('Direncanakan'), findsOneWidget);
    expect(find.text('Selesaikan'), findsOneWidget);

    // Switch to Riwayat tab
    await tester.tap(find.text('Riwayat Latihan'));
    await tester.pumpAndSettle();

    expect(find.text('Leg Day Completed'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets('ScheduleHistoryPage completes a planned session via dialog', (tester) async {
    final fakeDb = _FakeHistoryDbExecutor();
    final dbHelper = DatabaseHelper.withExecutor(fakeDb);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleHistoryPage(databaseHelper: dbHelper),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Selesaikan on Push Day Target
    await tester.tap(find.text('Selesaikan'));
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Selesaikan Sesi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Selesaikan Sesi'));
    await tester.pumpAndSettle();

    // Verify status updated in database
    final updatedSession = fakeDb.sessions.firstWhere((s) => s['id'] == 1);
    expect(updatedSession['status'], 'completed');
  });
}
