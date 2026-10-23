/// Counts only foreground, unpaused activity. Wall-clock time while paused is excluded.
class ActiveWorkoutClock {
  final DateTime Function() now;
  Duration _accumulated;
  DateTime? _segmentStart;

  ActiveWorkoutClock({
    required this.now,
    Duration accumulated = Duration.zero,
    bool running = true,
  }) : _accumulated = accumulated {
    if (running) _segmentStart = now();
  }

  bool get running => _segmentStart != null;
  Duration get elapsed =>
      _accumulated +
      (_segmentStart == null
          ? Duration.zero
          : now().difference(_segmentStart!));

  void pause() {
    if (_segmentStart == null) return;
    _accumulated = elapsed;
    _segmentStart = null;
  }

  void resume() {
    _segmentStart ??= now();
  }
}
