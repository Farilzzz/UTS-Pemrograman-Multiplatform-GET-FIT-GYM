import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/database/database_helper.dart';

import 'package:aplikasi_gym/view/workout/list_all_exercise_page.dart';
import 'package:aplikasi_gym/view/schedule/schedule_history_page.dart';
import 'package:aplikasi_gym/view/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.databaseHelper, this.exerciseApiService});

  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? exerciseApiService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "GET FIT",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Selamat Datang!",
                        style: TextStyle(
                          fontSize: 28,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pengaturan',
                  onPressed: () => Get.to(() => const SettingsPage()),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Text(
              "Mulai Latihan Anda",
              style: TextStyle(
                fontSize: 20,
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildMenuCard(
              context,
              "Jelajahi Latihan",
              Icons.fitness_center,
              () => Get.to(
                () => ListAllExercisePage(apiService: exerciseApiService),
              ),
            ),

            _buildMenuCard(
              context,
              "Jadwal & Riwayat",
              Icons.event_note,
              () => Get.to(
                () => ScheduleHistoryPage(
                  databaseHelper: databaseHelper,
                  apiService: exerciseApiService,
                ),
              ),
            ),

            _buildMenuCard(
              context,
              "Pengaturan",
              Icons.palette_outlined,
              () => Get.to(() => const SettingsPage()),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
