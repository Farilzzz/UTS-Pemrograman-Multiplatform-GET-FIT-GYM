import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/workout_session.dart';
import 'package:aplikasi_gym/model/workout_exercise.dart';
import 'package:aplikasi_gym/view/schedule/schedule_editor_page.dart';

class _FakeDbExecutor implements DatabaseExecutor {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> exercises = [];
  int nextId = 1;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final row = Map<String, dynamic>.from(values);
    final id = nextId++;
    row['id'] = id;
    if (table == DatabaseHelper.sessionTableName) {
      sessions.add(row);
    } else {
      exercises.add(row);
    }
    return id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ScheduleEditorPage validates title and exercises on save', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeDb = _FakeDbExecutor();
    final dbHelper = DatabaseHelper.withExecutor(fakeDb);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleEditorPage(databaseHelper: dbHelper),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buat Jadwal Baru'), findsOneWidget);

    // Tap Simpan with empty title and empty exercises
    final saveButton = find.text('Simpan Jadwal Latihan');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify error message for title
    expect(find.text('Nama jadwal tidak boleh kosong.'), findsOneWidget);

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'Leg Day');
    await tester.pumpAndSettle();

    // Tap Simpan again - should warn about empty exercise list
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Pilih minimal satu gerakan latihan untuk jadwal ini.'), findsOneWidget);
  });

  testWidgets('ScheduleEditorPage allows adding manual exercise and saving', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeDb = _FakeDbExecutor();
    final dbHelper = DatabaseHelper.withExecutor(fakeDb);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleEditorPage(databaseHelper: dbHelper),
      ),
    );
    await tester.pumpAndSettle();

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'Push Day Special');

    // Tap Tambah Gerakan chip to show popup menu
    await tester.tap(find.text('Tambah Gerakan'));
    await tester.pumpAndSettle();

    // Tap Input Manual
    expect(find.text('Input Manual (Offline)'), findsOneWidget);
    await tester.tap(find.text('Input Manual (Offline)'));
    await tester.pumpAndSettle();

    expect(find.text('Input Gerakan Manual (Offline)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Diamond Push-Up');
    await tester.tap(find.text('Tambahkan'));
    await tester.pumpAndSettle();

    // Verify item added
    expect(find.text('Diamond Push-Up'), findsOneWidget);

    // Save
    final saveBtn = find.text('Simpan Jadwal Latihan');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify saved to database
    expect(fakeDb.sessions.length, 1);
    expect(fakeDb.sessions.first['title'], 'Push Day Special');
    expect(fakeDb.exercises.length, 1);
    expect(fakeDb.exercises.first['exercise_name'], 'Diamond Push-Up');
  });

  testWidgets('ScheduleEditorPage loads existing session for editing', (tester) async {
    final fakeDb = _FakeDbExecutor();
    final dbHelper = DatabaseHelper.withExecutor(fakeDb);

    final existing = WorkoutSession(
      id: 88,
      title: 'Pull Session Pro',
      scheduledDate: '2026-10-23',
      status: 'planned',
      createdAt: '2026-10-23T07:00:00Z',
      exercises: const [
        WorkoutExercise(
          id: 1,
          sessionId: 88,
          exerciseName: 'Lat Pulldown',
          targetMuscle: 'Lats',
          sets: 4,
          reps: 10,
          weight: 55.0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleEditorPage(
          session: existing,
          databaseHelper: dbHelper,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Jadwal'), findsOneWidget);
    expect(find.text('Pull Session Pro'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsOneWidget);
  });
}
