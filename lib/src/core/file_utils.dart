import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/file_config.dart';
import 'file_type.dart';

/// Supported source categories for incoming file references.
enum FileSourceType {
  /// A remote HTTP or HTTPS URL.
  network,

  /// A Flutter asset path.
  asset,

  /// A path or file URI on the local device.
  local,
}

/// Base exception for errors raised by this package.
class UniversalFileHandlerException implements Exception {
  /// Creates an exception with a message and optional underlying details.
  const UniversalFileHandlerException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Human-readable description of the failure.
  final String message;

  /// Original error object, if one is available.
  final Object? cause;

  /// Stack trace captured when the exception was created.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a provided file source cannot be interpreted.
class InvalidFileSourceException extends UniversalFileHandlerException {
  /// Creates an invalid source exception.
  const InvalidFileSourceException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a file cannot be loaded into managed storage.
class FileLoadException extends UniversalFileHandlerException {
  /// Creates a file load exception.
  const FileLoadException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when an expected file cannot be found.
class SourceFileNotFoundException extends UniversalFileHandlerException {
  /// Creates a file not found exception.
  const SourceFileNotFoundException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a network download fails.
class FileDownloadException extends UniversalFileHandlerException {
  /// Creates a download exception.
  const FileDownloadException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a file cannot be opened for the user.
class FileOpenException extends UniversalFileHandlerException {
  /// Creates a file open exception.
  const FileOpenException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a share request cannot be completed.
class FileShareException extends UniversalFileHandlerException {
  /// Creates a file share exception.
  const FileShareException(super.message, {super.cause, super.stackTrace});
}

/// Helper methods for working with supported file sources and cache keys.
class FileUtils {
  static final RegExp _httpSchemePattern = RegExp(
    r'^https?:',
    caseSensitive: false,
  );
  static final RegExp _invalidFileNamePattern = RegExp(r'[^A-Za-z0-9._-]+');
  static final RegExp _duplicateUnderscorePattern = RegExp(r'_+');

  /// Returns a trimmed source string and rejects empty values.
  static String normalizeSource(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) {
      throw const InvalidFileSourceException('Source cannot be empty.');
    }
    return normalized;
  }

  /// Detects whether [source] points to a network URL, asset, or local file.
  static FileSourceType detectSourceType(String source) {
    final normalized = normalizeSource(source);

    if (_httpSchemePattern.hasMatch(normalized) && !isNetworkUrl(normalized)) {
      throw InvalidFileSourceException('Invalid network URL: "$source".');
    }

    if (isNetworkUrl(normalized)) {
      return FileSourceType.network;
    }

    if (isAssetPath(normalized)) {
      return FileSourceType.asset;
    }

    return FileSourceType.local;
  }

  /// Returns `true` when [source] is a valid HTTP or HTTPS URL.
  static bool isNetworkUrl(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) {
      return false;
    }

    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.hasAuthority;
  }

  /// Returns `true` when [source] looks like a Flutter asset path.
  static bool isAssetPath(String source) {
    final normalized = _stripLeadingCurrentDirectory(normalizeSource(source));
    return normalized.startsWith('assets/') ||
        normalized.startsWith('packages/');
  }

  /// Parses [source] as a validated network URI.
  static Uri parseNetworkUri(String source) {
    final normalized = normalizeSource(source);
    if (!isNetworkUrl(normalized)) {
      throw InvalidFileSourceException('Invalid network URL: "$source".');
    }
    return Uri.parse(normalized);
  }

  /// Resolves an asset lookup key, optionally prefixing it with [packageName].
  static String resolveAssetKey(String source, {String? packageName}) {
    final normalized = _stripLeadingCurrentDirectory(normalizeSource(source));

    if (normalized.startsWith('packages/')) {
      return normalized;
    }

    final trimmedPackageName = packageName?.trim();
    if (trimmedPackageName == null || trimmedPackageName.isEmpty) {
      return normalized;
    }

    return 'packages/$trimmedPackageName/$normalized';
  }

  /// Converts a local path or file URI into a [File] instance.
  static File resolveLocalFile(String source) {
    final normalized = normalizeSource(source);
    final uri = Uri.tryParse(normalized);

    if (uri != null && uri.scheme.toLowerCase() == 'file') {
      return File.fromUri(uri);
    }

    return File(normalized).absolute;
  }

