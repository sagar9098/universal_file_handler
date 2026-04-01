import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/file_type.dart';
import '../core/file_utils.dart';
import '../models/file_config.dart';
import '../viewers/image_viewer.dart';
import '../viewers/pdf_viewer.dart';
import 'asset_service.dart';
import 'cache_service.dart';
import 'memory_cache_service.dart';
import 'share_service.dart';

/// Public entry point for resolving, opening, caching, and sharing files.
class UniversalFileHandler {
  UniversalFileHandler._();

  static final MemoryCacheService _memoryCache = MemoryCacheService.instance;
  static final CacheService _cacheService = CacheService();
  static final AssetService _assetService = AssetService(
    cacheService: _cacheService,
  );
  static const ShareService _shareService = ShareService();

  /// Detects the file type for [source] from its extension.
  static FileType getFileType(String source) {
    return FileUtils.detectFileType(source);
  }

  /// Resolves [source] into a local [File] using the package pipeline.
  ///
  /// The lookup order is memory cache, disk cache, asset or network loading,
  /// and finally local file validation.
  static Future<File> prepareFile(
    String source, {
    FileConfig config = const FileConfig(),
  }) async {
    final sourceType = FileUtils.detectSourceType(source);
    final sourceKey = FileUtils.buildCacheKey(
      source,
      assetPackage: config.assetPackage,
    );

    final memoryFile = _memoryCache.get(sourceKey);
    if (memoryFile != null) {
      FileUtils.log(config, 'Memory cache hit: $sourceKey');
      return memoryFile;
    }

    final diskFile = await _cacheService.getFileFromDisk(
      sourceKey,
      sourceType,
      config,
    );
    if (diskFile != null) {
      FileUtils.log(config, 'Disk cache hit: ${diskFile.path}');
      _memoryCache.set(sourceKey, diskFile);
      return diskFile;
    }

    late final File resolvedFile;
    switch (sourceType) {
      case FileSourceType.network:
        resolvedFile = await _cacheService.downloadNetworkFile(
          sourceKey,
          config,
        );
        break;
      case FileSourceType.asset:
        resolvedFile = await _assetService.loadAsset(sourceKey, config);
        break;
      case FileSourceType.local:
        final localFile = FileUtils.resolveLocalFile(sourceKey);
        throw SourceFileNotFoundException(
          'Local file not found: "${localFile.path}".',
        );
    }

    _memoryCache.set(sourceKey, resolvedFile);
    FileUtils.log(config, 'Stored in memory cache: $sourceKey');
    return resolvedFile;
  }

  /// Opens a resolved file for the user.
  ///
  /// Pass [context] for image and PDF files so the built-in viewers can be
  /// presented. Other file types are forwarded to the platform opener.
  /// tag parameter is used for hero animation

  static Future<void> open(
    BuildContext? context,
    String source, {
    FileConfig config = const FileConfig(),
    String? title,
    String? tag,
  }) async {
    final file = await prepareFile(source, config: config);
    if (context != null && !context.mounted) {
      return;
    }

    final fileType = FileUtils.detectFileType(file.path);

    switch (fileType) {
      case FileType.image:
        if (context == null) {
          throw const FileOpenException(
            'A BuildContext is required to open image files in-app. '
            'Use ImageViewer directly or pass a context.',
          );
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewer(file: file, title: title, tag: tag),
          ),
        );
        return;
      case FileType.pdf:
        if (context == null) {
          throw const FileOpenException(
            'A BuildContext is required to open PDF files in-app. '
            'Use PdfViewer directly or pass a context.',
          );
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PdfViewer(file: file, title: title),
          ),
        );
        return;
      case FileType.word:
      case FileType.excel:
      case FileType.unknown:
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          throw FileOpenException(
            'Failed to open "${file.path}": ${result.message}',
          );
        }
        return;
    }
  }

  /// Resolves [source] and presents the platform share sheet.
  static Future<void> share(
    String source, {
    FileConfig config = const FileConfig(),
    String? text,
    String? subject,
  }) async {
    final file = await prepareFile(source, config: config);
    await _shareService.shareFile(file, text: text, subject: subject);
  }

  /// Clears every entry stored in the in-memory cache.
  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Removes the in-memory cache entry for [source].
  static void removeFromMemoryCache(
    String source, {
    FileConfig config = const FileConfig(),
  }) {
    final sourceKey = FileUtils.buildCacheKey(
      source,
      assetPackage: config.assetPackage,
    );
    _memoryCache.remove(sourceKey);
  }

  /// Removes the managed disk cache entry for [source].
  static Future<void> removeFromDiskCache(
    String source, {
    FileConfig config = const FileConfig(),
  }) async {
    final sourceType = FileUtils.detectSourceType(source);
    final sourceKey = FileUtils.buildCacheKey(
      source,
      assetPackage: config.assetPackage,
    );

    await _cacheService.removeManagedFile(sourceKey, sourceType, config);
  }

  /// Clears the managed disk cache directory.
  static Future<void> clearDiskCache({bool cache = true}) {
    return _cacheService.clearManagedCache(cache: cache);
  }
}
