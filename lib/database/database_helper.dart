import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../model/local_workout_log.dart';
import '../model/workout_session.dart';
import '../model/workout_exercise.dart';

/// SQLite DatabaseHelper untuk catatan latihan lokal di perangkat.
/// Menggunakan parameterized queries (whereArgs) untuk mencegah SQL injection.
class DatabaseHelper {
  static const String databaseName = 'local_workout_database.db';
  static const int databaseVersion = 3;
  static const String tableName = 'local_workout_logs';
  static const String sessionTableName = 'workout_sessions';
  static const String exerciseTableName = 'workout_exercises';

  static const String columnId = 'id';
  static const String columnExerciseName = 'exercise_name';
  static const String columnSets = 'sets';
  static const String columnReps = 'reps';
  static const String columnWeight = 'weight';
  static const String columnWorkoutDate = 'workout_date';
  static const String columnNotes = 'notes';
  static const String columnExerciseId = 'exercise_id';

  // Kolom tabel workout_sessions
  static const String columnSessionId = 'id';
  static const String columnSessionTitle = 'title';
  static const String columnSessionScheduledDate = 'scheduled_date';
  static const String columnSessionStatus = 'status';
  static const String columnSessionCreatedAt = 'created_at';
  static const String columnSessionCompletedAt = 'completed_at';

  // Kolom tabel workout_exercises
  static const String columnExId = 'id';
  static const String columnExSessionId = 'session_id';
  static const String columnExApiId = 'exercise_api_id';
  static const String columnExName = 'exercise_name';
  static const String columnExTargetMuscle = 'target_muscle';
  static const String columnExEquipment = 'equipment';
  static const String columnExSets = 'sets';
  static const String columnExReps = 'reps';
  static const String columnExWeight = 'weight';
  static const String columnExNotes = 'notes';
  static const String columnExPosition = 'position';

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  final DatabaseExecutor? _injectedExecutor;

  DatabaseHelper._internal() : _injectedExecutor = null;

  DatabaseHelper() : _injectedExecutor = null;

  /// Konstruktor pengujian untuk injeksi DatabaseExecutor
  DatabaseHelper.withExecutor(DatabaseExecutor executor)
    : _injectedExecutor = executor;

