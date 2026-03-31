import 'dart:io';

/// Stores resolved files in memory for fast reuse during the app session.
class MemoryCacheService {
  MemoryCacheService._();

  /// Shared in-memory cache instance used by the package.
  static final MemoryCacheService instance = MemoryCacheService._();

  final Map<String, File> _cache = <String, File>{};

  /// Returns the cached file for [key] when it is still available on disk.
  File? get(String key) {
    final file = _cache[key];
    if (file == null) {
      return null;
    }

    if (!file.existsSync()) {
      _cache.remove(key);
      return null;
    }

    return file;
  }

  /// Stores [file] in memory under [key].
  void set(String key, File file) {
    _cache[key] = file;
  }

  /// Removes the cached file associated with [key].
  File? remove(String key) {
    return _cache.remove(key);
  }

  /// Clears every file stored in memory.
  void clear() {
    _cache.clear();
  }
}
