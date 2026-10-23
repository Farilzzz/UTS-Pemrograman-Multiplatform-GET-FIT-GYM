import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/exercise_model.dart';

void main() {
  group('ExerciseModel', () {
    test('parses live schema with equipments array and safety_info', () {
      final json = {
        'name': 'Dumbbell Shoulder Press',
        'type': 'strength',
        'muscle': 'shoulders',
        'equipments': ['dumbbell'],
        'difficulty': 'intermediate',
        'instructions': 'Hold the dumbbells at shoulder height...',
        'safety_info': 'Do not arch lower back.',
      };
      final model = ExerciseModel.fromJson(json);
      expect(model.name, 'Dumbbell Shoulder Press');
      expect(model.type, 'strength');
      expect(model.muscle, 'shoulders');
      expect(model.equipment, 'dumbbell');
      expect(model.equipments, ['dumbbell']);
      expect(model.difficulty, 'intermediate');
      expect(model.instructions, 'Hold the dumbbells at shoulder height...');
      expect(model.safetyInfo, 'Do not arch lower back.');
    });

    test('joins multiple equipments into comma-separated equipment string', () {
      final json = {
        'name': 'Bench Press',
        'equipments': ['barbell', 'bench'],
        'muscle': 'chest',
      };
      final model = ExerciseModel.fromJson(json);
      expect(model.equipment, 'barbell, bench');
      expect(model.equipments, ['barbell', 'bench']);
    });

    test('supports legacy single equipment string backwards compatibility', () {
      final json = {
        'name': 'Pushups',
        'equipment': 'body only',
        'muscle': 'chest',
      };
      final model = ExerciseModel.fromJson(json);
      expect(model.equipment, 'body only');
      expect(model.equipments, isEmpty);
    });

    test('uses robust fallbacks for missing/null fields', () {
      final model = ExerciseModel.fromJson({});
      expect(model.name, 'Unknown Exercise');
      expect(model.muscle, 'General');
      expect(model.equipment, 'Not provided');
      expect(model.equipments, isEmpty);
      expect(model.type, '');
      expect(model.difficulty, 'Unknown');
      expect(model.instructions, 'No instructions provided.');
      expect(model.safetyInfo, '');
    });
  });
}
