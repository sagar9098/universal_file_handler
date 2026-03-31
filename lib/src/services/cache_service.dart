import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/file_utils.dart';
import '../models/file_config.dart';

class CacheService {
  CacheService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Future<File>> _pendingLoads = <String, Future<File>>{};

  Future<File?> getFileFromDisk(
    String sourceKey,
    FileSourceType sourceType,
    FileConfig config,
  ) async {
    switch (sourceType) {
      case FileSourceType.local:
        final localFile = FileUtils.resolveLocalFile(sourceKey);
        if (await localFile.exists()) {
          return localFile;
        }
        return null;
      case FileSourceType.asset:
      case FileSourceType.network:
        final managedFile = await _getManagedFile(sourceKey, config);
        if (await managedFile.exists()) {
          return managedFile;
        }
        return null;
    }
  }

  Future<File> downloadNetworkFile(String sourceKey, FileConfig config) {
    final uri = FileUtils.parseNetworkUri(sourceKey);

    return materializeManagedFile(
      sourceKey,
      config,
      () => _downloadBytes(uri, config),
    );
  }

  Future<File> materializeManagedFile(
    String sourceKey,
    FileConfig config,
    Future<List<int>> Function() loadBytes,
  ) {
    final pendingLoad = _pendingLoads[sourceKey];
    if (pendingLoad != null) {
      FileUtils.log(config, 'Waiting for in-flight load: $sourceKey');
      return pendingLoad;
    }

    final operation = _materializeManagedFile(sourceKey, config, loadBytes);
    _pendingLoads[sourceKey] = operation;

    return operation.whenComplete(() {
      _pendingLoads.remove(sourceKey);
    });
  }

  Future<void> removeManagedFile(
    String sourceKey,
    FileSourceType sourceType,
    FileConfig config,
  ) async {
    if (sourceType == FileSourceType.local) {
      return;
    }

    final file = await _getManagedFile(sourceKey, config);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearManagedCache({required bool cache}) async {
    final directory = await _getBaseDirectory(cache: cache);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<File> _materializeManagedFile(
    String sourceKey,
    FileConfig config,
    Future<List<int>> Function() loadBytes,
  ) async {
    final sourceType = FileUtils.detectSourceType(sourceKey);
    final existingFile = await getFileFromDisk(sourceKey, sourceType, config);
    if (existingFile != null) {
      FileUtils.log(config, 'Disk cache hit: ${existingFile.path}');
      return existingFile;
    }

    final targetFile = await _getManagedFile(sourceKey, config);
    final tempFile = File('${targetFile.path}.part');

    try {
      final bytes = await loadBytes();
      await tempFile.parent.create(recursive: true);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await tempFile.writeAsBytes(bytes, flush: true);

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final storedFile = await tempFile.rename(targetFile.path);
      FileUtils.log(config, 'Stored file on disk: ${storedFile.path}');
      return storedFile;
    } on UniversalFileHandlerException {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } catch (error, stackTrace) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw FileLoadException(
        'Failed to cache "$sourceKey".',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<File> _getManagedFile(String sourceKey, FileConfig config) async {
    final directory = await _getBaseDirectory(cache: config.cache);
    final fileName = FileUtils.buildManagedFileName(sourceKey);
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<Directory> _getBaseDirectory({required bool cache}) async {
    final rootDirectory = cache
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final directory = Directory(
      '${rootDirectory.path}${Platform.pathSeparator}universal_file_handler',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<List<int>> _downloadBytes(Uri uri, FileConfig config) async {
    try {
      FileUtils.log(config, 'Downloading file: $uri');

      final response = await _client
          .get(uri, headers: config.headers)
          .timeout(config.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FileDownloadException(
          'Failed to download "$uri" (HTTP ${response.statusCode}).',
        );
      }

      return response.bodyBytes;
    } on TimeoutException catch (error, stackTrace) {
      throw FileDownloadException(
        'Timed out while downloading "$uri".',
        cause: error,
        stackTrace: stackTrace,
      );
    } on SocketException catch (error, stackTrace) {
      throw FileDownloadException(
        'Network error while downloading "$uri".',
        cause: error,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      throw FileDownloadException(
        'HTTP client error while downloading "$uri".',
        cause: error,
        stackTrace: stackTrace,
      );
    } on UniversalFileHandlerException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileDownloadException(
        'Unexpected error while downloading "$uri".',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
