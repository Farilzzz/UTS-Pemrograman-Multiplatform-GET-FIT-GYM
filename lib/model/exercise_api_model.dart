import 'package:aplikasi_gym/model/exercise_model.dart';

class ExerciseApiModel {
  final String exerciseId;
  final String name;
  final String gifUrl;
  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  const ExerciseApiModel({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    required this.bodyParts,
    required this.equipments,
    required this.targetMuscles,
    required this.secondaryMuscles,
    required this.instructions,
  });

  factory ExerciseApiModel.fromJson(Map<String, dynamic> json) {
    return ExerciseApiModel(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Exercise',
      gifUrl: json['gifUrl'] as String? ?? '',
      bodyParts: _parseStringList(json['bodyParts']),
      equipments: _parseStringList(json['equipments']),
      targetMuscles: _parseStringList(json['targetMuscles']),
      secondaryMuscles: _parseStringList(json['secondaryMuscles']),
      instructions: _parseStringList(json['instructions']),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'gifUrl': gifUrl,
      'bodyParts': bodyParts,
      'equipments': equipments,
      'targetMuscles': targetMuscles,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
    };
  }

  String get formattedName {
    if (name.isEmpty || name == 'Unnamed Exercise') return 'Unnamed Exercise';
    return name
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String get primaryTarget {
    if (targetMuscles.isNotEmpty) {
      final t = targetMuscles.first;
      return t.isEmpty ? 'General' : '${t[0].toUpperCase()}${t.substring(1)}';
    }
    return 'General';
  }

  String get primaryBodyPart {
    if (bodyParts.isNotEmpty) {
      final b = bodyParts.first;
      return b.isEmpty ? 'All Body' : '${b[0].toUpperCase()}${b.substring(1)}';
    }
    return 'All Body';
  }

  String get primaryEquipment {
    if (equipments.isNotEmpty) {
      final e = equipments.first;
      return e.isEmpty
          ? 'Bodyweight'
          : '${e[0].toUpperCase()}${e.substring(1)}';
    }
    return 'Bodyweight';
  }

  ExerciseModel toExerciseModel() {
    return ExerciseModel(
      name: formattedName,
      muscle: primaryTarget.toLowerCase(),
      equipment: equipments.isNotEmpty
          ? equipments.join(', ')
          : primaryEquipment.toLowerCase(),
      equipments: equipments,
      difficulty: 'intermediate',
      instructions: instructions.isNotEmpty
          ? instructions.join('\n')
          : 'No instructions provided.',
      images: gifUrl.isNotEmpty ? [gifUrl] : const [],
    );
  }
}
