import 'package:flutter/material.dart';
import '../../model/exercise_api_model.dart';
import '../../service/exercise_api_service.dart';
import '../widgets/exercise_gif_preview.dart';

class ExercisePickerResult {
  final ExerciseApiModel? exercise;
  const ExercisePickerResult(this.exercise);
}

class ExercisePickerPage extends StatefulWidget {
  final ExerciseApiService? apiService;
  const ExercisePickerPage({super.key, this.apiService});
  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  late final ExerciseApiService _service;
  final _search = TextEditingController();
  final List<ExerciseApiModel> _items = [];
  String? _muscle, _cursor, _error;
  bool _loading = false, _more = false, _hasNext = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.apiService ?? ExerciseApiService();
    _fetch();
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    if (widget.apiService == null) _service.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool more = false}) async {
    if (more && (_more || !_hasNext || _cursor == null)) return;
    final generation = more ? _generation : ++_generation;
    setState(() {
      if (more) { _more = true; } else { _loading = true; _items.clear(); _cursor = null; _hasNext = false; }
      _error = null;
    });
    try {
      final result = await _service.fetchExercises(
        limit: 25, name: _search.text.trim(), targetMuscle: _muscle,
        after: more ? _cursor : null,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.exercises);
        _cursor = result.nextCursor;
        _hasNext = result.hasNextPage && _cursor != null;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() { _loading = false; _more = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pilih ExerciseDB')),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('pickerSearch'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetch(),
                  decoration: InputDecoration(
                    labelText: 'Cari nama latihan',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _fetch,
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('pickerMuscle'),
                  initialValue: _muscle,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Otot target'),
                  items: [
                    null,
                    'biceps',
                    'triceps',
                    'pectorals',
                    'delts',
                    'lats',
                    'quads',
                    'hamstrings',
                    'glutes',
                    'abs',
                    'calves',
                  ]
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m ?? 'Semua otot',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (m) {
                    _muscle = m;
                    _fetch();
                  },
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const ExercisePickerResult(null)),
                  child: const Text('Input manual (offline)'),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && _items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _fetch,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _items.length) {
                  return Center(
                    child: _more
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => _fetch(more: true),
                            child: Text(
                              _error == null ? 'Muat lagi' : 'Coba Lagi',
                            ),
                          ),
                  );
                }
                final item = _items[index];
                return ListTile(
                  leading: ExerciseGifPreview(
                    gifUrl: item.gifUrl,
                    width: 56,
                    height: 56,
                  ),
                  title: Text(item.formattedName),
                  subtitle: Text(item.primaryTarget),
                  onTap: () => Navigator.pop(context, ExercisePickerResult(item)),
                );
              },
              childCount:
                  _items.length + (_hasNext || _more || _error != null ? 1 : 0),
            ),
          ),
      ],
    ),
  );
}
