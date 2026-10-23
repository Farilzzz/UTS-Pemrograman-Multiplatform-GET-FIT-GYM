import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database/database_helper.dart';
import 'service/exercise_api_service.dart';
import 'view/home/home_page.dart';

// Standalone entry point; local persistence is initialized on demand.
import 'package:aplikasi_gym/service/theme_preference_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.themeService,
    this.databaseHelper,
    this.exerciseApiService,
  });

  final ThemePreferenceService? themeService;
  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? exerciseApiService;

  @override
  Widget build(BuildContext context) {
    final theme =
        themeService ??
        (Get.isRegistered<ThemePreferenceService>()
            ? Get.find<ThemePreferenceService>()
            : Get.put<ThemePreferenceService>(
                ThemePreferenceService(),
                permanent: true,
              ));
    if (!Get.isRegistered<ThemePreferenceService>()) {
      Get.put<ThemePreferenceService>(theme, permanent: true);
    }
    return FutureBuilder<bool>(
      future: theme.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor:
                  ThemeController.darkTheme.scaffoldBackgroundColor,
              body: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return Obx(
          () => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gym App',
            theme: ThemeController.lightTheme,
            darkTheme: ThemeController.darkTheme,
            themeMode: theme.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
            home: HomePage(
              databaseHelper: databaseHelper,
              exerciseApiService: exerciseApiService,
            ),
          ),
        );
      },
    );
  }
}
