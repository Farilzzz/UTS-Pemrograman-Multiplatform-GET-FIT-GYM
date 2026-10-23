import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/workout_session.dart';
import 'package:aplikasi_gym/model/workout_exercise.dart';
import 'package:aplikasi_gym/view/schedule/schedule_history_page.dart';
import 'package:aplikasi_gym/view/schedule/schedule_editor_page.dart';
import 'package:aplikasi_gym/view/schedule/session_detail_page.dart';

/// Test Fake DatabaseExecutor specifically configured for responsive tests
class FakeResponsiveScheduleDbExecutor implements DatabaseExecutor {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> exercises = [];
  bool throwErrorOnQuery = false;
  int nextSessionId = 100;
  int nextExerciseId = 200;

  FakeResponsiveScheduleDbExecutor({this.throwErrorOnQuery = false});

  void loadSampleData({required bool includePlanned, required bool includeCompleted}) {
    sessions.clear();
    exercises.clear();

    if (includePlanned) {
      sessions.add({
        'id': 1,
        'title': 'Program Latihan Kekuatan Komprehensif Semester 5 Target Hipertrofi Ekstrem 2026',
        'scheduled_date': '2026-10-23',
        'status': 'planned',
        'created_at': '2026-10-23T07:00:00Z',
        'completed_at': null,
      });

      // 5 long-named exercises
      exercises.addAll([
        {
          'id': 101,
          'session_id': 1,
          'exercise_api_id': 'band_romanian_deadlift',
          'exercise_name': 'Barbell Romanian Deadlift with Resistance Band Tension',
          'target_muscle': 'Hamstrings & Gluteus Maximus',
          'equipment': 'Olympic Barbell & Heavy Loop Band',
          'sets': 4,
          'reps': 10,
          'weight': 110.0,
          'notes': 'Pertahankan ketegangan pada bagian eksentrik selama 3 detik dan jangan biarkan punggung melengkung.',
          'position': 0,
        },
        {
          'id': 102,
          'session_id': 1,
          'exercise_api_id': 'pause_incline_dumbbell_press',
          'exercise_name': 'Close-Grip Incline Dumbbell Bench Press with Pause at Bottom',
          'target_muscle': 'Upper Pectoralis Major & Triceps Brachii',
          'equipment': 'Incline Adjustable Bench & Hex Dumbbells',
          'sets': 4,
          'reps': 12,
          'weight': 28.0,
          'notes': 'Berhenti selama 2 detik di bagian dada bawah sebelum mendorong beban ke atas.',
          'position': 1,
        },
        {
          'id': 103,
          'session_id': 1,
          'exercise_api_id': 'arnold_shoulder_press_rotation',
          'exercise_name': 'Overhead Alternating Dumbbell Shoulder Press with External Rotation',
          'target_muscle': 'Anterior & Lateral Deltoids',
          'equipment': 'Dumbbells',
          'sets': 3,
          'reps': 15,
          'weight': 18.0,
          'notes': 'Pastikan rotasi pergelangan tangan halus dan inti tubuh tetap terkunci kuat.',
          'position': 2,
        },
        {
          'id': 104,
          'session_id': 1,
          'exercise_api_id': 'bulgarian_split_squat_kettlebell',
          'exercise_name': 'Single-Leg Bulgarian Split Squat with Kettlebell Front Rack',
          'target_muscle': 'Quadriceps Femoris & Adductors',
          'equipment': 'Competition Kettlebell & Plyo Box',
          'sets': 4,
          'reps': 10,
          'weight': 24.0,
          'notes': 'Lutut depan tidak boleh kolaps ke dalam, fokus dorong beban dari tumit kaki depan.',
          'position': 3,
        },
        {
          'id': 105,
          'session_id': 1,
          'exercise_api_id': 'hanging_knees_elbows',
          'exercise_name': 'Hanging Knees-to-Elbows Abdominal Core Contraction',
          'target_muscle': 'Rectus Abdominis & Hip Flexors',
          'equipment': 'Pull-Up Bar Rig',
          'sets': 3,
          'reps': 15,
          'weight': 0.0,
          'notes': 'Hindari mengayunkan pinggul, gunakan murni kekuatan perut bawah untuk mengangkat lutut.',
          'position': 4,
        },
      ]);
    }

    if (includeCompleted) {
      sessions.add({
        'id': 2,
        'title': 'Sesi Pemulihan Aktif Mobilitas & Daya Tahan Kardiovaskular Pagi Hari',
        'scheduled_date': '2026-10-22',
        'status': 'completed',
        'created_at': '2026-10-22T06:00:00Z',
        'completed_at': '2026-10-22T07:45:00Z',
      });

      exercises.addAll([
        {
          'id': 201,
          'session_id': 2,
          'exercise_api_id': 'band_pull_apart',
          'exercise_name': 'Standing Resistance Band Face Pull with External Shoulder Rotation',
          'target_muscle': 'Rear Deltoids & Rhomboids',
          'equipment': 'Resistance Band',
          'sets': 3,
          'reps': 20,
          'weight': 0.0,
          'notes': 'Pegang puncak kontraksi selama 1 detik penuh untuk aktivasi postur maksimal.',
          'position': 0,
        },
        {
          'id': 202,
          'session_id': 2,
          'exercise_api_id': 'goblet_squat_pause',
          'exercise_name': 'Deep Goblet Squat with Bottom Prying and Hip Mobility Opener',
          'target_muscle': 'Hip Adductors & Glutes',
          'equipment': 'Heavy Kettlebell',
          'sets': 3,
          'reps': 12,
          'weight': 20.0,
          'notes': 'Buka pinggul menggunakan siku di bagian bawah gerakan jongkok.',
          'position': 1,
        },
      ]);
    }
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
    if (throwErrorOnQuery) {
      throw Exception('Simulated SQLite disk I/O read failure for responsive test');
    }

    if (table == DatabaseHelper.sessionTableName) {
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        if (where.contains(DatabaseHelper.columnSessionId)) {
          final targetId = whereArgs.first;
          return sessions.where((s) => s['id'] == targetId).toList();
        }
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
    } else {
      final id = nextExerciseId++;
      row['id'] = id;
      exercises.add(row);
      return id;
    }
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
      if (table == DatabaseHelper.sessionTableName) {
        final idx = sessions.indexWhere((s) => s['id'] == id);
        if (idx != -1) {
          sessions[idx].addAll(values);
          return 1;
        }
      } else {
        final idx = exercises.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          exercises[idx].addAll(values);
          return 1;
        }
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
      } else {
        exercises.removeWhere((e) => e['id'] == id);
        return 1;
      }
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testSizes = [
    Size(320, 568),
    Size(360, 640),
    Size(412, 915),
    Size(600, 960),
  ];

