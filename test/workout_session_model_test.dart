import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/workout_session.dart';
import 'package:aplikasi_gym/model/workout_exercise.dart';

void main() {
  group('WorkoutExercise Model Tests', () {
    test('WorkoutExercise serialization toMap and fromMap', () {
      const exercise = WorkoutExercise(
        id: 10,
        sessionId: 1,
        exerciseApiId: '0CXGHya',
        exerciseName: 'Bench Press',
        targetMuscle: 'Pectorals',
        equipment: 'Barbell',
        sets: 3,
        reps: 12,
        weight: 60.0,
        notes: 'Grip medium, jaga tempo',
        position: 0,
      );

      final map = exercise.toMap();
      expect(map['id'], 10);
      expect(map['session_id'], 1);
      expect(map['exercise_api_id'], '0CXGHya');
      expect(map['exercise_name'], 'Bench Press');
      expect(map['target_muscle'], 'Pectorals');
      expect(map['equipment'], 'Barbell');
      expect(map['sets'], 3);
      expect(map['reps'], 12);
      expect(map['weight'], 60.0);
      expect(map['notes'], 'Grip medium, jaga tempo');
      expect(map['position'], 0);

      final decoded = WorkoutExercise.fromMap(map);
      expect(decoded.id, 10);
      expect(decoded.sessionId, 1);
      expect(decoded.exerciseApiId, '0CXGHya');
      expect(decoded.exerciseName, 'Bench Press');
      expect(decoded.targetMuscle, 'Pectorals');
      expect(decoded.equipment, 'Barbell');
      expect(decoded.sets, 3);
      expect(decoded.reps, 12);
      expect(decoded.weight, 60.0);
      expect(decoded.notes, 'Grip medium, jaga tempo');
      expect(decoded.position, 0);
    });

    test('WorkoutExercise copyWith handles partial updates correctly', () {
      const exercise = WorkoutExercise(
        sessionId: 1,
        exerciseName: 'Incline Press',
        sets: 3,
        reps: 10,
        weight: 50.0,
      );

      final updated = exercise.copyWith(
        id: 99,
        weight: 55.0,
        notes: 'Naik beban 5kg',
      );

      expect(updated.id, 99);
      expect(updated.sessionId, 1);
      expect(updated.exerciseName, 'Incline Press');
      expect(updated.sets, 3);
      expect(updated.reps, 10);
      expect(updated.weight, 55.0);
      expect(updated.notes, 'Naik beban 5kg');
    });
  });

  group('WorkoutSession Model Tests', () {
    test('WorkoutSession serialization toMap and fromMap with child exercises', () {
      final session = WorkoutSession(
        id: 5,
        title: 'Push Day',
        scheduledDate: '2026-10-23',
        status: 'planned',
        createdAt: '2026-10-23T08:00:00Z',
        exercises: const [
          WorkoutExercise(
            id: 1,
            sessionId: 5,
            exerciseName: 'Bench Press',
            sets: 3,
            reps: 12,
            weight: 60.0,
            position: 0,
          ),
          WorkoutExercise(
            id: 2,
            sessionId: 5,
            exerciseName: 'Incline Press',
            sets: 3,
            reps: 10,
            weight: 50.0,
            position: 1,
          ),
          WorkoutExercise(
            id: 3,
            sessionId: 5,
            exerciseName: 'Triceps Pushdown',
            sets: 3,
            reps: 12,
            weight: 25.0,
            position: 2,
          ),
        ],
      );

      expect(session.isPlanned, isTrue);
      expect(session.isCompleted, isFalse);
      expect(session.statusLabel, 'Direncanakan');
      expect(session.exerciseCount, 3);

      final map = session.toMap();
      expect(map['id'], 5);
      expect(map['title'], 'Push Day');
      expect(map['scheduled_date'], '2026-10-23');
      expect(map['status'], 'planned');
      expect(map['created_at'], '2026-10-23T08:00:00Z');
      expect(map['completed_at'], isNull);

      final decoded = WorkoutSession.fromMap(map, exercises: session.exercises);
      expect(decoded.id, 5);
      expect(decoded.title, 'Push Day');
      expect(decoded.scheduledDate, '2026-10-23');
      expect(decoded.status, 'planned');
      expect(decoded.exercises.length, 3);
      expect(decoded.exercises[0].exerciseName, 'Bench Press');
      expect(decoded.exercises[1].exerciseName, 'Incline Press');
      expect(decoded.exercises[2].exerciseName, 'Triceps Pushdown');
    });

    test('WorkoutSession status transitions and completed state', () {
      final session = WorkoutSession(
        id: 7,
        title: 'Leg Day',
        scheduledDate: '2026-10-24',
        status: 'completed',
        createdAt: '2026-10-23T10:00:00Z',
        completedAt: '2026-10-24T11:30:00Z',
      );

      expect(session.isPlanned, isFalse);
      expect(session.isCompleted, isTrue);
      expect(session.statusLabel, 'Selesai');
      expect(session.completedAt, '2026-10-24T11:30:00Z');
    });
  });
}
