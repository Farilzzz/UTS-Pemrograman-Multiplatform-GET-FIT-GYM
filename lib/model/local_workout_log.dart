/// Model data untuk catatan latihan lokal (SQLite)
/// Mengikuti standar materi BAB 3 Data Persistence SQLite (toMap & fromMap)
class LocalWorkoutLog {
  static const Object _unset = Object();
  final int? id;
  final String? exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;
  final String workoutDate; // Format ISO 8601 string
  final String? notes;

  const LocalWorkoutLog({
    this.id,
    this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.workoutDate,
    this.notes,
  });

  static String? validateName(String? value) =>
      value == null || value.trim().isEmpty ? 'Nama latihan wajib diisi' : null;

  static String? validatePositiveInteger(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0
        ? 'Masukkan bilangan bulat lebih dari 0'
        : null;
  }

  static String? validateWeight(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || !parsed.isFinite || parsed < 0
        ? 'Masukkan berat valid (kg, minimal 0)'
        : null;
  }

  static String? validateDate(String? value) {
    final text = value?.trim() ?? '';
    final parsed = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)
        ? DateTime.tryParse(text)
        : null;
    return parsed == null || parsed.toIso8601String().substring(0, 10) != text
        ? 'Tanggal tidak valid (yyyy-MM-dd)'
        : null;
  }

  factory LocalWorkoutLog.fromInput({
    int? id,
    required String exerciseName,
    required String sets,
    required String reps,
    required String weight,
    required String workoutDate,
    String? notes,
    String? exerciseId,
  }) {
    if (validateName(exerciseName) != null ||
        validatePositiveInteger(sets) != null ||
        validatePositiveInteger(reps) != null ||
        validateWeight(weight) != null ||
        validateDate(workoutDate) != null) {
      throw const FormatException('Data latihan tidak valid');
    }
    final cleanNotes = notes?.trim();
    return LocalWorkoutLog(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName.trim(),
      sets: int.parse(sets.trim()),
      reps: int.parse(reps.trim()),
      weight: double.parse(weight.trim()),
      workoutDate: workoutDate.trim(),
      notes: cleanNotes == null || cleanNotes.isEmpty ? null : cleanNotes,
    );
  }

  /// Mengonversi objek Dart menjadi `Map<String, dynamic>` untuk disimpan ke tabel SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'workout_date': workoutDate,
      'notes': notes,
      'exercise_id': exerciseId,
    };
  }

  /// Mengonversi baris Map dari tabel SQLite kembali menjadi objek Dart
  factory LocalWorkoutLog.fromMap(Map<String, dynamic> map) {
    if (map['exercise_name'] is! String ||
        map['sets'] is! num ||
        map['reps'] is! num ||
        map['weight'] is! num ||
        map['workout_date'] is! String) {
      throw const FormatException('Baris latihan SQLite tidak valid');
    }
    return LocalWorkoutLog(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as String?,
      exerciseName: map['exercise_name'] as String,
      sets: (map['sets'] as num).toInt(),
      reps: (map['reps'] as num).toInt(),
      weight: (map['weight'] as num).toDouble(),
      workoutDate: map['workout_date'] as String,
      notes: map['notes'] as String?,
    );
  }

  /// Salin objek dengan perubahan nilai tertentu
  LocalWorkoutLog copyWith({
    int? id,
    Object? exerciseId = _unset,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weight,
    String? workoutDate,
    String? notes,
  }) {
    final nameChanged =
        exerciseName != null && exerciseName != this.exerciseName;
    final resolvedExerciseId = !identical(exerciseId, _unset)
        ? exerciseId as String?
        : (nameChanged ? null : this.exerciseId);

    return LocalWorkoutLog(
      id: id ?? this.id,
      exerciseId: resolvedExerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      workoutDate: workoutDate ?? this.workoutDate,
      notes: notes ?? this.notes,
    );
  }
}
