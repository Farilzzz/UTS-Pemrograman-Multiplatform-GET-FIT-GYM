import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';

void main() {
  test('legacy rows decode and exercise identity can retain or clear', () {
    final old = {'id': 1, 'exercise_name': 'Squat', 'sets': 4, 'reps': 10,
      'weight': 87.5, 'workout_date': '2026-10-22', 'notes': 'keep'};
    final log = LocalWorkoutLog.fromMap(old);
    expect(log.exerciseId, isNull);
    final linked = log.copyWith(exerciseId: 'api-1');
    expect(LocalWorkoutLog.fromMap(linked.toMap()).exerciseId, 'api-1');
    expect(linked.copyWith(sets: 5).exerciseId, 'api-1');
    expect(linked.copyWith(exerciseId: null).exerciseId, isNull);
    expect(linked.copyWith(exerciseName: 'Manual').exerciseId, isNull);
    expect(LocalWorkoutLog.fromInput(exerciseId: 'api-2', exerciseName: 'Press',
      sets: '2', reps: '8', weight: '0', workoutDate: '2026-10-22').exerciseId, 'api-2');
  });
}
