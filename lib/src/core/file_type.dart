/// Supported file categories used by the package.
enum FileType {
  /// Common image formats such as PNG, JPEG, GIF, and WebP.
  image,

  /// Portable Document Format files.
  pdf,

  /// Word processing documents such as DOC and DOCX files.
  word,

  /// Spreadsheet files such as XLS and XLSX documents.
  excel,

  /// A file that does not match one of the known categories.
  unknown,
}

/// Convenience metadata for [FileType] values.
extension FileTypeX on FileType {
  /// Whether this file type is intended to be previewed inside the app UI.
  bool get isPreviewableInApp => this == FileType.image || this == FileType.pdf;

  /// Whether this file type is typically opened with a platform app.
  bool get usesExternalOpener => !isPreviewableInApp;

  /// A lowercase label for the current file type.
  String get label {
    switch (this) {
      case FileType.image:
        return 'image';
      case FileType.pdf:
        return 'pdf';
      case FileType.word:
        return 'word';
      case FileType.excel:
        return 'excel';
      case FileType.unknown:
        return 'unknown';
    }
  }
}
