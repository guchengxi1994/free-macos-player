import 'dart:io';

import 'package:flutter/services.dart';

class VideoThumbnailService {
  const VideoThumbnailService();

  static const MethodChannel _channel = MethodChannel(
    'free_macos_player/thumbnail',
  );

  Future<String?> generateForFile({
    required String sourcePath,
    required String mediaId,
  }) async {
    if (!Platform.isMacOS) {
      return null;
    }

    final outputPath = _thumbnailPath(mediaId);
    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      return outputPath;
    }

    try {
      await outputFile.parent.create(recursive: true);
      final generatedPath = await _channel.invokeMethod<String>('generate', {
        'sourcePath': sourcePath,
        'outputPath': outputPath,
      });
      return generatedPath?.isNotEmpty == true ? generatedPath : outputPath;
    } on PlatformException {
      return null;
    } on FileSystemException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _thumbnailPath(String mediaId) {
    final home = Platform.environment['HOME'];
    final basePath = home == null || home.isEmpty
        ? Directory.systemTemp.path
        : '$home/Library/Application Support/free_macos_player';
    return '$basePath/thumbnails/${_stableHash(mediaId)}.jpg';
  }

  String _stableHash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
