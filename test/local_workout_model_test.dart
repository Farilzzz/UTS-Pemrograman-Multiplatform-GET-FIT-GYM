import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/local_workout_log.dart';

void main() {
  test('round trips every SQLite column without fabricating missing data', () {
    const log = LocalWorkoutLog(
      id: 3,
      exerciseName: "Farmer's walk",
      sets: 3,
      reps: 12,
      weight: 0,
      workoutDate: '2026-10-22',
      notes: 'Slow',
    );
    expect(LocalWorkoutLog.fromMap(log.toMap()).toMap(), log.toMap());
    expect(() => LocalWorkoutLog.fromMap({}), throwsFormatException);
  });

  test('validates actual calendar date and numeric boundaries', () {
    LocalWorkoutLog parse({
      String name = ' Squat ',
      String sets = '3',
      String reps = '12',
      String weight = '0',
      String date = '2026-10-22',
    }) => LocalWorkoutLog.fromInput(
      exerciseName: name,
      sets: sets,
      reps: reps,
      weight: weight,
      workoutDate: date,
      notes: ' note ',
    );
    expect(parse().exerciseName, 'Squat');
    expect(parse().notes, 'note');
    expect(parse(weight: '2.5').weight, 2.5);
    for (final invalid in ['', '0', '-1', '2.5', 'abc']) {
      expect(() => parse(sets: invalid), throwsFormatException);
      expect(() => parse(reps: invalid), throwsFormatException);
    }
    for (final invalid in ['', '-1', 'NaN', 'Infinity', 'abc']) {
      expect(() => parse(weight: invalid), throwsFormatException);
    }
    for (final date in ['', '2026-02-30', '2026-13-01', '22/10/2026']) {
      expect(() => parse(date: date), throwsFormatException);
    }
    expect(() => parse(name: ' '), throwsFormatException);
  });
}
