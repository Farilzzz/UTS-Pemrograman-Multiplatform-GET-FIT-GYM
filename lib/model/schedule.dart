class ScheduleExercise {
  final String name, muscle, equipment;
  final int sets, reps;
  final double? weight;

  const ScheduleExercise({
    required this.name,
    required this.muscle,
    required this.equipment,
    required this.sets,
    required this.reps,
    this.weight,
  });

  static int _positive(String value, String label) {
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      throw FormatException('$label harus bilangan bulat positif');
    }
    return n;
  }

  factory ScheduleExercise.parse({
    required String name,
    required String muscle,
    required String equipment,
    required String sets,
    required String reps,
    required String weight,
  }) {
    if (name.trim().isEmpty) {
      throw const FormatException('Nama latihan wajib diisi');
    }
    final load = weight.trim().isEmpty ? null : double.tryParse(weight.trim());
    if (weight.trim().isNotEmpty &&
        (load == null || !load.isFinite || load < 0)) {
      throw const FormatException('Berat harus angka >= 0');
    }
    return ScheduleExercise(
      name: name.trim(),
      muscle: muscle.trim(),
      equipment: equipment.trim(),
      sets: _positive(sets, 'Sets'),
      reps: _positive(reps, 'Reps'),
      weight: load,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'muscle': muscle,
    'equipment': equipment,
    'sets': sets,
    'reps': reps,
    'weight': weight,
  };
  factory ScheduleExercise.fromMap(Map<String, dynamic> data) =>
      ScheduleExercise.parse(
        name: data['name'] as String? ?? '',
        muscle: data['muscle'] as String? ?? '',
        equipment: data['equipment'] as String? ?? '',
        sets: '${data['sets']}',
        reps: '${data['reps']}',
        weight: data['weight'] == null ? '' : '${data['weight']}',
      );
}

class WorkoutSchedule {
  final String id, name;
  final List<int> weekdays;
  final List<ScheduleExercise> exercises;

  WorkoutSchedule({
    required this.id,
    required String name,
    required List<int> weekdays,
    required List<ScheduleExercise> exercises,
  }) : name = name.trim(),
       weekdays = List.unmodifiable(weekdays),
       exercises = List.unmodifiable(exercises) {
    if (this.name.isEmpty) {
      throw const FormatException('Nama jadwal wajib diisi');
    }
    if (weekdays.isEmpty ||
        weekdays.any((d) => d < 1 || d > 7) ||
        weekdays.toSet().length != weekdays.length) {
      throw const FormatException('Pilih minimal satu hari (Senin–Minggu)');
    }
    if (exercises.isEmpty) {
      throw const FormatException('Pilih minimal satu latihan');
    }
  }

  bool occursOn(DateTime localDate) => weekdays.contains(localDate.weekday);
  Map<String, dynamic> toMap() => {
    'name': name,
    'weekdays': weekdays,
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };
  factory WorkoutSchedule.fromMap(String id, Map<String, dynamic> data) =>
      WorkoutSchedule(
        id: id,
        name: data['name'] as String? ?? '',
        weekdays: (data['weekdays'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        exercises: (data['exercises'] as List)
            .map(
              (e) =>
                  ScheduleExercise.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
}
