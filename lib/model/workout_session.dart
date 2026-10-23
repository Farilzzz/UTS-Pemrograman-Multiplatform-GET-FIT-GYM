import 'workout_exercise.dart';

/// Model data untuk satu sesi latihan (Jadwal / Riwayat).
/// Mendukung relasi one-to-many ke daftar [WorkoutExercise].
/// Dipetakan ke tabel SQLite `workout_sessions`.
class WorkoutSession {
  final int? id;
  final String title;
  final String scheduledDate;
  final String status; // 'planned' atau 'completed'
  final String createdAt;
  final String? completedAt;
  final List<WorkoutExercise> exercises;

  const WorkoutSession({
    this.id,
    required this.title,
    required this.scheduledDate,
    this.status = 'planned',
    required this.createdAt,
    this.completedAt,
    this.exercises = const [],
  });

  /// Factory untuk validasi input sesi latihan.
  factory WorkoutSession.fromInput({
    int? id,
    required String title,
    required String scheduledDate,
    String status = 'planned',
    String? createdAt,
    String? completedAt,
    List<WorkoutExercise> exercises = const [],
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const FormatException('Nama atau judul jadwal latihan tidak boleh kosong.');
    }

    final cleanDate = scheduledDate.trim();
    if (cleanDate.isEmpty) {
      throw const FormatException('Tanggal jadwal latihan tidak boleh kosong.');
    }

    final cleanStatus = status.trim().toLowerCase();
    if (cleanStatus != 'planned' && cleanStatus != 'completed') {
      throw const FormatException('Status sesi harus "planned" atau "completed".');
    }

    return WorkoutSession(
      id: id,
      title: cleanTitle,
      scheduledDate: cleanDate,
      status: cleanStatus,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
      completedAt: completedAt,
      exercises: List.unmodifiable(exercises),
    );
  }

  bool get isPlanned => status == 'planned';
  bool get isCompleted => status == 'completed';
  int get exerciseCount => exercises.length;

  String get statusLabel => isCompleted ? 'Selesai' : 'Direncanakan';

  /// Konversi ke Map untuk tabel SQLite `workout_sessions`.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'scheduled_date': scheduledDate,
      'status': status,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  /// Konstruksi dari Map SQLite dengan daftar gerakan latihan terkait.
  factory WorkoutSession.fromMap(
    Map<String, dynamic> map, {
    List<WorkoutExercise> exercises = const [],
  }) {
    return WorkoutSession(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      scheduledDate: map['scheduled_date'] as String? ?? '',
      status: map['status'] as String? ?? 'planned',
      createdAt: map['created_at'] as String? ?? '',
      completedAt: map['completed_at'] as String?,
      exercises: List.unmodifiable(exercises),
    );
  }

  WorkoutSession copyWith({
    int? id,
    String? title,
    String? scheduledDate,
    String? status,
    String? createdAt,
    String? completedAt,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      exercises: exercises != null ? List.unmodifiable(exercises) : this.exercises,
    );
  }
}
