import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemePreferenceStore {
  Future<bool?> readDarkMode();
  Future<bool> writeDarkMode(bool isDarkMode);
}

class SharedPreferencesThemeStore implements ThemePreferenceStore {
  @override
  Future<bool?> readDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(ThemePreferenceService.preferenceKey);
  }

  @override
  Future<bool> writeDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(ThemePreferenceService.preferenceKey, isDarkMode);
  }
}

/// Device-local display preference only; never stores authentication or cloud data.
class ThemePreferenceService extends GetxService {
  ThemePreferenceService({ThemePreferenceStore? store})
    : _store = store ?? SharedPreferencesThemeStore();

  static const preferenceKey = 'getfit_theme_is_dark';
  final ThemePreferenceStore _store;

  final RxBool isDarkMode = true.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool lastSaveSucceeded = true.obs;
  final RxBool loadFailed = false.obs;

  Future<bool>? _loadFuture;

  /// Membaca preferensi tema secara asinkron; di-memoize untuk menghindari duplicate read.
  Future<bool> load() => _loadFuture ??= _read();

  Future<bool> _read() async {
    try {
      final savedDark = await _store.readDarkMode();
      isDarkMode.value = savedDark ?? true;
      loadFailed.value = false;
    } catch (e) {
      debugPrint('Error memuat SharedPreferences tema: $e');
      loadFailed.value = true;
    } finally {
      isInitialized.value = true;
    }
    return isDarkMode.value;
  }

  /// Backward-compatible method name for existing callers
  Future<bool> loadThemePreference() => load();

  /// Menyimpan preferensi tema ke SharedPreferences. Mengembalikan true jika sukses.
  Future<bool> setDarkMode(bool value) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      await load();
      final saved = await _store.writeDarkMode(value);
      lastSaveSucceeded.value = saved;
      if (saved) {
        isDarkMode.value = value;
      }
      return saved;
    } catch (e) {
      debugPrint('Error menyimpan SharedPreferences tema: $e');
      lastSaveSucceeded.value = false;
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Backward-compatible toggle method that updates Get.changeThemeMode when successful
  Future<void> toggleTheme(bool value) async {
    final success = await setDarkMode(value);
    if (success) {
      Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    }
  }
}

/// Service dan Controller untuk mengelola preferensi tema aplikasi (Dark Mode / Light Mode)
class ThemeController extends ThemePreferenceService {
  ThemeController({super.store});

  /// Definisi Dark Theme (Identitas Asli GET FIT GYM)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      primaryColor: const Color(0xFF00F0FF),
      cardColor: const Color(0xFF2C2C2E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F0FF),
        secondary: Color(0xFF00F0FF),
        surface: Color(0xFF2C2C2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        selectedItemColor: Color(0xFF00F0FF),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  /// Definisi Light Theme (Versi Terang Bersih & Kontras)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      primaryColor: const Color(0xFF00A8B5),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00A8B5),
        secondary: Color(0xFF00A8B5),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF00A8B5),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
