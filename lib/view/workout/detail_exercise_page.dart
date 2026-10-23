import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasi_gym/model/exercise_model.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/view/widgets/exercise_gif_preview.dart';

class DetailExercisePage extends StatelessWidget {
  final dynamic exercise;
  final ExerciseApiModel? apiExercise;
  final RxBool isExpanded = false.obs;

  DetailExercisePage({super.key, this.exercise, this.apiExercise})
    : assert(
        exercise != null || apiExercise != null,
        'Either exercise or apiExercise must be provided',
      );

  ExerciseApiModel? get _effectiveApi =>
      apiExercise ??
      (exercise is ExerciseApiModel ? exercise as ExerciseApiModel : null);

  ExerciseModel get _effectiveModel {
    if (exercise is ExerciseModel) return exercise as ExerciseModel;
    if (_effectiveApi != null) return _effectiveApi!.toExerciseModel();
    return const ExerciseModel(
      name: 'Unknown Exercise',
      muscle: 'General',
      equipment: 'Not provided',
      difficulty: 'Unknown',
      instructions: 'No instructions provided.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF1C1C1E)
        : theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : theme.cardColor;
    final accentColor = theme.colorScheme.primary != Colors.transparent
        ? theme.colorScheme.primary
        : const Color(0xFF00F0FF);

    final api = _effectiveApi;
    final model = _effectiveModel;
    final displayName = api?.formattedName ?? model.name;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Detail Latihan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: _exerciseVisual(),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          accentColor,
                          model.difficulty,
                          constraints.maxWidth,
                        ),
                        _buildBadge(
                          Colors.orange,
                          model.equipment,
                          constraints.maxWidth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildInfoRow("Target", api?.primaryTarget ?? model.muscle),
                  if (api != null && api.bodyParts.isNotEmpty)
                    _buildInfoRow("Bagian", api.primaryBodyPart),
                  if (model.type.isNotEmpty) _buildInfoRow("Tipe", model.type),
                  if (api != null && api.secondaryMuscles.isNotEmpty)
                    _buildInfoRow(
                      "Otot Sekunder",
                      api.secondaryMuscles.join(', '),
                    ),
                  if (model.safetyInfo.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      "Catatan Keamanan:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      model.safetyInfo,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  const Text(
                    "Cara Melakukan (sumber API):",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.instructions,
                            textAlign: TextAlign.justify,
                            maxLines: isExpanded.value ? null : 4,
                            overflow: isExpanded.value
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => isExpanded.toggle(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    isExpanded.value ? "Read Less" : "Read More",
                                    textAlign: TextAlign.end,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded.value
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Data dan media animasi disediakan oleh ExerciseDB OSS / AscendAPI untuk tujuan edukasi.",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseVisual() {
    final api = _effectiveApi;
    if (api != null && api.gifUrl.isNotEmpty) {
      return ExerciseGifPreview(
        gifUrl: api.gifUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.contain,
      );
    }

    final model = _effectiveModel;
    if (model.images.isEmpty) {
      return const Center(
        child: Icon(Icons.fitness_center, size: 96, color: Colors.grey),
      );
    }

    return PageView.builder(
      itemCount: model.images.length,
      itemBuilder: (_, index) => Image.network(
        model.images[index],
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
              ),
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/gym_logo.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(": ", style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(Color color, String text, double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
