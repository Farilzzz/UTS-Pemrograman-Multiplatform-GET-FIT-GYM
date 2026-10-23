import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';
import 'package:aplikasi_gym/view/local_workout/local_workout_history_page.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

class TestStore extends DatabaseHelper {
  final logs = <LocalWorkoutLog>[];
  bool fail = false;
  @override
  Future<List<LocalWorkoutLog>> getAllWorkoutLogs() async {
    if (fail) throw StateError('offline');
    return List.of(logs);
  }

  @override
  Future<int> insertWorkoutLog(LocalWorkoutLog log) async {
    if (fail) throw StateError('disk full');
    logs.add(log.copyWith(id: 1));
    return 1;
  }

  @override
  Future<int> updateWorkoutLog(LocalWorkoutLog log) async {
    logs[logs.indexWhere((e) => e.id == log.id)] = log;
    return 1;
  }

  @override
  Future<int> deleteWorkoutLog(int id) async {
    logs.removeWhere((e) => e.id == id);
    return 1;
  }
}

void main() {
  testWidgets(
    'local add edit delete requires confirmation and validates input',
    (tester) async {
      final store = TestStore();
      await tester.pumpWidget(
        MaterialApp(home: LocalWorkoutHistoryPage(databaseHelper: store)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('perangkat ini'), findsWidgets);
      await tester.tap(find.text('Tambah Latihan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(store.logs, isEmpty);
      await tester.enterText(find.byKey(const Key('exerciseName')), 'Squat');
      await tester.enterText(find.byKey(const Key('sets')), '3');
      await tester.enterText(find.byKey(const Key('reps')), '10');
      await tester.enterText(find.byKey(const Key('weight')), '0');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(store.logs.single.exerciseName, 'Squat');
      await tester.tap(find.byTooltip('Edit latihan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('exerciseName')), 'Lunge');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Lunge'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus latihan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(store.logs, hasLength(1));
      await tester.tap(find.byTooltip('Hapus latihan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(store.logs, isEmpty);
    },
  );
  testWidgets('save failure keeps entered input and permits retry', (
    tester,
  ) async {
    final store = TestStore();
    await tester.pumpWidget(
      MaterialApp(home: LocalWorkoutHistoryPage(databaseHelper: store)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Latihan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exerciseName')), 'Deadlift');
    await tester.enterText(find.byKey(const Key('sets')), '2');
    await tester.enterText(find.byKey(const Key('reps')), '8');
    await tester.enterText(find.byKey(const Key('weight')), '20');
    store.fail = true;
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Latihan gagal disimpan. Coba lagi.'), findsOneWidget);
    expect(find.text('Deadlift'), findsOneWidget);
    expect(store.logs, isEmpty);
    store.fail = false;
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(store.logs.single.exerciseName, 'Deadlift');
  });

  testWidgets('load failure has explicit retry', (tester) async {
    final store = TestStore()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: LocalWorkoutHistoryPage(databaseHelper: store)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada latihan lokal.'), findsOneWidget);
  });

  testWidgets('history stays offline; picker prefills identity and edit preserves values', (tester) async {
    final store = TestStore()..logs.add(const LocalWorkoutLog(id: 1, exerciseId: 'old-id', exerciseName: 'Old', sets: 3, reps: 9, weight: 12, workoutDate: '2026-10-22', notes: 'keep me'));
    int apiCalls = 0;
    final service = ExerciseApiService(client: MockClient((r) async { apiCalls++; return http.Response(jsonEncode({'success': true, 'data': [{'exerciseId':'new-id','name':'new press'}], 'meta': {'total':1,'hasNextPage':false}}), 200); }));
    await tester.pumpWidget(MaterialApp(home: LocalWorkoutHistoryPage(databaseHelper: store, apiService: service)));
    await tester.pumpAndSettle();
    expect(apiCalls, 0);
    await tester.tap(find.text('Tambah Latihan')); await tester.pumpAndSettle();
    expect(find.text('Pilih dari ExerciseDB'), findsOneWidget);
    expect(apiCalls, 0);
    await tester.tap(find.text('Pilih dari ExerciseDB')); await tester.pumpAndSettle();
    expect(apiCalls, 1);
    await tester.tap(find.text('New Press')); await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'new press'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('sets')), '2');
    await tester.enterText(find.byKey(const Key('reps')), '8');
    await tester.enterText(find.byKey(const Key('weight')), '0');
    await tester.tap(find.text('Simpan')); await tester.pumpAndSettle();
    expect(store.logs.last.exerciseId, 'new-id');
    await tester.tap(find.byTooltip('Edit latihan').first); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sets')), '7');
    await tester.tap(find.text('Ganti via ExerciseDB')); await tester.pumpAndSettle();
    await tester.tap(find.text('Input manual (offline)')); await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '7'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('exerciseName')), 'Manual changed');
    await tester.tap(find.text('Simpan')); await tester.pumpAndSettle();
    expect(store.logs.first.exerciseId, isNull);
    expect(store.logs.first.sets, 7);
  });
}
