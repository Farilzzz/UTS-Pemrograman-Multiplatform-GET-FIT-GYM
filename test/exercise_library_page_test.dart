import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/view/workout/list_all_exercise_page.dart';
import 'package:aplikasi_gym/view/workout/detail_exercise_page.dart';
import 'package:aplikasi_gym/view/widgets/exercise_gif_preview.dart';

class FakeExerciseApiService extends ExerciseApiService {
  FakeExerciseApiService(this.handler);

  final Future<ExerciseApiResponse> Function({
    int limit,
    String? cursor,
    String? after,
    String? bodyPart,
    String? bodyParts,
    String? targetMuscle,
    String? targetMuscles,
    String? name,
  })
  handler;

  int calls = 0;
  final List<Map<String, dynamic>> recordedCalls = [];

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
  }) {
    calls++;
    recordedCalls.add({
      'limit': limit,
      'cursor': cursor,
      'after': after,
      'bodyPart': bodyPart,
      'bodyParts': bodyParts,
      'targetMuscle': targetMuscle,
      'targetMuscles': targetMuscles,
      'name': name,
    });
    return handler(
      limit: limit,
      cursor: cursor,
      after: after,
      bodyPart: bodyPart,
      bodyParts: bodyParts,
      targetMuscle: targetMuscle,
      targetMuscles: targetMuscles,
      name: name,
    );
  }

  @override
  void dispose() {}
}

const sampleExercise1 = ExerciseApiModel(
  exerciseId: 'ex-1',
  name: 'bench press',
  gifUrl: 'https://static.exercisedb.dev/media/ex1.gif',
  bodyParts: ['chest'],
  equipments: ['barbell'],
  targetMuscles: ['pectorals'],
  secondaryMuscles: ['triceps'],
  instructions: ['Lie on bench', 'Press barbell up'],
);

