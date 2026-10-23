import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aplikasi_gym/service/exercise_api_service.dart';

void main() {
  group('ExerciseApiService', () {
    test(
      'sends request with correct endpoint, clamped limit, headers and parameters',
      () async {
        late Uri capturedUri;
        late Map<String, String> capturedHeaders;

        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          return http.Response(
            '''{
            "success": true,
            "meta": {
              "total": 1500,
              "hasNextPage": true,
              "hasPreviousPage": false,
              "nextCursor": "cursor-abc"
            },
            "data": [
              {
                "exerciseId": "01qpYSe",
                "name": "upward facing dog",
                "gifUrl": "https://static.exercisedb.dev/media/01qpYSe.gif",
                "bodyParts": ["back"],
                "equipments": ["bodyweight"],
                "targetMuscles": ["erector spinae"],
                "secondaryMuscles": ["deltoids"],
                "instructions": ["Lie down", "Arch back"]
              }
            ]
          }''',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = ExerciseApiService(client: client);
        final response = await service.fetchExercises(
          limit: 50, // Should be clamped to 25
          cursor: 'start-cursor',
          bodyPart: 'back',
          targetMuscle: 'erector spinae',
          name: 'dog',
        );

        expect(capturedUri.scheme, 'https');
        expect(capturedUri.host, 'oss.exercisedb.dev');
        expect(capturedUri.path, '/api/v1/exercises');
        expect(capturedUri.queryParameters['limit'], '25');
        expect(capturedUri.queryParameters['after'], 'start-cursor');
        expect(capturedUri.queryParameters['bodyParts'], 'back');
        expect(capturedUri.queryParameters['targetMuscles'], 'erector spinae');
        expect(capturedUri.queryParameters['name'], 'dog');
        expect(capturedHeaders['Accept'], 'application/json');

        expect(response.total, 1500);
        expect(response.hasNextPage, isTrue);
        expect(response.nextCursor, 'cursor-abc');
        expect(response.exercises, hasLength(1));
        expect(response.exercises.first.exerciseId, '01qpYSe');
        expect(response.exercises.first.formattedName, 'Upward Facing Dog');

        service.dispose();
      },
    );

    test('supports forward cursor via "after" named parameter', () async {
      late Uri capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          '{"success": true, "meta": {"total": 1, "hasNextPage": false, "nextCursor": null}, "data": []}',
          200,
        );
      });

      final service = ExerciseApiService(client: client);
      await service.fetchExercises(after: 'next-123');
      expect(capturedUri.queryParameters['after'], 'next-123');
      service.dispose();
    });

    test('throws ApiException on HTTP non-200 status', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ExerciseApiService(client: client);
      expect(
        () => service.fetchExercises(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
      service.dispose();
    });

    test(
      'throws ApiException when server response success flag is false',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            '{"success": false, "message": "Bad request"}',
            200,
          );
        });

        final service = ExerciseApiService(client: client);
        expect(() => service.fetchExercises(), throwsA(isA<ApiException>()));
        service.dispose();
      },
    );

    test(
      'throws ApiException on invalid JSON schema / malformed data',
      () async {
        final client = MockClient((request) async {
          return http.Response('{"success": true, "data": "not a list"}', 200);
        });

        final service = ExerciseApiService(client: client);
        expect(() => service.fetchExercises(), throwsA(isA<ApiException>()));
        service.dispose();
      },
    );

    test('throws ApiException on network client exception', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final service = ExerciseApiService(client: client);
      expect(() => service.fetchExercises(), throwsA(isA<ApiException>()));
      service.dispose();
    });

    test('throws ApiException on timeout', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{"success": true, "data": []}', 200);
      });

      final service = ExerciseApiService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      );
      expect(
        () => service.fetchExercises(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('waktu'),
          ),
        ),
      );
      service.dispose();
    });
  });
}
