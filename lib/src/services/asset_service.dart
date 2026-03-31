import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/file_utils.dart';
import '../models/file_config.dart';
import 'cache_service.dart';

/// Loads Flutter assets into managed file storage.
class AssetService {
  /// Creates an asset loader backed by [cacheService].
  AssetService({required CacheService cacheService})
    : _cacheService = cacheService;

  final CacheService _cacheService;

  /// Resolves [assetKey] into a local file that can be opened or shared.
  Future<File> loadAsset(String assetKey, FileConfig config) {
    FileUtils.log(config, 'Loading asset: $assetKey');

    return _cacheService.materializeManagedFile(assetKey, config, () async {
      try {
        final data = await rootBundle.load(assetKey);
        return data.buffer.asUint8List();
      } on FlutterError catch (error, stackTrace) {
        throw SourceFileNotFoundException(
          'Asset not found: "$assetKey".',
          cause: error,
          stackTrace: stackTrace,
        );
      } catch (error, stackTrace) {
        throw FileLoadException(
          'Failed to load asset "$assetKey".',
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });
  }
}
