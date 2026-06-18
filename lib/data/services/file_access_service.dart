import 'dart:io';

import 'package:flutter/services.dart';

class FileAccessGrant {
  const FileAccessGrant({required this.path, this.renewedBookmark});

  final String path;
  final String? renewedBookmark;
}

class FileAccessService {
  const FileAccessService();

  static const MethodChannel _channel = MethodChannel(
    'free_macos_player/file_access',
  );

  Future<String?> createBookmark(String path) async {
    if (!Platform.isMacOS) {
      return null;
    }

    try {
      return await _channel.invokeMethod<String>('createBookmark', {
        'path': path,
      });
    } on PlatformException {
      return null;
    }
  }

  Future<FileAccessGrant?> startAccessing({
    required String path,
    required String? bookmark,
  }) async {
    if (!Platform.isMacOS) {
      return File(path).existsSync() ? FileAccessGrant(path: path) : null;
    }

    if (bookmark == null || bookmark.isEmpty) {
      return File(path).existsSync() ? FileAccessGrant(path: path) : null;
    }

    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'startAccessing',
        {'bookmark': bookmark},
      );
      final resolvedPath = result?['path'] as String?;
      if (resolvedPath == null || resolvedPath.isEmpty) {
        return null;
      }

      return FileAccessGrant(
        path: resolvedPath,
        renewedBookmark: result?['bookmark'] as String?,
      );
    } on PlatformException {
      return null;
    }
  }
}
