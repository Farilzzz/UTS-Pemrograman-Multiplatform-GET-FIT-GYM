import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingThemePreferenceStore implements ThemePreferenceStore {
  @override
  Future<bool?> readDarkMode() async => null;

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await SharedPreferences.getInstance().then((prefs) => prefs.clear());
  });

  test('loads dark mode by default from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ThemePreferenceService();

    expect(await service.load(), isTrue);
    expect(service.isDarkMode.value, isTrue);
    expect(service.isInitialized.value, isTrue);
  });

  test('loads the saved light preference from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({
      ThemePreferenceService.preferenceKey: false,
    });
    final service = ThemePreferenceService();

    expect(await service.load(), isFalse);
    expect(service.isDarkMode.value, isFalse);
  });

  test('saves a preference that a new service can read', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ThemePreferenceService();

    expect(await service.setDarkMode(false), isTrue);

    final reloadedService = ThemePreferenceService();
    expect(await reloadedService.load(), isFalse);
  });

  test('reports a failed write and restores the previous theme', () async {
    final service = ThemePreferenceService(
      store: _FailingThemePreferenceStore(),
    );
    await service.load();

    expect(await service.setDarkMode(false), isFalse);
    expect(service.isDarkMode.value, isTrue);
    expect(service.lastSaveSucceeded.value, isFalse);
  });
}
