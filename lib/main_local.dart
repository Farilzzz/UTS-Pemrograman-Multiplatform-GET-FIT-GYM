import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database/database_helper.dart';
import 'service/theme_preference_service.dart';
import 'view/local_workout/local_workout_history_page.dart';
import 'view/settings_page.dart';

/// Standalone QA entry point for local persistence testing.
/// Standalone QA entry point; it uses only on-device persistence.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = Get.put<ThemePreferenceService>(
    ThemePreferenceService(),
    permanent: true,
  );
  await themeService.load();
  runApp(const LocalQaApp());
}

class LocalQaApp extends StatelessWidget {
  final ThemePreferenceService? themeService;
  final DatabaseHelper? databaseHelper;

  const LocalQaApp({super.key, this.themeService, this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    final service =
        themeService ??
        (Get.isRegistered<ThemePreferenceService>()
            ? Get.find<ThemePreferenceService>()
            : Get.put<ThemePreferenceService>(
                ThemePreferenceService(),
                permanent: true,
              ));

    return FutureBuilder<bool>(
      future: service.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !service.isInitialized.value) {
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
            title: 'Gym App Local QA',
            theme: ThemeController.lightTheme,
            darkTheme: ThemeController.darkTheme,
            themeMode: service.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
            home: LocalQaShell(
              themeService: service,
              databaseHelper: databaseHelper,
            ),
          ),
        );
      },
    );
  }
}

class LocalQaShell extends StatefulWidget {
  final ThemePreferenceService themeService;
  final DatabaseHelper? databaseHelper;

  const LocalQaShell({
    super.key,
    required this.themeService,
    this.databaseHelper,
  });

  @override
  State<LocalQaShell> createState() => _LocalQaShellState();
}

class _LocalQaShellState extends State<LocalQaShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LocalWorkoutHistoryPage(databaseHelper: widget.databaseHelper),
      SettingsPage(service: widget.themeService),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            key: Key('local_qa_history_tab'),
            icon: Icon(Icons.fitness_center),
            label: 'Latihan Lokal',
          ),
          BottomNavigationBarItem(
            key: Key('local_qa_settings_tab'),
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
