import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../core/file_utils.dart';

/// Wraps platform sharing for resolved files.
class ShareService {
  /// Creates a share service.
  const ShareService();

  /// Shares [file] with the platform share sheet.
  ///
  /// Optional [text] and [subject] values are forwarded to the share request.
  Future<void> shareFile(File file, {String? text, String? subject}) async {
    if (!await file.exists()) {
      throw SourceFileNotFoundException(
        'Cannot share a file that does not exist: "${file.path}".',
      );
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text: text,
          subject: subject,
        ),
      );

      if (result.status == ShareResultStatus.unavailable) {
        throw const FileShareException(
          'Sharing is unavailable on this platform.',
        );
      }
    } on UniversalFileHandlerException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileShareException(
        'Failed to share "${file.path}".',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
