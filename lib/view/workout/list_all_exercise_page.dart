import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:aplikasi_gym/model/exercise_api_model.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';
import 'package:aplikasi_gym/view/workout/detail_exercise_page.dart';
import 'package:aplikasi_gym/view/widgets/exercise_gif_preview.dart';

class ListAllExercisePage extends StatefulWidget {
  final String? categoryName;
  final String? bodyPartName;
  final List<dynamic>? initialExercises;
  final ExerciseApiService? apiService;
  final bool isPickerMode;

  const ListAllExercisePage({
    super.key,
    this.categoryName,
    this.bodyPartName,
    this.initialExercises,
    this.apiService,
    this.isPickerMode = false,
  });

  @override
  State<ListAllExercisePage> createState() => _ListAllExercisePageState();
}

class _ListAllExercisePageState extends State<ListAllExercisePage> {
  String get categoryName =>
      widget.categoryName ?? widget.bodyPartName ?? 'All';

  final TextEditingController searchController = TextEditingController();
  static const bodyParts = [
    'all',
    'chest',
    'back',
    'shoulders',
    'upper arms',
    'lower arms',
    'upper legs',
    'lower legs',
    'waist',
    'cardio',
  ];
  String? _selectedBodyPart;

  // Service mode state
  late final ExerciseApiService _apiService;
  late Future<ExerciseApiResponse> _exercisesFuture;
  final List<ExerciseApiModel> _loadedExercises = [];
  String? _nextCursor;
  bool _hasNextPage = false;
  int _totalServerCount = 0;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBodyPart = widget.bodyPartName ?? widget.categoryName;
    _apiService = widget.apiService ?? ExerciseApiService();
    _exercisesFuture = _fetchInitial();
  }

  String? _resolveBodyPartParam() {
    final raw = (_selectedBodyPart ?? '').toLowerCase().trim();
    if (raw.isEmpty ||
        raw == 'all exercise' ||
        raw == 'all exercises' ||
        raw == 'all') {
      return null;
    }
    if (raw == 'biceps' || raw == 'bicep') {
      return null; // Target muscle in ExerciseDB OSS
    }
    if (raw == 'shoulders' || raw == 'shoulder') return 'shoulders';
    if (raw == 'chest') return 'chest';
    if (raw == 'back') return 'back';
    return raw;
  }

  String? _resolveTargetMuscleParam() {
    final raw = (_selectedBodyPart ?? '').toLowerCase().trim();
    if (raw == 'biceps' || raw == 'bicep') return 'biceps';
    return null;
  }

  Future<ExerciseApiResponse> _fetchInitial() async {
    _loadedExercises.clear();
    _loadMoreError = null;
    final res = await _apiService.fetchExercises(
      limit: 25,
      bodyPart: _resolveBodyPartParam(),
      targetMuscle: _resolveTargetMuscleParam(),
      name: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    _loadedExercises.addAll(res.exercises);
    _nextCursor = res.nextCursor;
    _hasNextPage = res.hasNextPage;
    _totalServerCount = res.total;
    return res;
  }

  void _loadExercises() {
    setState(() {
      _exercisesFuture = _fetchInitial();
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage || _nextCursor == null) return;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final res = await _apiService.fetchExercises(
        limit: 25,
        cursor: _nextCursor,
        after: _nextCursor,
        bodyPart: _resolveBodyPartParam(),
        targetMuscle: _resolveTargetMuscleParam(),
      );
      setState(() {
        _loadedExercises.addAll(res.exercises);
        _nextCursor = res.nextCursor;
        _hasNextPage = res.hasNextPage;
        _totalServerCount = res.total;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = e is ApiException ? e.message : e.toString();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    if (widget.apiService == null) {
      _apiService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildServiceMode(context);

  Widget _buildServiceMode(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary != Colors.transparent
        ? theme.colorScheme.primary
        : const Color(0xFF00F0FF);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: Text(
          widget.isPickerMode ? "PILIH GERAKAN LATIHAN" : categoryName.toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.isPickerMode)
            IconButton(
              tooltip: 'Input manual (offline)',
              icon: const Icon(Icons.edit_note, color: Colors.black),
              onPressed: _showManualFallbackDialog,
            ),
        ],
        backgroundColor: accentColor,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header and results share a viewport when the keyboard is open.
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: const Color(0xFF1C1C1E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Cari latihan...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: accentColor),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('body-part-filter'),
                  initialValue: bodyParts.contains(_selectedBodyPart)
                      ? _selectedBodyPart
                      : 'all',
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Body part',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  items: bodyParts
                      .map(
                        (part) => DropdownMenuItem(
                          value: part,
                          child: Text(
                            '${part[0].toUpperCase()}${part.substring(1)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (part) {
                    _selectedBodyPart = part;
                    searchController.clear();
                    _searchQuery = '';
                    _loadExercises();
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  _totalServerCount > 0
                      ? "$_totalServerCount latihan tersedia • ExerciseDB OSS"
                      : "Data disediakan oleh ExerciseDB OSS / AscendAPI (Edukasi)",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          )),
          SliverToBoxAdapter(child: FutureBuilder<ExerciseApiResponse>(
              future: _exercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }

                if (snapshot.hasError) {
                  final errorMsg = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Gagal Memuat Data Latihan: ${snapshot.error}';
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          const Icon(
                            Icons.error_outline,
                            size: 56,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _loadExercises,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Coba Lagi",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (widget.isPickerMode) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              onPressed: _showManualFallbackDialog,
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Input manual (offline)'),
                            ),
                          ],
                        ],
                      ),
                  );
                }

                final filtered = _loadedExercises.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  return item.name.toLowerCase().contains(_searchQuery) ||
                      item.primaryTarget.toLowerCase().contains(_searchQuery) ||
                      item.primaryEquipment.toLowerCase().contains(
                        _searchQuery,
                      );
                }).toList();

                if (filtered.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          const Icon(
                            Icons.fitness_center,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Tidak ada data latihan yang diterima dari server.",
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(color: accentColor),
                            ),
                            onPressed: _loadExercises,
                            child: const Text("Muat Ulang"),
                          ),
                        ],
                      ),
                  );
                }

                final itemCount = filtered.length + (_hasNextPage ? 1 : 0);

                return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return _buildLoadMoreFooter(accentColor);
                    }

                    final item = filtered[index];
                    return Card(
                      color: const Color(0xFF2C2C2E),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: ExerciseGifPreview(
                            gifUrl: item.gifUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                        title: Text(
                          item.formattedName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "Target: ${item.primaryTarget}",
                              style: TextStyle(color: accentColor),
                            ),
                            if (item.equipments.isNotEmpty)
                              Text(
                                "Alat: ${item.primaryEquipment}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          if (widget.isPickerMode) {
                            Navigator.of(context).pop(item);
                          } else {
                            Get.to(() => DetailExercisePage(exercise: item));
                          }
                        },
                      ),
                    );
                  },
                );
              },
            )),
        ],
      ),
    );
  }

  Future<void> _showManualFallbackDialog() async {
    final textController = TextEditingController();
    final chosenName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Gerakan Manual (Offline)'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Gerakan Latihan',
            hintText: 'Contoh: Push-Up, Pull-Up, Plank',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop(text);
              }
            },
            child: const Text('Pilih'),
          ),
        ],
      ),
    );

    if (chosenName != null && chosenName.isNotEmpty && mounted) {
      final manualItem = ExerciseApiModel(
        exerciseId: '',
        name: chosenName,
        bodyParts: const ['manual'],
        targetMuscles: const ['general'],
        equipments: const ['body weight'],
        gifUrl: '',
        instructions: const [],
        secondaryMuscles: const [],
      );
      Navigator.of(context).pop(manualItem);
    }
  }

  Widget _buildLoadMoreFooter(Color accentColor) {
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              _loadMoreError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMore,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _loadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.expand_more, color: Colors.black),
          label: const Text(
            'Muat Lebih Banyak',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
