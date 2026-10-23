import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/model/exercise_model.dart';

void main() {
  group('ExerciseApiModel', () {
    test('parses full ExerciseDB OSS JSON schema', () {
      final json = {
        'exerciseId': '01qpYSe',
        'name': 'upward facing dog',
        'gifUrl': 'https://static.exercisedb.dev/media/01qpYSe.gif',
        'bodyParts': ['back'],
        'equipments': ['bodyweight'],
        'targetMuscles': ['erector spinae'],
        'secondaryMuscles': ['deltoids', 'pectorals'],
        'instructions': [
          'Step:1 Lie face down on the mat.',
          'Step:2 Push through hands and arch back upwards.',
        ],
      };

      final model = ExerciseApiModel.fromJson(json);

      expect(model.exerciseId, '01qpYSe');
      expect(model.name, 'upward facing dog');
      expect(model.formattedName, 'Upward Facing Dog');
      expect(model.gifUrl, 'https://static.exercisedb.dev/media/01qpYSe.gif');
      expect(model.bodyParts, ['back']);
      expect(model.equipments, ['bodyweight']);
      expect(model.targetMuscles, ['erector spinae']);
      expect(model.secondaryMuscles, ['deltoids', 'pectorals']);
      expect(model.instructions, hasLength(2));
      expect(model.primaryTarget, 'Erector spinae');
      expect(model.primaryBodyPart, 'Back');
      expect(model.primaryEquipment, 'Bodyweight');
    });

    test('handles missing, null, or empty fields with safe fallbacks', () {
      final model = ExerciseApiModel.fromJson(const {});

      expect(model.exerciseId, isEmpty);
      expect(model.name, 'Unnamed Exercise');
      expect(model.formattedName, 'Unnamed Exercise');
      expect(model.gifUrl, isEmpty);
      expect(model.bodyParts, isEmpty);
      expect(model.equipments, isEmpty);
      expect(model.targetMuscles, isEmpty);
      expect(model.secondaryMuscles, isEmpty);
      expect(model.instructions, isEmpty);
      expect(model.primaryTarget, 'General');
      expect(model.primaryBodyPart, 'All Body');
      expect(model.primaryEquipment, 'Bodyweight');
    });

    test('serializes to JSON accurately', () {
      const model = ExerciseApiModel(
        exerciseId: 'test-123',
        name: 'cable crossover',
        gifUrl: 'https://static.exercisedb.dev/media/0CXGHya.gif',
        bodyParts: ['chest'],
        equipments: ['cable'],
        targetMuscles: ['pectorals'],
        secondaryMuscles: ['shoulders'],
        instructions: ['Stand between cables.'],
      );

      final map = model.toJson();
      expect(map['exerciseId'], 'test-123');
      expect(map['name'], 'cable crossover');
      expect(map['gifUrl'], 'https://static.exercisedb.dev/media/0CXGHya.gif');
      expect(map['bodyParts'], ['chest']);
      expect(map['equipments'], ['cable']);
      expect(map['targetMuscles'], ['pectorals']);
      expect(map['secondaryMuscles'], ['shoulders']);
      expect(map['instructions'], ['Stand between cables.']);
    });

    test(
      'converts cleanly to ExerciseModel for legacy caller interoperability',
      () {
        const model = ExerciseApiModel(
          exerciseId: 'test-999',
          name: 'dumbbell bench press',
          gifUrl: 'https://static.exercisedb.dev/media/test.gif',
          bodyParts: ['chest'],
          equipments: ['dumbbell', 'bench'],
          targetMuscles: ['pectorals'],
          secondaryMuscles: ['triceps'],
          instructions: ['Lie on bench', 'Press dumbbells up'],
        );

        final legacy = model.toExerciseModel();
        expect(legacy, isA<ExerciseModel>());
        expect(legacy.name, 'Dumbbell Bench Press');
        expect(legacy.muscle, 'pectorals');
        expect(legacy.equipment, 'dumbbell, bench');
        expect(legacy.equipments, ['dumbbell', 'bench']);
        expect(legacy.images, ['https://static.exercisedb.dev/media/test.gif']);
        expect(
          legacy.instructions,
          contains('Lie on bench\nPress dumbbells up'),
        );
      },
    );
  });
}
