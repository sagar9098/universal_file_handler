import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../universal_file_handler.dart';


class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.file, this.title});

  final File file;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : FileUtils.extractFileName(file.path);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(resolvedTitle),
        actions: [
          IconButton(
            onPressed: () {
              UniversalFileHandler.share(file.path);
            },
            icon: Icon(Icons.share),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(file),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        loadingBuilder: (context, event) {
          final expectedBytes = event?.expectedTotalBytes;
          final loadedBytes = event?.cumulativeBytesLoaded;
          final progress =
              expectedBytes == null || expectedBytes == 0 || loadedBytes == null
              ? null
              : loadedBytes / expectedBytes;

          return Center(
            child: CircularProgressIndicator.adaptive(
              value: progress,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to render this image.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
