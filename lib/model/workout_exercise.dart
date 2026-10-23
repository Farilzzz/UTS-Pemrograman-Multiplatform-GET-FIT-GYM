/// Model data untuk satu gerakan latihan di dalam suatu sesi jadwal/riwayat.
/// Mendukung pemetaan ke tabel SQLite `workout_exercises`.
class WorkoutExercise {
  final int? id;
  final int? sessionId;
  final String? exerciseApiId;
  final String exerciseName;
  final String? targetMuscle;
  final String? equipment;
  final int sets;
  final int reps;
  final double weight;
  final String? notes;
  final int position;

  const WorkoutExercise({
    this.id,
    this.sessionId,
    this.exerciseApiId,
    required this.exerciseName,
    this.targetMuscle,
    this.equipment,
    required this.sets,
    required this.reps,
    this.weight = 0.0,
    this.notes,
    this.position = 0,
  });

  /// Factory untuk membuat dan memvalidasi input gerakan latihan.
  factory WorkoutExercise.fromInput({
    int? id,
    int? sessionId,
    String? exerciseApiId,
    required String exerciseName,
    String? targetMuscle,
    String? equipment,
    required String sets,
    required String reps,
    String? weight,
    String? notes,
    int position = 0,
  }) {
    final cleanName = exerciseName.trim();
    if (cleanName.isEmpty) {
      throw const FormatException('Nama gerakan latihan tidak boleh kosong.');
    }

    final parsedSets = int.tryParse(sets.trim());
    if (parsedSets == null || parsedSets <= 0) {
      throw const FormatException('Jumlah set harus berupa bilangan bulat lebih dari 0.');
    }

    final parsedReps = int.tryParse(reps.trim());
    if (parsedReps == null || parsedReps <= 0) {
      throw const FormatException('Jumlah repetisi harus berupa bilangan bulat lebih dari 0.');
    }

    double parsedWeight = 0.0;
    if (weight != null && weight.trim().isNotEmpty) {
      final w = double.tryParse(weight.trim());
      if (w == null || w < 0 || !w.isFinite) {
        throw const FormatException('Beban (weight) harus berupa angka desimal positif atau 0.');
      }
      parsedWeight = w;
    }

    return WorkoutExercise(
      id: id,
      sessionId: sessionId,
      exerciseApiId: exerciseApiId?.trim().isEmpty == true ? null : exerciseApiId?.trim(),
      exerciseName: cleanName,
      targetMuscle: targetMuscle?.trim().isEmpty == true ? null : targetMuscle?.trim(),
      equipment: equipment?.trim().isEmpty == true ? null : equipment?.trim(),
      sets: parsedSets,
      reps: parsedReps,
      weight: parsedWeight,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      position: position,
    );
  }

  /// Konversi ke Map untuk penyimpanan SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      'exercise_api_id': exerciseApiId,
      'exercise_name': exerciseName,
      'target_muscle': targetMuscle,
      'equipment': equipment,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'position': position,
    };
  }

  /// Konstruksi dari Map SQLite.
  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int?,
      exerciseApiId: map['exercise_api_id'] as String?,
      exerciseName: map['exercise_name'] as String? ?? '',
      targetMuscle: map['target_muscle'] as String?,
      equipment: map['equipment'] as String?,
      sets: (map['sets'] as num?)?.toInt() ?? 1,
      reps: (map['reps'] as num?)?.toInt() ?? 1,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      position: (map['position'] as num?)?.toInt() ?? 0,
    );
  }

  WorkoutExercise copyWith({
    int? id,
    int? sessionId,
    String? exerciseApiId,
    String? exerciseName,
    String? targetMuscle,
    String? equipment,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    int? position,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseApiId: exerciseApiId ?? this.exerciseApiId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      position: position ?? this.position,
    );
  }
}
