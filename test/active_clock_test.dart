import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/model/active_workout_clock.dart';

void main() {
  test(
    'paused intervals never count and repeated pause resume is idempotent',
    () {
      var now = DateTime(2026);
      final clock = ActiveWorkoutClock(now: () => now);
      now = now.add(const Duration(seconds: 12));
      clock.pause();
      now = now.add(const Duration(hours: 1));
      clock.pause();
      expect(clock.elapsed.inSeconds, 12);
      clock.resume();
      clock.resume();
      now = now.add(const Duration(seconds: 8));
      expect(clock.elapsed.inSeconds, 20);
    },
  );
}
