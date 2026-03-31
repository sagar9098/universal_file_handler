class FileConfig {
  const FileConfig({
    this.cache = true,
    this.enableLog = false,
    this.headers = const <String, String>{},
    this.timeout = const Duration(seconds: 30),
    this.assetPackage,
  });

  final bool cache;
  final bool enableLog;
  final Map<String, String> headers;
  final Duration timeout;
  final String? assetPackage;

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
