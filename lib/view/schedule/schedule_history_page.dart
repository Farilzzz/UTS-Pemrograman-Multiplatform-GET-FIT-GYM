import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../model/workout_session.dart';
import '../../service/exercise_api_service.dart';
import 'schedule_editor_page.dart';
import 'session_detail_page.dart';

/// Halaman utama "Jadwal & Riwayat" dengan tabulasi Jadwal (Planned) dan Riwayat (Completed).
/// 100% menggunakan SQLite lokal tanpa dependensi jaringan untuk membaca dan mengelola data.
class ScheduleHistoryPage extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? apiService;

  const ScheduleHistoryPage({
    super.key,
    this.databaseHelper,
    this.apiService,
  });

  @override
  State<ScheduleHistoryPage> createState() => _ScheduleHistoryPageState();
}

class _ScheduleHistoryPageState extends State<ScheduleHistoryPage>
    with SingleTickerProviderStateMixin {
  late final DatabaseHelper _db;
  late final TabController _tabController;
  late Future<List<WorkoutSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _db = widget.databaseHelper ?? DatabaseHelper.instance;
    _tabController = TabController(length: 2, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSessions() {
    setState(() {
      _sessionsFuture = _db.getAllSessions();
    });
  }

  Future<void> _createNewSchedule() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScheduleEditorPage(
          databaseHelper: _db,
          apiService: widget.apiService,
        ),
      ),
    );
    if (created == true && mounted) {
      _loadSessions();
    }
  }

  Future<void> _editSchedule(WorkoutSession session) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScheduleEditorPage(
          session: session,
          databaseHelper: _db,
          apiService: widget.apiService,
        ),
      ),
    );
    if (updated == true && mounted) {
      _loadSessions();
    }
  }

  Future<void> _viewSessionDetail(WorkoutSession session) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionDetailPage(
          sessionId: session.id!,
          databaseHelper: _db,
          apiService: widget.apiService,
        ),
      ),
    );
    if (changed == true && mounted) {
      _loadSessions();
    }
  }

  Future<void> _toggleStatus(WorkoutSession session) async {
    final newStatus = session.isPlanned ? 'completed' : 'planned';
    final actionLabel = session.isPlanned ? 'Selesaikan Sesi' : 'Kembalikan ke Jadwal';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('$actionLabel?'),
        content: Text(
          session.isPlanned
              ? 'Tandai sesi "${session.title}" telah selesai dilakukan dan simpan ke riwayat?'
              : 'Kembalikan sesi "${session.title}" ke status Direncanakan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final now = DateTime.now().toIso8601String();
      await _db.updateSessionStatus(
        session.id!,
        newStatus,
        completedAt: newStatus == 'completed' ? now : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'completed'
                ? 'Sesi "${session.title}" dipindahkan ke Riwayat Latihan.'
                : 'Sesi "${session.title}" dikembalikan ke Jadwal Latihan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadSessions();
    }
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Hapus Sesi Latihan?'),
        content: Text(
          'Sesi "${session.title}" beserta seluruh gerakannya akan dihapus permanen dari perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _db.deleteSession(session.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi latihan berhasil dihapus.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jadwal & Riwayat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Jadwal Latihan'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat Latihan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        onPressed: _createNewSchedule,
        icon: const Icon(Icons.add),
        label: const Text(
          'Buat Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('Gagal memuat data SQLite: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadSessions,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allSessions = snapshot.data ?? [];
          final plannedSessions = allSessions.where((s) => s.isPlanned).toList();
          final completedSessions = allSessions.where((s) => s.isCompleted).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Jadwal Latihan (Planned)
              _buildSessionList(
                sessions: plannedSessions,
                isPlannedTab: true,
                emptyMessage:
                    'Belum ada jadwal latihan yang direncanakan.\nTekan tombol "Buat Jadwal" untuk menyusun sesi latihan baru.',
                accentColor: accentColor,
              ),

              // Tab 2: Riwayat Latihan (Completed)
              _buildSessionList(
                sessions: completedSessions,
                isPlannedTab: false,
                emptyMessage:
                    'Belum ada riwayat latihan yang diselesaikan.\nSelesaikan jadwal latihan untuk mencatat riwayat workout.',
                accentColor: accentColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionList({
    required List<WorkoutSession> sessions,
    required bool isPlannedTab,
    required String emptyMessage,
    required Color accentColor,
  }) {
    if (sessions.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPlannedTab ? Icons.event_note : Icons.task_alt,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              if (isPlannedTab) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _createNewSchedule,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Jadwal Pertama'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _viewSessionDetail(session),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Header: Judul & Badge Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (session.isCompleted ? Colors.green : accentColor)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session.statusLabel,
                          style: TextStyle(
                            color: session.isCompleted ? Colors.greenAccent : accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tanggal & Gerakan Count
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.event, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        session.scheduledDate,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.fitness_center, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${session.exercises.length} gerakan',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Daftar Gerakan Preview
                  if (session.exercises.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: session.exercises.take(3).map((ex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${ex.exerciseName} (${ex.sets} set × ${ex.reps} reps${ex.weight > 0 ? " • ${ex.weight} kg" : ""})',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  if (session.exercises.length > 3)
                    Text(
                      '+ ${session.exercises.length - 3} gerakan lainnya...',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                  const SizedBox(height: 12),

                  // Tombol Aksi
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isPlannedTab) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.greenAccent,
                            side: const BorderSide(color: Colors.greenAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () => _toggleStatus(session),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Selesaikan'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Edit jadwal',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editSchedule(session),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () => _viewSessionDetail(session),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Detail'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Kembalikan ke Jadwal',
                          icon: const Icon(Icons.undo, size: 20),
                          onPressed: () => _toggleStatus(session),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Hapus sesi',
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => _deleteSession(session),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
