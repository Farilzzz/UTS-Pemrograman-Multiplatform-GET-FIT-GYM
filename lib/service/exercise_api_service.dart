import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:aplikasi_gym/model/exercise_api_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ExerciseApiResponse {
  final List<ExerciseApiModel> exercises;
  final int total;
  final bool hasNextPage;
  final String? nextCursor;

  const ExerciseApiResponse({
    required this.exercises,
    required this.total,
    required this.hasNextPage,
    this.nextCursor,
  });
}

class ExerciseApiService {
  static const String baseUrl = 'https://oss.exercisedb.dev/api/v1';
  static const Duration defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final Duration timeout;

  ExerciseApiService({http.Client? client, this.timeout = defaultTimeout})
    : _client = client ?? http.Client();

  Future<ExerciseApiResponse> fetchExercises({
    int limit = 20,
    String? cursor,
    String? after,
    String? bodyPart,
    String? bodyParts,
    String? targetMuscle,
    String? targetMuscles,
    String? name,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.clamp(1, 25).toString(),
    };

    final effectiveCursor = after ?? cursor;
    if (effectiveCursor != null && effectiveCursor.isNotEmpty) {
      queryParams['after'] = effectiveCursor;
    }

    final effectiveBodyPart = bodyParts ?? bodyPart;
    if (effectiveBodyPart != null &&
        effectiveBodyPart.isNotEmpty &&
        effectiveBodyPart.toLowerCase() != 'all exercise' &&
        effectiveBodyPart.toLowerCase() != 'all exercises' &&
        effectiveBodyPart.toLowerCase() != 'all') {
      queryParams['bodyParts'] = effectiveBodyPart.toLowerCase();
    }

    final effectiveTargetMuscle = targetMuscles ?? targetMuscle;
    if (effectiveTargetMuscle != null && effectiveTargetMuscle.isNotEmpty) {
      queryParams['targetMuscles'] = effectiveTargetMuscle.toLowerCase();
    }

    if (name != null && name.trim().isNotEmpty) {
      queryParams['name'] = name.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/exercises',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'GetFitGym-ExerciseDB/1.0',
            },
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server ExerciseDB. Periksa koneksi internet Anda. ($e)',
      );
    } on TimeoutException {
      throw const ApiException(
        'Permintaan data ke ExerciseDB melebihi batas waktu (timeout). Silakan coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server ExerciseDB: ${e.message}',
      );
    } on FormatException catch (e) {
      throw ApiException(
        'Gagal mengolah format data respons dari server. ($e)',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat memuat data latihan: $e');
    }
  }

  ExerciseApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        'Server ExerciseDB merespons kesalahan ($statusCode).',
        statusCode: statusCode,
      );
    }

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (e) {
      throw ApiException('Format data JSON dari server tidak valid: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'Format data JSON dari server tidak sesuai standar.',
      );
    }

    final success = decoded['success'] as bool? ?? false;
    if (!success) {
      throw ApiException(
        'Server ExerciseDB merespons status gagal.',
        statusCode: statusCode,
      );
    }

    final dataList = decoded['data'];
    if (dataList is! List) {
      throw const ApiException(
        'Struktur atribut data latihan tidak berbentuk list.',
      );
    }

    final exercises = dataList
        .whereType<Map<String, dynamic>>()
        .map((item) => ExerciseApiModel.fromJson(item))
        .toList();

    int total = exercises.length;
    bool hasNextPage = false;
    String? nextCursor;

    final meta = decoded['meta'];
    if (meta is Map<String, dynamic>) {
      total = meta['total'] as int? ?? total;
      hasNextPage = meta['hasNextPage'] as bool? ?? false;
      nextCursor = meta['nextCursor'] as String?;
    }

    return ExerciseApiResponse(
      exercises: exercises,
      total: total,
      hasNextPage: hasNextPage,
      nextCursor: nextCursor,
    );
  }

  void dispose() {
    _client.close();
  }

  void close() {
    dispose();
  }
}