  /// Builds a normalized cache key for any supported [source].
  static String buildCacheKey(String source, {String? assetPackage}) {
    switch (detectSourceType(source)) {
      case FileSourceType.network:
        return Uri.parse(normalizeSource(source)).toString();
      case FileSourceType.asset:
        return resolveAssetKey(source, packageName: assetPackage);
      case FileSourceType.local:
        return resolveLocalFile(source).path;
    }
  }

  /// Extracts a filename from [source], falling back to [fallback] when needed.
  static String extractFileName(
    String source, {
    String fallback = 'file',
    String? assetPackage,
  }) {
    final normalized = normalizeSource(source);
    late final String fileName;

    switch (detectSourceType(normalized)) {
      case FileSourceType.network:
        fileName =
            _lastNonEmptySegment(Uri.parse(normalized).pathSegments) ?? '';
        break;
      case FileSourceType.asset:
        fileName = _basename(
          resolveAssetKey(normalized, packageName: assetPackage),
        );
        break;
      case FileSourceType.local:
        fileName = _basename(resolveLocalFile(normalized).path);
        break;
    }

    final trimmedFileName = fileName.trim();
    return trimmedFileName.isEmpty ? fallback : trimmedFileName;
  }

  /// Returns the lowercase extension for [source] without the leading dot.
  static String extractExtension(String source, {String? assetPackage}) {
    final fileName = extractFileName(source, assetPackage: assetPackage);
    return _extensionFromFileName(fileName);
  }

  /// Detects the [FileType] for [source] using its extension.
  static FileType detectFileType(String source) {
    switch (extractExtension(source)) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'heic':
      case 'heif':
      case 'svg':
        return FileType.image;
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
      case 'dot':
      case 'dotx':
      case 'odt':
        return FileType.word;
      case 'xls':
      case 'xlsx':
      case 'xlsm':
      case 'csv':
      case 'ods':
        return FileType.excel;
      default:
        return FileType.unknown;
    }
  }

  /// Builds a stable, file-system-safe name for managed cache storage.
  static String buildManagedFileName(String source, {String? assetPackage}) {
    final sanitizedFileName = sanitizeFileName(
      extractFileName(source, assetPackage: assetPackage),
    );
    final baseName = _baseNameWithoutExtension(sanitizedFileName);
    final extension = _extensionFromFileName(sanitizedFileName);
    final compactBaseName = baseName.length > 60
        ? baseName.substring(0, 60)
        : baseName;
    final shortHash = stableHash(
      buildCacheKey(source, assetPackage: assetPackage),
    );

    if (extension.isEmpty) {
      return '${compactBaseName}_$shortHash';
    }

    return '${compactBaseName}_$shortHash.$extension';
  }

  /// Removes unsupported characters from a filename.
  static String sanitizeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'file';
    }

    final fileNameOnly = trimmed.replaceAll('\\', '/').split('/').last;
    final sanitized = fileNameOnly
        .replaceAll(_invalidFileNamePattern, '_')
        .replaceAll(_duplicateUnderscorePattern, '_')
        .replaceAll(RegExp(r'^[_\.]+|[_\.]+$'), '');

    return sanitized.isEmpty ? 'file' : sanitized;
  }

  /// Returns a deterministic short hash for [input].
  static String stableHash(String input) {
    var hash = 2166136261;

    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }

    return hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

  /// Prints a package log line when [config.enableLog] is enabled.
  static void log(FileConfig config, String message) {
    if (!config.enableLog) {
      return;
    }

    debugPrint('[UniversalFileHandler] $message');
  }

  static String _stripLeadingCurrentDirectory(String source) {
    if (source.startsWith('./')) {
      return source.substring(2);
    }

    return source;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return _lastNonEmptySegment(normalized.split('/')) ?? 'file';
  }

  static String? _lastNonEmptySegment(Iterable<String> segments) {
    final values = segments.toList(growable: false);

    for (var index = values.length - 1; index >= 0; index--) {
      final value = values[index];
      if (value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static String _baseNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot <= 0) {
      return fileName;
    }

    return fileName.substring(0, lastDot);
  }

  static String _extensionFromFileName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot <= 0 || lastDot == fileName.length - 1) {
      return '';
    }

    return fileName.substring(lastDot + 1).toLowerCase();
  }
}
