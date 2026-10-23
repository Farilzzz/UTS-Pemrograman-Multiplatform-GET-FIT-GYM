import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/main.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:aplikasi_gym/view/home/home_page.dart';
import 'package:aplikasi_gym/view/workout/detail_exercise_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

class _MemoryThemeStore implements ThemePreferenceStore {
  bool value = true;

  @override
  Future<bool?> readDarkMode() async => value;

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async {
    value = isDarkMode;
    return true;
  }
}

class _EmptyDatabase implements DatabaseExecutor {
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
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyExerciseService extends ExerciseApiService {
  @override
  Future<ExerciseApiResponse> fetchExercises({
    int limit = 20,
    String? cursor,
    String? after,
    String? bodyPart,
    String? bodyParts,
    String? targetMuscle,
    String? targetMuscles,
    String? name,
  }) async =>
      const ExerciseApiResponse(exercises: [], total: 0, hasNextPage: false);

  @override
  void dispose() {}
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('standalone app opens Home directly with exactly three routes', (
    tester,
  ) async {
    final theme = ThemePreferenceService(store: _MemoryThemeStore());
    await tester.pumpWidget(
      MyApp(
        themeService: theme,
        databaseHelper: DatabaseHelper.withExecutor(_EmptyDatabase()),
        exerciseApiService: _EmptyExerciseService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Jelajahi Latihan'), findsOneWidget);
    expect(find.text('Jadwal & Riwayat'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.textContaining('Login'), findsNothing);
    expect(find.textContaining('Profile'), findsNothing);
  });

  testWidgets('home menu text stays constrained on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(260, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        home: HomePage(
          databaseHelper: DatabaseHelper.withExecutor(_EmptyDatabase()),
          exerciseApiService: _EmptyExerciseService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final menuText = tester.widget<Text>(find.text('Jelajahi Latihan'));
    expect(menuText.softWrap ?? (menuText.overflow == TextOverflow.ellipsis), isTrue);
  });

  testWidgets('ExerciseDB detail has no cloud workout action', (tester) async {
    const exercise = ExerciseApiModel(
      exerciseId: 'squat',
      name: 'barbell squat',
      gifUrl: '',
      bodyParts: ['upper legs'],
      equipments: ['barbell'],
      targetMuscles: ['quads'],
      secondaryMuscles: ['glutes'],
      instructions: ['Stand tall.', 'Squat with control.'],
    );

    await tester.pumpWidget(
      GetMaterialApp(home: DetailExercisePage(exercise: exercise)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barbell Squat'), findsOneWidget);
    expect(find.text('Add to Workout'), findsNothing);
    expect(find.text('Tambahkan ke Jadwal'), findsNothing);
  });
}
