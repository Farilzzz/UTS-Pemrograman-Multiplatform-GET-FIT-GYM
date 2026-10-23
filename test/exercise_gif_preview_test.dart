import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_gym/view/widgets/exercise_gif_preview.dart';

void main() {
  group('ExerciseGifPreview', () {
    testWidgets('renders placeholder when gifUrl is empty or not http', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExerciseGifPreview(gifUrl: '')),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('No Animation'), findsOneWidget);
    });

    testWidgets('renders Image.network when gifUrl is valid HTTP URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseGifPreview(
              gifUrl: 'https://static.exercisedb.dev/media/01qpYSe.gif',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.fit, BoxFit.contain);
      expect(imageWidget.width, 120);
      expect(imageWidget.height, 120);
      expect(imageWidget.gaplessPlayback, isFalse);
    });

    testWidgets('displays placeholder on image errorBuilder fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseGifPreview(
              gifUrl: 'https://invalid.domain.example/fake.gif',
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull);

      final context = tester.element(find.byType(ExerciseGifPreview));
      final errorWidget = image.errorBuilder!(
        context,
        Exception('Network fail'),
        null,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: errorWidget)));

      expect(find.text('GIF Unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('loadingBuilder displays byte progress when totalBytes known', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseGifPreview(
              gifUrl: 'https://static.exercisedb.dev/media/01qpYSe.gif',
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.loadingBuilder, isNotNull);

      final context = tester.element(find.byType(ExerciseGifPreview));
      final progressWidget = image.loadingBuilder!(
        context,
        const SizedBox(),
        const ImageChunkEvent(
          cumulativeBytesLoaded: 50,
          expectedTotalBytes: 100,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: progressWidget)),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.5);
    });
  });
}
