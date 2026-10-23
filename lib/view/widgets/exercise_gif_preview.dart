import 'package:flutter/material.dart';

class ExerciseGifPreview extends StatelessWidget {
  final String gifUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ExerciseGifPreview({
    super.key,
    required this.gifUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    final theme = Theme.of(context);
    final placeholderBg =
        theme.colorScheme.surfaceContainerHighest != theme.colorScheme.surface
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF2C2C2E);
    final accentColor = theme.colorScheme.primary != Colors.transparent
        ? theme.colorScheme.primary
        : const Color(0xFF00F0FF);

    if (gifUrl.isEmpty || !gifUrl.startsWith('http')) {
      return _buildPlaceholder(
        radius: radius,
        label: 'No Animation',
        bgColor: placeholderBg,
        iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        gifUrl,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: false,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          final totalBytes = loadingProgress.expectedTotalBytes;
          final loadedBytes = loadingProgress.cumulativeBytesLoaded;
          final progress = (totalBytes != null && totalBytes > 0)
              ? loadedBytes / totalBytes
              : null;

          return Container(
            width: width,
            height: height,
            color: placeholderBg,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.2,
                color: accentColor,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(
            radius: radius,
            label: 'GIF Unavailable',
            bgColor: placeholderBg,
            iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder({
    required BorderRadius radius,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: bgColor, borderRadius: radius),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: iconColor, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias for reference callers
typedef ExerciseGifWidget = ExerciseGifPreview;
