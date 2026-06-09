import 'package:flutter/material.dart';

import 'pokrov_palette.dart';

abstract final class PokrovBrandAssets {
  static const mark = 'assets/brand/pokrov_mark.png';
}

class PokrovBrandMark extends StatelessWidget {
  const PokrovBrandMark({
    required this.size,
    this.opacity = 1,
    this.assetName = PokrovBrandAssets.mark,
    this.fallbackText = 'P',
    super.key,
  });

  static const imageKey = ValueKey('pokrov-brand-mark');

  final double size;
  final double opacity;
  final String assetName;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (assetName.trim().isEmpty) {
      return Opacity(
        opacity: opacity,
        child: _FallbackBrandMark(
          key: imageKey,
          size: size,
          fallbackText: fallbackText,
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Image.asset(
        assetName,
        key: imageKey,
        width: size,
        height: size,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackBrandMark(
            key: imageKey,
            size: size,
            fallbackText: fallbackText,
          );
        },
      ),
    );
  }
}

class _FallbackBrandMark extends StatelessWidget {
  const _FallbackBrandMark({
    required this.size,
    required this.fallbackText,
    super.key,
  });

  final double size;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final trimmed = fallbackText.trim();
    final label = trimmed.isEmpty ? 'O' : trimmed.substring(0, 1).toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PokrovPalette.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: PokrovPalette.accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}
