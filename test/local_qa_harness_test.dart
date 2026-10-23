import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/main_local.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';
import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:aplikasi_gym/view/local_workout/local_workout_history_page.dart';
import 'package:aplikasi_gym/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

class _InMemoryThemeStore implements ThemePreferenceStore {
  bool? stored;
  _InMemoryThemeStore([this.stored]);

  @override
  Future<bool?> readDarkMode() async => stored;

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async {
    stored = isDarkMode;
    return true;
  }
}

class _FakeDatabaseExecutor implements DatabaseExecutor {
  final List<Map<String, dynamic>> records = [];
  int _nextId = 1;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final copy = Map<String, dynamic>.of(values);
    copy['id'] = _nextId++;
    records.add(copy);
    return copy['id'] as int;
  }

  @override
  Future<List<Map<String, dynamic>>> query(
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
    return List<Map<String, dynamic>>.from(records);
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = whereArgs?.first as int?;
    final index = records.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      records[index] = Map<String, dynamic>.of(values);
      return 1;
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
      final id = whereArgs.first as int?;
      records.removeWhere((r) => r['id'] == id);
      return 1;
    }
    final count = records.length;
    records.clear();
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'LocalQaApp initializes standalone without Firebase and navigates between local history and settings',
    (tester) async {
      final store = _InMemoryThemeStore(true);
      final themeService = ThemePreferenceService(store: store);
      final executor = _FakeDatabaseExecutor();
      final dbHelper = DatabaseHelper.withExecutor(executor);

      // Pre-populate with one item
      await dbHelper.insertWorkoutLog(
        LocalWorkoutLog(
          id: 1,
          exerciseName: 'Bench Press Lokal',
          sets: 3,
          reps: 10,
          weight: 60.0,
          workoutDate: '2026-10-22',
          notes: 'Latihan dada',
        ),
      );

      await tester.pumpWidget(
        LocalQaApp(themeService: themeService, databaseHelper: dbHelper),
      );
      await tester.pumpAndSettle();

      // Verify it renders LocalWorkoutHistoryPage first
      expect(find.byType(LocalWorkoutHistoryPage), findsOneWidget);
      expect(find.text('Riwayat Latihan Lokal'), findsOneWidget);
      expect(find.text('Bench Press Lokal'), findsOneWidget);

      // Tap on Settings tab in navigation bar
      final settingsTab = find.byKey(const Key('local_qa_settings_tab'));
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();

      // Verify SettingsPage is now visible
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // Toggle Dark Mode
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(store.stored, isFalse);
      expect(themeService.isDarkMode.value, isFalse);
    },
  );
}
