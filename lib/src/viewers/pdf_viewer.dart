import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../universal_file_handler.dart';

/// Full-screen viewer for PDF files resolved by the package.
class PdfViewer extends StatefulWidget {
  /// Creates a PDF viewer for [file].
  const PdfViewer({super.key, required this.file, this.title,this.tag,this.isShare});

  /// Local PDF file to display.
  final File file;

  /// Optional title shown in the app bar.
  final String? title;

  /// Optional data for hero transitions.
  final String? tag;

  /// Optional bool for sharing icon by default true.
  final bool? isShare;
  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  bool _isReady = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  String? _password;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : FileUtils.extractFileName(widget.file.path);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          resolvedTitle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: widget.isShare==false?[]:[
          IconButton(
            onPressed: () {
              UniversalFileHandler.share(widget.file.path);
            },
            icon: Icon(Icons.share),
          ),
        ],
      ),
        body: widget.tag == null ? _buildPdf() : Hero(tag: widget.tag!, child: _buildPdf()),
    );
  }
  Widget _buildPdf(){
    return Stack(
      children: <Widget>[
        PDFView(
          key: ValueKey(_password),
          filePath: widget.file.path,
          password: _password,
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
            final errorStr = error.toString().toLowerCase();

            if (errorStr.contains('password')) {
              _askPassword(); // Show password dialog
            } else {
              setState(() {
                _errorMessage = '$error';
                _isReady = true;
              });
            }
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
    );
  }

  void _askPassword() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Enter PDF Password",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Password",
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text(
                "Open",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    if (password != null && password.isNotEmpty) {
      setState(() {
        _password = password;
        _isReady = false;
        _errorMessage = null;
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}