  Future<DatabaseExecutor> get _effectiveExecutor async {
    if (_injectedExecutor != null) {
      return _injectedExecutor;
    }
    return database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnExerciseName TEXT NOT NULL,
        $columnSets INTEGER NOT NULL,
        $columnReps INTEGER NOT NULL,
        $columnWeight REAL NOT NULL,
        $columnWorkoutDate TEXT NOT NULL,
        $columnNotes TEXT,
        $columnExerciseId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $sessionTableName (
        $columnSessionId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnSessionTitle TEXT NOT NULL,
        $columnSessionScheduledDate TEXT NOT NULL,
        $columnSessionStatus TEXT NOT NULL,
        $columnSessionCreatedAt TEXT NOT NULL,
        $columnSessionCompletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $exerciseTableName (
        $columnExId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnExSessionId INTEGER NOT NULL,
        $columnExApiId TEXT,
        $columnExName TEXT NOT NULL,
        $columnExTargetMuscle TEXT,
        $columnExEquipment TEXT,
        $columnExSets INTEGER NOT NULL,
        $columnExReps INTEGER NOT NULL,
        $columnExWeight REAL NOT NULL DEFAULT 0.0,
        $columnExNotes TEXT,
        $columnExPosition INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY ($columnExSessionId) REFERENCES $sessionTableName ($columnSessionId) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await onUpgrade(db, oldVersion, newVersion);
  }

  /// Migrasi database antar versi skema
  static Future<void> onUpgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnExerciseId TEXT',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $sessionTableName (
          $columnSessionId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnSessionTitle TEXT NOT NULL,
          $columnSessionScheduledDate TEXT NOT NULL,
          $columnSessionStatus TEXT NOT NULL,
          $columnSessionCreatedAt TEXT NOT NULL,
          $columnSessionCompletedAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $exerciseTableName (
          $columnExId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnExSessionId INTEGER NOT NULL,
          $columnExApiId TEXT,
          $columnExName TEXT NOT NULL,
          $columnExTargetMuscle TEXT,
          $columnExEquipment TEXT,
          $columnExSets INTEGER NOT NULL,
          $columnExReps INTEGER NOT NULL,
          $columnExWeight REAL NOT NULL DEFAULT 0.0,
          $columnExNotes TEXT,
          $columnExPosition INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY ($columnExSessionId) REFERENCES $sessionTableName ($columnSessionId) ON DELETE CASCADE
        )
      ''');

      try {
        final existing = await db.query(sessionTableName);
        if (existing.isEmpty) {
          final oldLogs = await db.query(tableName, orderBy: '$columnId ASC');
          for (final row in oldLogs) {
            final name = row[columnExerciseName] as String? ?? 'Latihan';
            final date = row[columnWorkoutDate] as String? ??
                DateTime.now().toIso8601String().split('T')[0];
            final sets = (row[columnSets] as num?)?.toInt() ?? 3;
            final reps = (row[columnReps] as num?)?.toInt() ?? 10;
            final weight = (row[columnWeight] as num?)?.toDouble() ?? 0.0;
            final notes = row[columnNotes] as String?;
            final exId = row[columnExerciseId] as String?;

            final sid = await db.insert(sessionTableName, {
              columnSessionTitle: 'Sesi: $name',
              columnSessionScheduledDate: date,
              columnSessionStatus: 'completed',
              columnSessionCreatedAt: DateTime.now().toIso8601String(),
              columnSessionCompletedAt: date,
            });

            await db.insert(exerciseTableName, {
              columnExSessionId: sid,
              columnExApiId: exId,
              columnExName: name,
              columnExTargetMuscle: null,
              columnExEquipment: null,
              columnExSets: sets,
              columnExReps: reps,
              columnExWeight: weight,
              columnExNotes: notes,
              columnExPosition: 0,
            });
          }
        }
      } catch (_) {}
    }
  }

  // =========================================================================
  // OPERASI RELASIONAL: WORKOUT SESSIONS & WORKOUT EXERCISES (CRUD LENGKAP)
  // =========================================================================

  Future<int> insertSessionWithExercises(WorkoutSession session) async {
    final exec = await _effectiveExecutor;
    if (exec is Database) {
      return await exec.transaction((txn) async => _insertSessionTxn(txn, session));
    }
    return await _insertSessionTxn(exec, session);
  }

  Future<int> _insertSessionTxn(DatabaseExecutor txn, WorkoutSession session) async {
    final sessionMap = Map<String, dynamic>.of(session.toMap())..remove('id');
    final sessionId = await txn.insert(
      sessionTableName,
      sessionMap,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (var i = 0; i < session.exercises.length; i++) {
      final ex = session.exercises[i];
      final exMap = Map<String, dynamic>.of(ex.toMap())
        ..remove('id')
        ..['session_id'] = sessionId
        ..['position'] = i;
      await txn.insert(exerciseTableName, exMap);
    }
    return sessionId;
  }

  Future<List<WorkoutSession>> getAllSessions({String? status}) async {
    final exec = await _effectiveExecutor;
    final List<Map<String, dynamic>> sessionMaps;
    if (status != null && status.isNotEmpty) {
      sessionMaps = await exec.query(
        sessionTableName,
        where: '$columnSessionStatus = ?',
        whereArgs: [status],
        orderBy: '$columnSessionScheduledDate DESC, $columnSessionId DESC',
      );
    } else {
      sessionMaps = await exec.query(
        sessionTableName,
        orderBy: '$columnSessionScheduledDate DESC, $columnSessionId DESC',
      );
    }

    final List<WorkoutSession> results = [];
    for (final sMap in sessionMaps) {
      final sId = sMap[columnSessionId] as int;
      final exMaps = await exec.query(
        exerciseTableName,
        where: '$columnExSessionId = ?',
        whereArgs: [sId],
        orderBy: '$columnExPosition ASC, $columnExId ASC',
      );
      final exercises = exMaps.map((e) => WorkoutExercise.fromMap(e)).toList();
      results.add(WorkoutSession.fromMap(sMap, exercises: exercises));
    }
    return results;
  }

  Future<WorkoutSession?> getSessionById(int id) async {
    final exec = await _effectiveExecutor;
    final sessionMaps = await exec.query(
      sessionTableName,
      where: '$columnSessionId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (sessionMaps.isEmpty) return null;

    final exMaps = await exec.query(
      exerciseTableName,
      where: '$columnExSessionId = ?',
      whereArgs: [id],
      orderBy: '$columnExPosition ASC, $columnExId ASC',
    );
    final exercises = exMaps.map((e) => WorkoutExercise.fromMap(e)).toList();
    return WorkoutSession.fromMap(sessionMaps.first, exercises: exercises);
  }

  Future<int> updateSessionWithExercises(WorkoutSession session) async {
    if (session.id == null) {
      throw ArgumentError('Sesi latihan harus memiliki ID untuk dapat diperbarui.');
    }
    final exec = await _effectiveExecutor;
    if (exec is Database) {
      return await exec.transaction((txn) async => _updateSessionTxn(txn, session));
    }
    return await _updateSessionTxn(exec, session);
  }

  Future<int> _updateSessionTxn(DatabaseExecutor txn, WorkoutSession session) async {
    final sessionMap = Map<String, dynamic>.of(session.toMap());
    final affected = await txn.update(
      sessionTableName,
      sessionMap,
      where: '$columnSessionId = ?',
      whereArgs: [session.id],
    );

    await txn.delete(
      exerciseTableName,
      where: '$columnExSessionId = ?',
      whereArgs: [session.id],
    );

    for (var i = 0; i < session.exercises.length; i++) {
      final ex = session.exercises[i];
      final exMap = Map<String, dynamic>.of(ex.toMap())
        ..remove('id')
        ..['session_id'] = session.id
        ..['position'] = i;
      await txn.insert(exerciseTableName, exMap);
    }
    return affected;
  }

  Future<int> updateSessionStatus(int id, String status, {String? completedAt}) async {
    final exec = await _effectiveExecutor;
    return await exec.update(
      sessionTableName,
      {
        columnSessionStatus: status,
        columnSessionCompletedAt: completedAt,
      },
      where: '$columnSessionId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSession(int id) async {
    final exec = await _effectiveExecutor;
    await exec.delete(
      exerciseTableName,
      where: '$columnExSessionId = ?',
      whereArgs: [id],
    );
    return await exec.delete(
      sessionTableName,
      where: '$columnSessionId = ?',
      whereArgs: [id],
    );
  }

  Future<int> addExerciseToSession(int sessionId, WorkoutExercise exercise) async {
    final exec = await _effectiveExecutor;
    final map = Map<String, dynamic>.of(exercise.toMap())
      ..remove('id')
      ..['session_id'] = sessionId;
    return await exec.insert(exerciseTableName, map);
  }

  Future<int> deleteExercise(int exerciseId) async {
    final exec = await _effectiveExecutor;
    return await exec.delete(
      exerciseTableName,
      where: '$columnExId = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<int> updateExercise(WorkoutExercise exercise) async {
    if (exercise.id == null) {
      throw ArgumentError('Gerakan latihan harus memiliki ID untuk diperbarui.');
    }
    final exec = await _effectiveExecutor;
    return await exec.update(
      exerciseTableName,
      exercise.toMap(),
      where: '$columnExId = ?',
      whereArgs: [exercise.id],
    );
  }

  /// Menambahkan log latihan baru ke SQLite
  Future<int> insertWorkoutLog(LocalWorkoutLog log) async {
    final exec = await _effectiveExecutor;
    return await exec.insert(
      tableName,
      Map<String, dynamic>.of(log.toMap())..remove(columnId),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Mengambil semua log latihan lokal diurutkan dari yang terbaru
  Future<List<LocalWorkoutLog>> getAllWorkoutLogs() async {
    final exec = await _effectiveExecutor;
    final List<Map<String, dynamic>> maps = await exec.query(
      tableName,
      orderBy: '$columnWorkoutDate DESC, $columnId DESC',
    );
    return maps.map((item) => LocalWorkoutLog.fromMap(item)).toList();
  }

  /// Mengambil satu log latihan berdasarkan ID dengan parameterized whereArgs
  Future<LocalWorkoutLog?> getWorkoutLogById(int id) async {
    final exec = await _effectiveExecutor;
    final List<Map<String, dynamic>> maps = await exec.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LocalWorkoutLog.fromMap(maps.first);
  }

  /// Memperbarui log latihan yang ada dengan parameterized whereArgs
  Future<int> updateWorkoutLog(LocalWorkoutLog log) async {
    if (log.id == null) {
      throw ArgumentError('Cannot update a workout log without an id');
    }
    final exec = await _effectiveExecutor;
    return await exec.update(
      tableName,
      log.toMap(),
      where: '$columnId = ?',
      whereArgs: [log.id],
    );
  }

  /// Menghapus log latihan berdasarkan ID dengan parameterized whereArgs
  Future<int> deleteWorkoutLog(int id) async {
    final exec = await _effectiveExecutor;
    return await exec.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Menghapus seluruh log latihan lokal
  Future<int> deleteAllWorkoutLogs() async {
    final exec = await _effectiveExecutor;
    return await exec.delete(tableName);
  }

  /// Menutup koneksi database jika terbuka
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