const sampleExercise2 = ExerciseApiModel(
  exerciseId: 'ex-2',
  name: 'incline dumbbell press',
  gifUrl: 'https://static.exercisedb.dev/media/ex2.gif',
  bodyParts: ['chest'],
  equipments: ['dumbbell'],
  targetMuscles: ['upper pectorals'],
  secondaryMuscles: ['front deltoids'],
  instructions: ['Set bench to incline', 'Press dumbbells up'],
);

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget(
    ExerciseApiService service, {
    String bodyPart = 'chest',
  }) {
    return GetMaterialApp(
      home: ListAllExercisePage(bodyPartName: bodyPart, apiService: service),
    );
  }

  group('ExerciseDB OSS ListAllExercisePage Integration', () {
    testWidgets(
      'loads initial exercises, maps query, and displays attribution',
      (tester) async {
        final service = FakeExerciseApiService(({
          limit = 20,
          cursor,
          after,
          bodyPart,
          bodyParts,
          targetMuscle,
          targetMuscles,
          name,
        }) async {
          return const ExerciseApiResponse(
            exercises: [sampleExercise1],
            total: 1,
            hasNextPage: false,
          );
        });

        await tester.pumpWidget(createTestWidget(service, bodyPart: 'chest'));

        // Initially shows loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // Displays exercise name and attribution
        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.textContaining('ExerciseDB OSS'), findsWidgets);
        expect(service.calls, 1);
        expect(service.recordedCalls.first['bodyPart'], 'chest');

        // Rebuild does not trigger duplicate fetch
        await tester.pump();
        expect(service.calls, 1);
      },
    );

    testWidgets(
      'cursor pagination appends next page items when Load More is tapped',
      (tester) async {
        var fetchIndex = 0;
        final service = FakeExerciseApiService(({
          limit = 20,
          cursor,
          after,
          bodyPart,
          bodyParts,
          targetMuscle,
          targetMuscles,
          name,
        }) async {
          fetchIndex++;
          if (fetchIndex == 1) {
            return const ExerciseApiResponse(
              exercises: [sampleExercise1],
              total: 2,
              hasNextPage: true,
              nextCursor: 'cursor-page-2',
            );
          } else {
            return const ExerciseApiResponse(
              exercises: [sampleExercise2],
              total: 2,
              hasNextPage: false,
              nextCursor: null,
            );
          }
        });

        await tester.pumpWidget(createTestWidget(service));
        await tester.pumpAndSettle();

        // Page 1 is displayed
        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.text('Incline Dumbbell Press'), findsNothing);

        // Tap "Muat Lebih Banyak" button
        final loadMoreFinder = find.text('Muat Lebih Banyak');
        expect(loadMoreFinder, findsOneWidget);
        await tester.tap(loadMoreFinder);
        await tester.pumpAndSettle();

        // Verify second call requested after: 'cursor-page-2'
        expect(service.calls, 2);
        expect(
          service.recordedCalls[1]['cursor'] ??
              service.recordedCalls[1]['after'],
          'cursor-page-2',
        );

        // Both items are now present (appended, not overwritten!)
        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      },
    );

    testWidgets('shows error state and retries successfully', (tester) async {
      var shouldFail = true;
      final service = FakeExerciseApiService(({
        limit = 20,
        cursor,
        after,
        bodyPart,
        bodyParts,
        targetMuscle,
        targetMuscles,
        name,
      }) async {
        if (shouldFail) {
          throw const ApiException('Koneksi terputus');
        }
        return const ExerciseApiResponse(
          exercises: [sampleExercise1],
          total: 1,
          hasNextPage: false,
        );
      });

      await tester.pumpWidget(createTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.textContaining('Koneksi terputus'), findsOneWidget);
      final retryFinder = find.text('Coba Lagi');
      expect(retryFinder, findsOneWidget);

      shouldFail = false;
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(service.calls, 2);
    });

    testWidgets(
      'catalog filter changes server body part and resets the visible list',
      (tester) async {
        final service = FakeExerciseApiService(({
          limit = 20,
          cursor,
          after,
          bodyPart,
          bodyParts,
          targetMuscle,
          targetMuscles,
          name,
        }) async {
          return ExerciseApiResponse(
            exercises: bodyPart == 'chest'
                ? const [sampleExercise1]
                : const [sampleExercise2],
            total: 1,
            hasNextPage: false,
          );
        });
        await tester.pumpWidget(
          GetMaterialApp(home: ListAllExercisePage(apiService: service)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('body-part-filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chest').last);
        await tester.pumpAndSettle();
        expect(service.recordedCalls.last['bodyPart'], 'chest');
        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.text('Incline Dumbbell Press'), findsNothing);
      },
    );

    testWidgets('maps targetMuscles for biceps category', (tester) async {
      final service = FakeExerciseApiService(({
        limit = 20,
        cursor,
        after,
        bodyPart,
        bodyParts,
        targetMuscle,
        targetMuscles,
        name,
      }) async {
        return const ExerciseApiResponse(
          exercises: [],
          total: 0,
          hasNextPage: false,
        );
      });

      await tester.pumpWidget(createTestWidget(service, bodyPart: 'biceps'));
      await tester.pumpAndSettle();

      expect(service.recordedCalls.first['targetMuscle'], 'biceps');
    });

    testWidgets(
      'navigates to detail page showing ExerciseApiModel details, GIF preview, and standalone content',
      (tester) async {
        final service = FakeExerciseApiService(({
          limit = 20,
          cursor,
          after,
          bodyPart,
          bodyParts,
          targetMuscle,
          targetMuscles,
          name,
        }) async {
          return const ExerciseApiResponse(
            exercises: [sampleExercise1],
            total: 1,
            hasNextPage: false,
          );
        });

        await tester.pumpWidget(createTestWidget(service));
        await tester.pumpAndSettle();

        // Tap the list item
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();

        // Detail page is mounted
        expect(find.byType(DetailExercisePage), findsOneWidget);
        expect(find.byType(ExerciseGifPreview), findsOneWidget);
        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.text('Add to Workout'), findsNothing);
        expect(find.textContaining('ExerciseDB OSS'), findsWidgets);
      },
    );
  });
}
