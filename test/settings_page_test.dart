import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:aplikasi_gym/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingStore implements ThemePreferenceStore {
  @override
  Future<bool?> readDarkMode() async => null;

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async => false;
}

class _ThrowingReadStore implements ThemePreferenceStore {
  @override
  Future<bool?> readDarkMode() async => throw Exception('disk error');

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async => true;
}

void main() {
  tearDown(() async {
    Get.reset();
    await SharedPreferences.getInstance().then((prefs) => prefs.clear());
  });

  testWidgets('settings saves light mode and updates application brightness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = ThemePreferenceService();
    await service.load();
    await tester.pumpWidget(
      Obx(
        () => MaterialApp(
          theme: ThemeController.lightTheme,
          darkTheme: ThemeController.darkTheme,
          themeMode: service.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          home: SettingsPage(service: service),
        ),
      ),
    );
    expect(find.text('Dark Mode'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(service.isDarkMode.value, isFalse);
    expect(
      Theme.of(tester.element(find.byType(Switch))).brightness,
      Brightness.light,
    );
    expect(
      (await SharedPreferences.getInstance()).getBool(
        ThemePreferenceService.preferenceKey,
      ),
      isFalse,
    );
  });

  testWidgets('shows snackbar when saving theme fails', (tester) async {
    final service = ThemePreferenceService(store: _FailingStore());
    await service.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(service: service)),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to save theme. Please try again.'),
      findsOneWidget,
    );
    expect(service.isDarkMode.value, isTrue);
  });

  testWidgets('shows warning text when loading theme fails', (tester) async {
    final service = ThemePreferenceService(store: _ThrowingReadStore());
    await service.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(service: service)),
      ),
    );

    expect(
      find.textContaining('Could not read the saved theme'),
      findsOneWidget,
    );
    expect(service.isDarkMode.value, isTrue);
  });
}