  const textScales = [1.0, 1.5, 2.0];

  Widget buildTestHost({
    required Widget child,
    required Size size,
    required double textScale,
    double keyboardInset = 0.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: child,
      ),
    );
  }

  Future<void> setTestViewport(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    double keyboardInset = 0.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  }

  tearDown(() {
    // Reset view bounds between test executions
  });

  group('ScheduleHistoryPage Responsive Matrix', () {
    for (final size in testSizes) {
      for (final scale in textScales) {
        testWidgets('ScheduleHistoryPage renders planned and completed at ${size.width}x${size.height} scale $scale', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetViewInsets);

          await setTestViewport(tester, size: size, textScale: scale);

          final fakeDb = FakeResponsiveScheduleDbExecutor();
          fakeDb.loadSampleData(includePlanned: true, includeCompleted: true);
          final dbHelper = DatabaseHelper.withExecutor(fakeDb);

          await tester.pumpWidget(
            buildTestHost(
              child: ScheduleHistoryPage(databaseHelper: dbHelper),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Jadwal & Riwayat'), findsOneWidget);
          expect(find.text('Jadwal Latihan'), findsOneWidget);
          expect(find.text('Riwayat Latihan'), findsOneWidget);
          expect(find.text('Program Latihan Kekuatan Komprehensif Semester 5 Target Hipertrofi Ekstrem 2026'), findsOneWidget);

          // Verify actions exist
          expect(find.text('Selesaikan'), findsOneWidget);

          // Switch to Riwayat Tab
          await tester.tap(find.text('Riwayat Latihan'));
          await tester.pumpAndSettle();

          expect(find.text('Sesi Pemulihan Aktif Mobilitas & Daya Tahan Kardiovaskular Pagi Hari'), findsOneWidget);
          expect(find.text('Detail'), findsOneWidget);
        });
      }
    }

    testWidgets('ScheduleHistoryPage empty states render without overflow on 320x568 scale 2.0 keyboard 280', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);

      const size = Size(320, 568);
      const scale = 2.0;
      const keyboard = 280.0;

      await setTestViewport(tester, size: size, textScale: scale, keyboardInset: keyboard);

      final fakeDb = FakeResponsiveScheduleDbExecutor();
      fakeDb.loadSampleData(includePlanned: false, includeCompleted: false);
      final dbHelper = DatabaseHelper.withExecutor(fakeDb);

      await tester.pumpWidget(
        buildTestHost(
          child: ScheduleHistoryPage(databaseHelper: dbHelper),
          size: size,
          textScale: scale,
          keyboardInset: keyboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buat Jadwal Pertama'), findsOneWidget);

      // Riwayat Tab Empty
      await tester.tap(find.text('Riwayat Latihan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Belum ada riwayat latihan'), findsOneWidget);
    });

    testWidgets('ScheduleHistoryPage error state renders without overflow on 320x568 scale 2.0', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);

      const size = Size(320, 568);
      const scale = 2.0;

      await setTestViewport(tester, size: size, textScale: scale);

      final fakeDb = FakeResponsiveScheduleDbExecutor(throwErrorOnQuery: true);
      final dbHelper = DatabaseHelper.withExecutor(fakeDb);

      await tester.pumpWidget(
        buildTestHost(
          child: ScheduleHistoryPage(databaseHelper: dbHelper),
          size: size,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal memuat data SQLite'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('ScheduleHistoryPage status dialog and delete dialog responsive on 320x568 scale 2.0 keyboard 280', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);

      const size = Size(320, 568);
      const scale = 2.0;
      const keyboard = 280.0;

      await setTestViewport(tester, size: size, textScale: scale, keyboardInset: keyboard);

      final fakeDb = FakeResponsiveScheduleDbExecutor();
      fakeDb.loadSampleData(includePlanned: true, includeCompleted: true);
      final dbHelper = DatabaseHelper.withExecutor(fakeDb);

      await tester.pumpWidget(
        buildTestHost(
          child: ScheduleHistoryPage(databaseHelper: dbHelper),
          size: size,
          textScale: scale,
          keyboardInset: keyboard,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger Selesaikan Dialog
      final selesaikanBtn = find.text('Selesaikan');
      await tester.dragUntilVisible(selesaikanBtn.hitTestable(), find.byType(ListView).first, const Offset(0, -100), maxIteration: 100);
      await tester.tap(selesaikanBtn);
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan Sesi?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Trigger Delete Dialog
      final deleteBtn = find.byTooltip('Hapus sesi').first;
      await tester.dragUntilVisible(deleteBtn.hitTestable(), find.byType(ListView).first, const Offset(0, -80), maxIteration: 100);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Sesi Latihan?'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });
  });

  group('SessionDetailPage Responsive Matrix', () {
    for (final size in testSizes) {
      for (final scale in textScales) {
        testWidgets('SessionDetailPage renders 5 long exercises at ${size.width}x${size.height} scale $scale', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetViewInsets);

          await setTestViewport(tester, size: size, textScale: scale);

          final fakeDb = FakeResponsiveScheduleDbExecutor();
          fakeDb.loadSampleData(includePlanned: true, includeCompleted: false);
          final dbHelper = DatabaseHelper.withExecutor(fakeDb);

          await tester.pumpWidget(
            buildTestHost(
              child: SessionDetailPage(sessionId: 1, databaseHelper: dbHelper),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Detail Sesi Latihan'), findsOneWidget);
          expect(find.text('Program Latihan Kekuatan Komprehensif Semester 5 Target Hipertrofi Ekstrem 2026'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Barbell Romanian Deadlift with Resistance Band Tension'), 150, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('Barbell Romanian Deadlift with Resistance Band Tension'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Hanging Knees-to-Elbows Abdominal Core Contraction'), 200, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('Hanging Knees-to-Elbows Abdominal Core Contraction'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Hapus Sesi'), 200, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('Tandai Selesai (Simpan ke Riwayat)'), findsOneWidget);
          expect(find.text('Edit Jadwal'), findsOneWidget);
          expect(find.text('Hapus Sesi'), findsOneWidget);
        });
      }
    }

    testWidgets('SessionDetailPage completed state and error state responsive on 320x568 scale 2.0', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);

      const size = Size(320, 568);
      const scale = 2.0;

      await setTestViewport(tester, size: size, textScale: scale);

      final fakeDb = FakeResponsiveScheduleDbExecutor();
      fakeDb.loadSampleData(includePlanned: false, includeCompleted: true);
      final dbHelper = DatabaseHelper.withExecutor(fakeDb);

      await tester.pumpWidget(
        buildTestHost(
          child: SessionDetailPage(sessionId: 2, databaseHelper: dbHelper),
          size: size,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Kembalikan ke Jadwal Aktif'), 200, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Kembalikan ke Jadwal Aktif'), findsOneWidget);
    });
  });

  group('ScheduleEditorPage Responsive Matrix', () {
    for (final size in testSizes) {
      for (final scale in textScales) {
        testWidgets('ScheduleEditorPage renders with 5 long exercises at ${size.width}x${size.height} scale $scale', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetViewInsets);

          await setTestViewport(tester, size: size, textScale: scale);

          final fakeDb = FakeResponsiveScheduleDbExecutor();
          fakeDb.loadSampleData(includePlanned: true, includeCompleted: false);
          final dbHelper = DatabaseHelper.withExecutor(fakeDb);

          final sampleSession = WorkoutSession(
            createdAt: '2026-10-23T07:00:00Z',
            id: 1,
            title: 'Program Latihan Kekuatan Komprehensif Semester 5 Target Hipertrofi Ekstrem 2026',
            scheduledDate: '2026-10-23',
            status: 'planned',
            exercises: const [
              WorkoutExercise(
                id: 101,
                sessionId: 1,
                exerciseName: 'Barbell Romanian Deadlift with Resistance Band Tension',
                targetMuscle: 'Hamstrings & Gluteus Maximus',
                equipment: 'Olympic Barbell & Heavy Loop Band',
                sets: 4,
                reps: 10,
                weight: 110.0,
                position: 0,
              ),
              WorkoutExercise(
                id: 102,
                sessionId: 1,
                exerciseName: 'Close-Grip Incline Dumbbell Bench Press with Pause at Bottom',
                targetMuscle: 'Upper Pectoralis Major & Triceps Brachii',
                equipment: 'Incline Adjustable Bench & Hex Dumbbells',
                sets: 4,
                reps: 12,
                weight: 28.0,
                position: 1,
              ),
              WorkoutExercise(
                id: 103,
                sessionId: 1,
                exerciseName: 'Overhead Alternating Dumbbell Shoulder Press with External Rotation',
                targetMuscle: 'Anterior & Lateral Deltoids',
                equipment: 'Dumbbells',
                sets: 3,
                reps: 15,
                weight: 18.0,
                position: 2,
              ),
              WorkoutExercise(
                id: 104,
                sessionId: 1,
                exerciseName: 'Single-Leg Bulgarian Split Squat with Kettlebell Front Rack',
                targetMuscle: 'Quadriceps Femoris & Adductors',
                equipment: 'Competition Kettlebell & Plyo Box',
                sets: 4,
                reps: 10,
                weight: 24.0,
                position: 3,
              ),
              WorkoutExercise(
                id: 105,
                sessionId: 1,
                exerciseName: 'Hanging Knees-to-Elbows Abdominal Core Contraction',
                targetMuscle: 'Rectus Abdominis & Hip Flexors',
                equipment: 'Pull-Up Bar Rig',
                sets: 3,
                reps: 15,
                weight: 0.0,
                position: 4,
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestHost(
              child: ScheduleEditorPage(
                session: sampleSession,
                databaseHelper: dbHelper,
              ),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Edit Jadwal'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Daftar Latihan (5)'), 100, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('Daftar Latihan (5)'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Barbell Romanian Deadlift with Resistance Band Tension'), 100, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('Barbell Romanian Deadlift with Resistance Band Tension'), findsOneWidget);

          final saveBtn = find.text('Perbarui Jadwal Latihan');
          await tester.scrollUntilVisible(saveBtn, 200, maxScrolls: 200, scrollable: find.byType(Scrollable).first);
          expect(saveBtn, findsOneWidget);
        });
      }
    }

    testWidgets('ScheduleEditorPage manual exercise dialog with keyboard inset 280 on 320x568 scale 2.0', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);

      const size = Size(320, 568);
      const scale = 2.0;
      const keyboard = 280.0;

      await setTestViewport(tester, size: size, textScale: scale);

      final fakeDb = FakeResponsiveScheduleDbExecutor();
      final dbHelper = DatabaseHelper.withExecutor(fakeDb);

      await tester.pumpWidget(
        buildTestHost(
          child: ScheduleEditorPage(databaseHelper: dbHelper),
          size: size,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();

      final addChip = find.text('Tambah Gerakan');
      // Scroll until addChip is within visible viewport
      await tester.dragUntilVisible(addChip.hitTestable(), find.byType(ListView), const Offset(0, -100), maxIteration: 100);
      await tester.pumpAndSettle();
      await tester.tap(addChip);
      await tester.pumpAndSettle();

      // Tap manual option
      expect(find.text('Input Manual (Offline)'), findsOneWidget);
      await tester.tap(find.text('Input Manual (Offline)'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      expect(find.text('Input Gerakan Manual (Offline)'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Tambahkan'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });
  });
}
