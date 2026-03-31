import 'dart:io';

class MemoryCacheService {
  MemoryCacheService._();

  static final MemoryCacheService instance = MemoryCacheService._();

  final Map<String, File> _cache = <String, File>{};

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

  void set(String key, File file) {
    _cache[key] = file;
  }

  File? remove(String key) {
    return _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}
