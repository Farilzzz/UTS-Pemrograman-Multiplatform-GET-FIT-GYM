import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../model/local_workout_log.dart';
import '../../service/exercise_api_service.dart';
import 'exercise_picker_page.dart';

class LocalWorkoutHistoryPage extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  final ExerciseApiService? apiService;
  const LocalWorkoutHistoryPage({
    super.key,
    this.databaseHelper,
    this.apiService,
  });

  @override
  State<LocalWorkoutHistoryPage> createState() =>
      _LocalWorkoutHistoryPageState();
}

class _LocalWorkoutHistoryPageState extends State<LocalWorkoutHistoryPage> {
  List<LocalWorkoutLog> _logs = const [];
  bool _loading = true;
  String? _error;
  late final ExerciseApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ExerciseApiService();
    _load();
  }

  @override
  void dispose() {
    if (widget.apiService == null) {
      _apiService.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await (widget.databaseHelper ?? DatabaseHelper.instance)
          .getAllWorkoutLogs();
      if (mounted) setState(() => _logs = logs);
    } catch (_) {
      if (mounted) setState(() => _error = 'Riwayat lokal gagal dimuat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([LocalWorkoutLog? current]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LocalWorkoutForm(
        databaseHelper: widget.databaseHelper ?? DatabaseHelper.instance,
        apiService: _apiService,
        current: current,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(LocalWorkoutLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus latihan?'),
        content: Text(
          'Riwayat "${log.exerciseName}" akan dihapus dari perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await (widget.databaseHelper ?? DatabaseHelper.instance).deleteWorkoutLog(
        log.id!,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Latihan gagal dihapus.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cyan = Color(0xFF00D7E6);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Riwayat Latihan Lokal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openForm(),
        backgroundColor: cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Latihan'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_android, color: cyan),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Disimpan hanya di perangkat ini dan tidak disinkronkan ke layanan cloud.',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _logs.isEmpty
                ? const Center(child: Text('Belum ada latihan lokal.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _logs.length,
                      itemBuilder: (_, index) {
                        final log = _logs[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cyan.withValues(alpha: .15),
                              child: const Icon(
                                Icons.fitness_center,
                                color: cyan,
                              ),
                            ),
                            title: Text(
                              log.exerciseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${log.workoutDate}  •  ${log.sets} set × ${log.reps} repetisi  •  ${log.weight} kg${log.notes == null ? '' : '\n${log.notes}'}',
                            ),
                            isThreeLine: log.notes != null,
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: 'Edit latihan',
                                  onPressed: () => _openForm(log),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Hapus latihan',
                                  onPressed: () => _delete(log),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocalWorkoutForm extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final ExerciseApiService apiService;
  final LocalWorkoutLog? current;
  const _LocalWorkoutForm({
    required this.databaseHelper,
    required this.apiService,
    this.current,
  });
  @override
  State<_LocalWorkoutForm> createState() => _LocalWorkoutFormState();
}

class _LocalWorkoutFormState extends State<_LocalWorkoutForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _sets, _reps, _weight, _date, _notes;
  bool _saving = false;
  String? _error;
  String? _exerciseId;
  String? _selectedExerciseName;

  @override
  void initState() {
    super.initState();
    final log = widget.current;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _name = TextEditingController(text: log?.exerciseName ?? '');
    _sets = TextEditingController(text: log?.sets.toString() ?? '');
    _reps = TextEditingController(text: log?.reps.toString() ?? '');
    _weight = TextEditingController(text: log?.weight.toString() ?? '');
    _date = TextEditingController(text: log?.workoutDate ?? today);
    _notes = TextEditingController(text: log?.notes ?? '');
    _exerciseId = log?.exerciseId;
    _selectedExerciseName = log?.exerciseName;
  }

  @override
  void dispose() {
    for (final controller in [_name, _sets, _reps, _weight, _date, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExercise() async {
    final result = await Navigator.push<ExercisePickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerPage(apiService: widget.apiService),
      ),
    );
    if (result == null) return;
    final selected = result.exercise;
    if (selected != null) {
      setState(() {
        _name.text = selected.name;
        _selectedExerciseName = selected.name;
        _exerciseId =
            selected.exerciseId.isNotEmpty ? selected.exerciseId : null;
      });
    } else {
      setState(() {
        _selectedExerciseName = null;
        _exerciseId = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _date.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final isManualEdit =
        _selectedExerciseName == null ||
        _name.text.trim().toLowerCase() !=
            _selectedExerciseName!.trim().toLowerCase();
    final effectiveExerciseId = isManualEdit ? null : _exerciseId;

    try {
      final log = LocalWorkoutLog.fromInput(
        id: widget.current?.id,
        exerciseId: effectiveExerciseId,
        exerciseName: _name.text,
        sets: _sets.text,
        reps: _reps.text,
        weight: _weight.text,
        workoutDate: _date.text,
        notes: _notes.text,
      );
      if (widget.current == null) {
        await widget.databaseHelper.insertWorkoutLog(log);
      } else {
        await widget.databaseHelper.updateWorkoutLog(log);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Latihan gagal disimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 420;
                  final title = Text(
                    widget.current == null
                        ? 'Tambah Latihan Lokal'
                        : 'Edit Latihan Lokal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                  final picker = TextButton.icon(
                    key: const Key('pickerButton'),
                    onPressed: _pickExercise,
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(
                      widget.current == null
                          ? 'Pilih dari ExerciseDB'
                          : 'Ganti via ExerciseDB',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                  return narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [title, Align(alignment: Alignment.centerLeft, child: picker)],
                        )
                      : Row(
                          children: [Expanded(child: title), picker],
                        );
                },
              ),
              const SizedBox(height: 2),
              const Text(
                'Data ini tetap tersimpan secara lokal di perangkat ini.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('exerciseName'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama latihan'),
                validator: LocalWorkoutLog.validateName,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('sets'),
                      controller: _sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Set'),
                      validator: LocalWorkoutLog.validatePositiveInteger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      key: const Key('reps'),
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Repetisi'),
                      validator: LocalWorkoutLog.validatePositiveInteger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('weight'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Berat (kg)'),
                validator: LocalWorkoutLog.validateWeight,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('date'),
                controller: _date,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: LocalWorkoutLog.validateDate,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('notes'),
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
