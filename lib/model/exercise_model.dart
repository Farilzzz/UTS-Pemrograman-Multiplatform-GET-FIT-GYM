class ExerciseModel {
  final String name;
  final String muscle;
  final String equipment;
  final List<String> equipments;
  final String type;
  final String difficulty;
  final String instructions;
  final String safetyInfo;
  final List<String> images;

  static bool _isNetworkImage(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  const ExerciseModel({
    required this.name,
    required this.muscle,
    required this.equipment,
    this.equipments = const [],
    this.type = '',
    required this.difficulty,
    required this.instructions,
    this.safetyInfo = '',
    this.images = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    String text(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty
          ? value.trim()
          : fallback;
    }

    final raw = json['equipments'];
    final equipments = raw is List
        ? raw
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final legacy = text('equipment', '');
    return ExerciseModel(
      name: text('name', 'Unknown Exercise'),
      muscle: text('muscle', 'General'),
      equipment: equipments.isNotEmpty
          ? equipments.join(', ')
          : (legacy.isEmpty ? 'Not provided' : legacy),
      equipments: equipments,
      type: text('type', ''),
      difficulty: text('difficulty', 'Unknown'),
      instructions: text('instructions', 'No instructions provided.'),
      safetyInfo: text('safety_info', ''),
      images: json['images'] is List
          ? List.unmodifiable(
              (json['images'] as List)
                  .whereType<String>()
                  .map((s) => s.trim())
                  .where(_isNetworkImage),
            )
          : const [],
    );
  }
}
