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

class UniversalFileHandler {
  UniversalFileHandler._();

  static final MemoryCacheService _memoryCache = MemoryCacheService.instance;
  static final CacheService _cacheService = CacheService();
  static final AssetService _assetService = AssetService(
    cacheService: _cacheService,
  );
  static const ShareService _shareService = ShareService();

  static FileType getFileType(String source) {
    return FileUtils.detectFileType(source);
  }
  /// save file local or cache
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

  /// Opens a file from network, asset, or local path.
  /// Automatically detects type and handles accordingly.
  static Future<void> open(
    BuildContext? context,
    String source, {
    FileConfig config = const FileConfig(),
    String? title,
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
            builder: (_) => ImageViewer(file: file, title: title),
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
  /// share a file
  static Future<void> share(
    String source, {
    FileConfig config = const FileConfig(),
    String? text,
    String? subject,
  }) async {
    final file = await prepareFile(source, config: config);
    await _shareService.shareFile(file, text: text, subject: subject);
  }

  // clear all cache from memory
  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  // clear source cache from memory
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
  // remove source from disk cache
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
  // clear all from disk cache
  static Future<void> clearDiskCache({bool cache = true}) {
    return _cacheService.clearManagedCache(cache: cache);
  }
}
