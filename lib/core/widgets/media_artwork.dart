import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class MediaArtwork extends StatelessWidget {
  const MediaArtwork({
    super.key,
    this.source,
    this.fit = BoxFit.cover,
    this.icon = Icons.movie_outlined,
  });

  final String? source;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return _ArtworkFallback(icon: icon);
    }

    if (_isRemote(value)) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (_, _, _) => _ArtworkFallback(icon: icon),
      );
    }

    final file = File(_filePath(value));
    if (!file.existsSync()) {
      return _ArtworkFallback(icon: icon);
    }

    return Image.file(
      file,
      fit: fit,
      errorBuilder: (_, _, _) => _ArtworkFallback(icon: icon),
    );
  }

  bool _isRemote(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _filePath(String value) {
    if (value.startsWith('file://')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.panelSecondaryBackground, palette.primarySoft],
        ),
      ),
      child: Center(
        child: Icon(icon, color: palette.primary.withValues(alpha: 0.72)),
      ),
    );
  }
}
