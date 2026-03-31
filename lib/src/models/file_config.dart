/// Configuration used while resolving, caching, and loading files.
class FileConfig {
  /// Creates a file handling configuration.
  const FileConfig({
    this.cache = true,
    this.enableLog = false,
    this.headers = const <String, String>{},
    this.timeout = const Duration(seconds: 30),
    this.assetPackage,
  });

  /// Whether resolved files should use persistent storage instead of temp storage.
  final bool cache;

  /// Whether internal package logging should be printed with `debugPrint`.
  final bool enableLog;

  /// Optional HTTP headers used for network downloads.
  final Map<String, String> headers;

  /// Maximum time allowed for a network download request.
  final Duration timeout;

  /// Package name used when resolving assets from another package.
  final String? assetPackage;

  /// Returns a copy with the provided values replaced.
  FileConfig copyWith({
    bool? cache,
    bool? enableLog,
    Map<String, String>? headers,
    Duration? timeout,
    String? assetPackage,
  }) {
    return FileConfig(
      cache: cache ?? this.cache,
      enableLog: enableLog ?? this.enableLog,
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      assetPackage: assetPackage ?? this.assetPackage,
    );
  }
}
