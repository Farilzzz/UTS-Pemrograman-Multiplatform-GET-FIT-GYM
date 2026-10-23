import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/view/workout/list_all_exercise_page.dart';
import 'package:aplikasi_gym/view/workout/detail_exercise_page.dart';
import 'package:aplikasi_gym/view/widgets/exercise_gif_preview.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:get/get.dart';

// Explicit offline fixture: this is not evidence of a live API response.
ExerciseApiService fixtureService({bool error = false, bool empty = false}) =>
    ExerciseApiService(client: MockClient((request) async {
      if (error) return http.Response('offline fixture', 503);
      return http.Response(jsonEncode({
        'success': true,
        'data': empty ? [] : [{
          'exerciseId': 'fixture-1',
          'name': 'bench press with a deliberately long descriptive name',
          'bodyParts': ['chest'],
          'targetMuscles': ['pectorals'],
          'equipments': ['barbell'],
          'gifUrl': '',
          'instructions': ['Raise slowly and lower with control.'],
        }],
        'meta': {'total': empty ? 0 : 1, 'hasNextPage': false},
      }), 200);
    }));

Future<void> mount(WidgetTester tester, Widget page, Size size, double scale,
    {bool keyboard = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard ? 280 : 0);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: page,
  ));
  await tester.pumpAndSettle();
}

const fixtureExercise = ExerciseApiModel(
  exerciseId: 'fixture-1',
  name: 'barbell incline bench press with a deliberately long title',
  bodyParts: ['chest'],
  targetMuscles: ['upper pectorals'],
  equipments: ['olympic barbell with bumper plates'],
  gifUrl: '',
  secondaryMuscles: ['front deltoids', 'triceps brachii'],
  instructions: [
    'Lie on an incline bench and brace your feet flat against the floor.',
    'Lower the bar slowly to the upper chest and press it back with control.',
  ],
);

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('catalog error stays scrollable with keyboard at 320 text 2', (tester) async {
    final service = fixtureService(error: true);
    addTearDown(service.dispose);
    await mount(tester, ListAllExercisePage(apiService: service, isPickerMode: true),
        const Size(320, 568), 2, keyboard: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog empty state stays scrollable with keyboard at 320 text 2', (tester) async {
    final service = fixtureService(empty: true);
    addTearDown(service.dispose);
    await mount(tester, ListAllExercisePage(apiService: service),
        const Size(320, 568), 2, keyboard: true);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada data latihan'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(360, 640), const Size(412, 915), const Size(600, 960)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('catalog list is overflow-free at ${size.width}x${size.height} scale $scale', (tester) async {
        final service = fixtureService();
        addTearDown(service.dispose);
        await mount(tester, ListAllExercisePage(apiService: service), size, scale);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Bench Press'), findsOneWidget);
      });

      testWidgets('keyboard catalog at ${size.width}x${size.height} scale $scale', (tester) async {
        final service = fixtureService();
        addTearDown(service.dispose);
        await mount(tester, ListAllExercisePage(apiService: service), size, scale, keyboard: true);
        await tester.enterText(find.byType(TextField), 'bench');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(find.textContaining('Bench Press'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('keyboard detail at ${size.width}x${size.height} scale $scale', (tester) async {
        await mount(tester, DetailExercisePage(apiExercise: fixtureExercise), size, scale, keyboard: true);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Read More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Read More'));
        await tester.pumpAndSettle();
        expect(find.text('Read Less'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('detail is overflow-free at ${size.width}x${size.height} scale $scale', (tester) async {
        await mount(tester, DetailExercisePage(apiExercise: fixtureExercise), size, scale);
        expect(tester.takeException(), isNull);
        expect(find.text(fixtureExercise.formattedName), findsOneWidget);
        await tester.ensureVisible(find.text('Read More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Read More'));
        await tester.pumpAndSettle();
        expect(find.text('Read Less'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('catalog active search is overflow-free with keyboard at 320 text 1.5', (tester) async {
    final service = fixtureService();
    addTearDown(service.dispose);
    await mount(tester, ListAllExercisePage(apiService: service),
        const Size(320, 568), 1.5, keyboard: true);
    await tester.enterText(find.byType(TextField), 'incline');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('GIF placeholder is overflow-free at compact constraint and text 2', (tester) async {
    await mount(tester, const Center(child: SizedBox(width: 40, height: 40,
      child: ExerciseGifPreview(gifUrl: ''))), const Size(320, 568), 2);
    expect(tester.takeException(), isNull);
  });
}
