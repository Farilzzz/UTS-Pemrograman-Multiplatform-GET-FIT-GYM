import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../model/workout_session.dart';
import '../../service/exercise_api_service.dart';
import 'schedule_editor_page.dart';

/// Halaman detail untuk melihat seluruh gerakan latihan di dalam satu sesi jadwal / riwayat.
class SessionDetailPage extends StatefulWidget {
  final int sessionId;
  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? apiService;

  const SessionDetailPage({
    super.key,
    required this.sessionId,
    this.databaseHelper,
    this.apiService,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late final DatabaseHelper _db;
  late Future<WorkoutSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _db = widget.databaseHelper ?? DatabaseHelper.instance;
    _loadSession();
  }

  void _loadSession() {
    setState(() {
      _sessionFuture = _db.getSessionById(widget.sessionId);
    });
  }

  Future<void> _toggleStatus(WorkoutSession session) async {
    final newStatus = session.isPlanned ? 'completed' : 'planned';
    final actionLabel = session.isPlanned ? 'Selesaikan' : 'Kembalikan ke Jadwal';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('$actionLabel Sesi Latihan?'),
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
                ? 'Sesi latihan ditandai selesai.'
                : 'Sesi latihan dikembalikan ke jadwal aktif.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadSession();
    }
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Hapus Sesi Latihan?'),
        content: Text(
          'Sesi "${session.title}" dan seluruh gerakan di dalamnya akan dihapus permanen dari perangkat.',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi latihan berhasil dihapus.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _editSession(WorkoutSession session) async {
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
      _loadSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Sesi Latihan'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSession,
          ),
        ],
      ),
      body: FutureBuilder<WorkoutSession?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat detail sesi: ${snapshot.error}'),
            );
          }

          final session = snapshot.data;
          if (session == null) {
            return const Center(
              child: Text('Sesi latihan tidak ditemukan.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            child: Text(
                              session.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              session.statusLabel,
                              style: TextStyle(
                                color: session.isCompleted ? Colors.greenAccent : accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: (session.isCompleted ? Colors.green : accentColor)
                                .withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Tanggal: ${session.scheduledDate}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (session.completedAt != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'Diselesaikan: ${session.completedAt!.split("T")[0]}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Total Gerakan: ${session.exercises.length} latihan',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sub-header Daftar Latihan
              Text(
                'Daftar Gerakan Latihan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (session.exercises.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tidak ada gerakan yang tercatat dalam sesi ini.'),
                  ),
                )
              else
                ...List.generate(session.exercises.length, (idx) {
                  final ex = session.exercises[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        ex.exerciseName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${ex.sets} set  ×  ${ex.reps} repetisi  •  ${ex.weight > 0 ? "${ex.weight} kg" : "Tanpa Beban"}',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ex.targetMuscle != null)
                            Text(
                              'Target: ${ex.targetMuscle} • Alat: ${ex.equipment ?? "-"}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          if (ex.notes != null && ex.notes!.isNotEmpty)
                            Text(
                              'Catatan: ${ex.notes}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Action Buttons
              if (session.isPlanned)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _toggleStatus(session),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Tandai Selesai (Simpan ke Riwayat)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _toggleStatus(session),
                  icon: const Icon(Icons.undo),
                  label: const Text('Kembalikan ke Jadwal Aktif'),
                ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editSession(session),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Jadwal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () => _deleteSession(session),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus Sesi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
