enum FileType { image, pdf, word, excel, unknown }

extension FileTypeX on FileType {
  bool get isPreviewableInApp => this == FileType.image || this == FileType.pdf;

  bool get usesExternalOpener => !isPreviewableInApp;

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
