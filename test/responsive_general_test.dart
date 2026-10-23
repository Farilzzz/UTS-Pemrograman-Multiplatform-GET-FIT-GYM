import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/view/local_workout/exercise_picker_page.dart';
import 'package:aplikasi_gym/view/local_workout/local_workout_history_page.dart';
import 'package:aplikasi_gym/database/database_helper.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';
import 'package:aplikasi_gym/view/home/home_page.dart';
import 'package:aplikasi_gym/view/settings_page.dart';
import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:aplikasi_gym/widgets/custom_button.dart';
import 'package:aplikasi_gym/widgets/custom_textfield.dart';

class _Store extends DatabaseHelper {
  @override
  Future<List<LocalWorkoutLog>> getAllWorkoutLogs() async => [];
}

Future<void> host(WidgetTester tester, Widget page, Size size, double scale, {double keyboard = 0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: page, builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!)));
  await tester.pumpAndSettle();
}
void main() {
  tearDown(Get.reset);
  for (final size in [const Size(320,568), const Size(360,640), const Size(412,915), const Size(600,960)]) {
    for (final scale in [1.0,1.5,2.0]) {
      testWidgets('home settings access $size scale $scale', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final service = Get.put(ThemePreferenceService());
        await service.load();
        await host(tester, const HomePage(), size, scale);
        for (final label in ['Jelajahi Latihan','Jadwal & Riwayat','Pengaturan']) {
          final target = find.text(label);
          await tester.scrollUntilVisible(target, 120);
          await tester.pumpAndSettle();
          final paragraph = tester.renderObject<RenderParagraph>(target);
          expect(paragraph.didExceedMaxLines, isFalse, reason: '$label must be readable');
          expect(target.hitTestable(), findsOneWidget);
        }
        await tester.tap(find.text('Pengaturan'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(service.isDarkMode.value, isFalse);
        await tester.scrollUntilVisible(find.text('Riwayat Latihan Lokal'), 100);
        await tester.pumpAndSettle();
        expect(find.text('Riwayat Latihan Lokal').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [const Size(320,568), const Size(360,640), const Size(412,915), const Size(600,960)]) {
    for (final scale in [1.0,1.5,2.0]) {
      testWidgets('legacy picker and history keyboard $size scale $scale', (tester) async {
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details);
          oldHandler?.call(details);
        };
        final service = ExerciseApiService(client: MockClient((_) async => http.Response('{"success":true,"data":[],"meta":{"hasNextPage":false}}', 200)));
        await host(tester, ExercisePickerPage(apiService: service), size, scale, keyboard: 240);
        expect(find.byKey(const Key('pickerSearch')).hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Input manual (offline)'), 100, scrollable: find.byType(Scrollable).first);
        expect(find.text('Input manual (offline)').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        await host(tester, LocalWorkoutHistoryPage(databaseHelper: _Store(), apiService: service), size, scale);
        await tester.tap(find.text('Tambah Latihan'));
        await tester.pumpAndSettle();
        await tester.showKeyboard(find.byKey(const Key('notes')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('notes')), 'Keyboard notes');
        await tester.scrollUntilVisible(find.text('Simpan'), 100, scrollable: find.byType(Scrollable).last);
        expect(find.text('Simpan').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        service.dispose();
      });
    }
  }

  for (final size in [const Size(320,568), const Size(360,640), const Size(412,915), const Size(600,960)]) {
    for (final scale in [1.0,1.5,2.0]) {
      testWidgets('shared custom widgets $size scale $scale', (tester) async {
        final ctrl = TextEditingController(text: 'Input test');
        await host(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CustomButton(
                    text: 'Mulai Sesi Latihan Gym Beban Paling Berat Hari Ini',
                    onPressed: () {},
                    color: Colors.blue,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: ctrl,
                    hintText: 'Cari sesuatu',
                    icon: Icons.search,
                  ),
                ],
              ),
            ),
          ),
          size,
          scale,
        );
        final labelRect = tester.getRect(find.text('Mulai Sesi Latihan Gym Beban Paling Berat Hari Ini'));
        final buttonRect = tester.getRect(find.byType(ElevatedButton));
        expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
        expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
        expect(find.byType(CustomButton).hitTestable(), findsOneWidget);
        expect(find.byType(CustomTextField).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        ctrl.dispose();
      });
    }
  }
}
