import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../universal_file_handler.dart';

class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key, required this.file, this.title});

  final File file;
  final String? title;

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  bool _isReady = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : FileUtils.extractFileName(widget.file.path);

    return Scaffold(
      appBar: AppBar(title: Text(resolvedTitle),
        actions: [
          IconButton(
            onPressed: () {
              UniversalFileHandler.share(widget.file.path);
            },
            icon: Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.file.path,
            onRender: (pages) {
              if (!mounted) {
                return;
              }

              setState(() {
                _totalPages = pages ?? 0;
                _isReady = true;
              });
            },
            onPageChanged: (page, total) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? _totalPages;
              });
            },
            onError: (error) {
              if (!mounted) {
                return;
              }

              setState(() {
                _errorMessage = '$error';
                _isReady = true;
              });
            },
            onPageError: (page, error) {
              if (!mounted) {
                return;
              }

              setState(() {
                _errorMessage = 'Failed to render page ${page ?? '-'}: $error';
                _isReady = true;
              });
            },
          ),
          if (!_isReady && _errorMessage == null)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
            ),
          if (_isReady && _errorMessage == null && _totalPages > 0)
            Positioned(
              bottom: 16,
              right: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
