import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/file_config.dart';
import 'file_type.dart';

enum FileSourceType { network, asset, local }

class UniversalFileHandlerException implements Exception {
  const UniversalFileHandlerException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class InvalidFileSourceException extends UniversalFileHandlerException {
  const InvalidFileSourceException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class FileLoadException extends UniversalFileHandlerException {
  const FileLoadException(super.message, {super.cause, super.stackTrace});
}

class SourceFileNotFoundException extends UniversalFileHandlerException {
  const SourceFileNotFoundException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class FileDownloadException extends UniversalFileHandlerException {
  const FileDownloadException(super.message, {super.cause, super.stackTrace});
}

class FileOpenException extends UniversalFileHandlerException {
  const FileOpenException(super.message, {super.cause, super.stackTrace});
}

class FileShareException extends UniversalFileHandlerException {
  const FileShareException(super.message, {super.cause, super.stackTrace});
}

class FileUtils {
  static final RegExp _httpSchemePattern = RegExp(
    r'^https?:',
    caseSensitive: false,
  );
  static final RegExp _invalidFileNamePattern = RegExp(r'[^A-Za-z0-9._-]+');
  static final RegExp _duplicateUnderscorePattern = RegExp(r'_+');

  static String normalizeSource(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) {
      throw const InvalidFileSourceException('Source cannot be empty.');
    }
    return normalized;
  }

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

  static bool isNetworkUrl(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) {
      return false;
    }

    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.hasAuthority;
  }

  static bool isAssetPath(String source) {
    final normalized = _stripLeadingCurrentDirectory(normalizeSource(source));
    return normalized.startsWith('assets/') ||
        normalized.startsWith('packages/');
  }

  static Uri parseNetworkUri(String source) {
    final normalized = normalizeSource(source);
    if (!isNetworkUrl(normalized)) {
      throw InvalidFileSourceException('Invalid network URL: "$source".');
    }
    return Uri.parse(normalized);
  }

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

  static File resolveLocalFile(String source) {
    final normalized = normalizeSource(source);
    final uri = Uri.tryParse(normalized);

    if (uri != null && uri.scheme.toLowerCase() == 'file') {
      return File.fromUri(uri);
    }

    return File(normalized).absolute;
  }

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

  static String extractExtension(String source, {String? assetPackage}) {
    final fileName = extractFileName(source, assetPackage: assetPackage);
    return _extensionFromFileName(fileName);
  }

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

  static String stableHash(String input) {
    var hash = 2166136261;

    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }

    return hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

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
