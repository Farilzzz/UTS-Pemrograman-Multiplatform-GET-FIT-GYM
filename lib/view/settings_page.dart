import 'package:aplikasi_gym/service/theme_preference_service.dart';
import 'package:aplikasi_gym/view/local_workout/local_workout_history_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.service});

  final ThemePreferenceService? service;

  @override
  Widget build(BuildContext context) {
    final preferences = service ?? Get.find<ThemePreferenceService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Obx(
              () => SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  preferences.isSaving.value
                      ? 'Saving preference…'
                      : 'Saved on this device (SharedPreferences)',
                ),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: preferences.isDarkMode.value,
                onChanged: preferences.isSaving.value
                    ? null
                    : (value) async {
                        final saved = await preferences.setDarkMode(value);
                        if (!context.mounted) return;
                        if (!saved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to save theme. Please try again.',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
          Obx(
            () => preferences.loadFailed.value
                ? const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Could not read the saved theme. Using Dark Mode until a new preference is saved.',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const Text('Display preference only. Workout weights remain in kg.'),
          const SizedBox(height: 24),
          Text(
            'Data Persistence (UTS)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.storage_outlined,
                color: Color(0xFF00D7E6),
              ),
              title: const Text('Riwayat Latihan Lokal'),
              subtitle: const Text('Tersimpan di SQLite (lokal di perangkat)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.to(() => const LocalWorkoutHistoryPage()),
            ),
          ),
        ],
      ),
    );
  }
}
