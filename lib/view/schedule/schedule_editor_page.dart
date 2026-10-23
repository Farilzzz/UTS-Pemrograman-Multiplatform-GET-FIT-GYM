import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../model/exercise_api_model.dart';
import '../../model/workout_exercise.dart';
import '../../model/workout_session.dart';
import '../../service/exercise_api_service.dart';
import '../workout/list_all_exercise_page.dart';

/// Halaman untuk membuat jadwal baru atau menyunting jadwal yang sudah ada.
/// Mendukung multi-exercise sessions yang terintegrasi dengan katalog ExerciseDB OSS.
class ScheduleEditorPage extends StatefulWidget {
  final WorkoutSession? session;
  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? apiService;

  const ScheduleEditorPage({
    super.key,
    this.session,
    this.databaseHelper,
    this.apiService,
  });

  @override
  State<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ExerciseItemFormState {
  final String? exerciseApiId;
  final String exerciseName;
  final String? targetMuscle;
  final String? equipment;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController notesController;

  _ExerciseItemFormState({
    this.exerciseApiId,
    required this.exerciseName,
    this.targetMuscle,
    this.equipment,
    int sets = 3,
    int reps = 12,
    double weight = 0.0,
    String? notes,
  })  : setsController = TextEditingController(text: sets.toString()),
        repsController = TextEditingController(text: reps.toString()),
        weightController = TextEditingController(text: weight > 0 ? weight.toString() : '0'),
        notesController = TextEditingController(text: notes ?? '');

  void dispose() {
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    notesController.dispose();
  }
}

class _ScheduleEditorPageState extends State<ScheduleEditorPage> {
  late final DatabaseHelper _db;
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  final List<_ExerciseItemFormState> _exerciseForms = [];
  bool _isSaving = false;

  bool get _isEdit => widget.session != null;

  @override
  void initState() {
    super.initState();
    _db = widget.databaseHelper ?? DatabaseHelper.instance;
    _titleController = TextEditingController(text: widget.session?.title ?? '');

    if (widget.session != null && widget.session!.scheduledDate.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.session!.scheduledDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }

    if (widget.session != null) {
      for (final ex in widget.session!.exercises) {
        _exerciseForms.add(_ExerciseItemFormState(
          exerciseApiId: ex.exerciseApiId,
          exerciseName: ex.exerciseName,
          targetMuscle: ex.targetMuscle,
          equipment: ex.equipment,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          notes: ex.notes,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final f in _exerciseForms) {
      f.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _openExercisePicker() async {
    final result = await Navigator.of(context).push<ExerciseApiModel>(
      MaterialPageRoute(
        builder: (_) => ListAllExercisePage(
          apiService: widget.apiService,
          isPickerMode: true,
        ),
      ),
    );

    if (result != null && mounted) {
      final name = result.formattedName;
      // Periksa duplikasi gerakan dalam sesi yang sama
      final alreadyExists = _exerciseForms.any(
        (f) => f.exerciseName.trim().toLowerCase() == name.trim().toLowerCase(),
      );

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gerakan '$name' sudah ada dalam sesi latihan ini."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() {
        _exerciseForms.add(_ExerciseItemFormState(
          exerciseApiId: result.exerciseId.isNotEmpty ? result.exerciseId : null,
          exerciseName: name,
          targetMuscle: result.primaryTarget,
          equipment: result.primaryEquipment,
          sets: 3,
          reps: 12,
          weight: 0.0,
        ));
      });
    }
  }

  Future<void> _addManualExercise() async {
    final textController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Input Gerakan Manual (Offline)'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Gerakan',
            hintText: 'Contoh: Push-Up, Pull-Up, Plank',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );

    if (added == true && mounted) {
      final name = textController.text.trim();
      final alreadyExists = _exerciseForms.any(
        (f) => f.exerciseName.trim().toLowerCase() == name.toLowerCase(),
      );

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gerakan '$name' sudah ada dalam sesi latihan ini."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() {
        _exerciseForms.add(_ExerciseItemFormState(
          exerciseName: name,
          targetMuscle: 'Manual/Lokal',
          equipment: 'Bodyweight/Bebas',
          sets: 3,
          reps: 10,
          weight: 0.0,
        ));
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      final removed = _exerciseForms.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveSchedule() async {
    final title = _titleController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (title.isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nama jadwal tidak boleh kosong.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_exerciseForms.isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu gerakan latihan untuk jadwal ini.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final List<WorkoutExercise> parsedExercises = [];
    for (var i = 0; i < _exerciseForms.length; i++) {
      final form = _exerciseForms[i];
      try {
        final ex = WorkoutExercise.fromInput(
          exerciseApiId: form.exerciseApiId,
          exerciseName: form.exerciseName,
          targetMuscle: form.targetMuscle,
          equipment: form.equipment,
          sets: form.setsController.text,
          reps: form.repsController.text,
          weight: form.weightController.text,
          notes: form.notesController.text,
          position: i,
        );
        parsedExercises.add(ex);
      } on FormatException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${form.exerciseName}: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = _formatDate(_selectedDate);
      if (_isEdit) {
        final updatedSession = widget.session!.copyWith(
          title: title,
          scheduledDate: dateStr,
          exercises: parsedExercises,
        );
        await _db.updateSessionWithExercises(updatedSession);
      } else {
        final newSession = WorkoutSession.fromInput(
          title: title,
          scheduledDate: dateStr,
          status: 'planned',
          exercises: parsedExercises,
        );
        await _db.insertSessionWithExercises(newSession);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Jadwal berhasil diperbarui.' : 'Jadwal latihan berhasil disimpan.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jadwal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Jadwal' : 'Buat Jadwal Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Input Nama Jadwal
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Jadwal (Wajib)',
                hintText: 'Contoh: Push Day, Leg Day, Full Body',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Tanggal Jadwal
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: accentColor),
                title: const Text('Tanggal Pelaksanaan'),
                subtitle: Text(
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: _pickDate,
                trailing: IconButton(
                  tooltip: 'Ubah Tanggal',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Daftar Gerakan
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Daftar Latihan (${_exerciseForms.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'catalog') {
                      _openExercisePicker();
                    } else if (val == 'manual') {
                      _addManualExercise();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'catalog',
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pilih dari Katalog API',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'manual',
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Input Manual (Offline)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Gerakan'),
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List Gerakan Latihan
            if (_exerciseForms.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.playlist_add, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada gerakan latihan dalam sesi ini.\nTekan tombol di bawah untuk memilih dari katalog ExerciseDB.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _openExercisePicker,
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('Buka Katalog Latihan'),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_exerciseForms.length, (idx) {
                final form = _exerciseForms[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: accentColor.withValues(alpha: 0.2),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                form.exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus gerakan',
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeExercise(idx),
                            ),
                          ],
                        ),
                        if (form.targetMuscle != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 36, bottom: 8),
                            child: Text(
                              'Target: ${form.targetMuscle} • Alat: ${form.equipment ?? "-"}',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: form.setsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Set',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: form.repsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: form.weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Beban (kg)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Tombol tambah latihan lagi
            if (_exerciseForms.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openExercisePicker,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Gerakan (Katalog API)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Input Manual',
                    icon: const Icon(Icons.edit_note),
                    onPressed: _addManualExercise,
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // Tombol Simpan Jadwal
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSaving ? null : _saveSchedule,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      _isEdit ? 'Perbarui Jadwal Latihan' : 'Simpan Jadwal Latihan',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
