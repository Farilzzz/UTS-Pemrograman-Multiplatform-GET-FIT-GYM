import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/view/local_workout/exercise_picker_page.dart';

void main() {
  testWidgets('picker selects model, searches and filters server pages with retry', (tester) async {
    final requests = <Uri>[];
    bool fail = false;
    final service = ExerciseApiService(client: MockClient((r) async {
      requests.add(r.url);
      if (fail) return http.Response('offline', 503);
      final next = r.url.queryParameters['after'] != null;
      return http.Response(jsonEncode({'success': true, 'data': [
        {'exerciseId': next ? '2' : '1', 'name': next ? 'curl' : 'press'}
      ], 'meta': {'total': 2, 'hasNextPage': !next, 'nextCursor': next ? null : 'next'}}), 200);
    }));
    ExerciseApiModel? selected;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () async { final result = await Navigator.push<ExercisePickerResult>(context, MaterialPageRoute(builder: (_) => ExercisePickerPage(apiService: service))); selected = result?.exercise; }, child: const Text('open'))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
    expect(find.text('No Animation'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pickerSearch')), 'curl');
    await tester.testTextInput.receiveAction(TextInputAction.search); await tester.pumpAndSettle();
    expect(requests.last.queryParameters['name'], 'curl');
    await tester.tap(find.byKey(const Key('pickerMuscle'))); await tester.pumpAndSettle();
    await tester.tap(find.text('biceps').last); await tester.pumpAndSettle();
    expect(requests.last.queryParameters['targetMuscles'], 'biceps');
    fail = true;
    await tester.tap(find.text('Muat lagi')); await tester.pumpAndSettle();
    expect(find.text('Press'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Coba Lagi')); await tester.pumpAndSettle();
    expect(requests.last.queryParameters['after'], 'next');
    await tester.tap(find.text('Curl')); await tester.pumpAndSettle();
    expect(selected?.exerciseId, '2');
  });
  testWidgets('initial error retries and manual fallback is explicit', (tester) async {
    int calls = 0;
    final service = ExerciseApiService(client: MockClient((r) async { calls++; return http.Response('', 503); }));
    await tester.pumpWidget(MaterialApp(home: ExercisePickerPage(apiService: service)));
    await tester.pumpAndSettle();
    expect(find.text('Input manual (offline)'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi')); await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
