# Universal File Handler

A Flutter package to open, view, cache, and share files such as PDF, images, Word, and Excel. Supports network, asset, and local file handling.

## Overview

Universal File Handler helps you easily open and manage different file types in Flutter apps with a single API.

## Features

- Open images, PDFs, Word, and Excel files
- Smart memory and disk caching
- File type detection
- Share files easily
- Supports network, asset, and local files

## Keywords

Flutter file opener, Flutter open PDF, Flutter open image, Flutter document viewer, Flutter share file, Flutter Excel viewer, Flutter Word file opener, Flutter file cache

---

## Flutter Open PDF

Open and view PDF files directly inside your Flutter app.

## Flutter Open Image

View images using a built-in image viewer.

## Flutter File Sharing

Share any file (PDF, image, Word, Excel) easily.

## Flutter File Cache System

Automatically cache files for faster access and offline usage.

---

## Usage

### Open File

```dart
await UniversalFileHandler.open(
  context,
  fileUrl,
);

// Share file in Flutter
await UniversalFileHandler.share(fileUrl);

ElevatedButton(
  onPressed: () {
    UniversalFileHandler.open(context,fileUrl);
  },
  child: Text("Open File"),
);


## Example

import 'package:flutter/material.dart';
import 'package:universal_file_handler/universal_file_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal File Handler Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FileExamplePage(),
    );
  }
}

class FileExamplePage extends StatelessWidget {
  const FileExamplePage({super.key});

  static const imageUrl =
      "https://picsum.photos/400/600";

  static const pdfUrl =
      "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";

  static const excelUrl =
      "https://github.com/sagar9098/universal_file_handler/tree/master/example/assets/excel.xlsx";

  static const wordUrl =
      "https://github.com/sagar9098/universal_file_handler/tree/master/example/assets/word.doc";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Handler Example")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          ///  PREPARE FILE (Download + Cache)
          ElevatedButton(
            onPressed: () async {
              final file = await UniversalFileHandler.prepareFile(pdfUrl);
              debugPrint("Saved at: ${file.path}");
            },
            child: const Text("Download & Cache PDF"),
          ),

          const SizedBox(height: 10),

          ///  OPEN IMAGE
          ElevatedButton(
            onPressed: () async {
              await UniversalFileHandler.open(context,
                imageUrl,
              );
            },
            child: const Text("Open Image"),
          ),

          const SizedBox(height: 10),

          /// OPEN PDF
          ElevatedButton(
            onPressed: () async {
              await UniversalFileHandler.open(context,
                pdfUrl,
              );
            },
            child: const Text("Open PDF"),
          ),

          const SizedBox(height: 10),

          ///  OPEN EXCEL (External App Required)
          ElevatedButton(
            onPressed: () async {
              await UniversalFileHandler.open(context,excelUrl);
            },
            child: const Text("Open Excel"),
          ),

          const SizedBox(height: 10),

          ///  OPEN WORD (External App Required)
          ElevatedButton(
            onPressed: () async {
              await UniversalFileHandler.open(context,wordUrl);
            },
            child: const Text("Open Word"),
          ),

          const SizedBox(height: 10),

          ///  SHARE FILE
          ElevatedButton(
            onPressed: () async {
              await UniversalFileHandler.share(pdfUrl);
            },
            child: const Text("Share PDF"),
          ),

          const SizedBox(height: 10),

          ///  ASSET FILE TEST
          ElevatedButton(
            onPressed: () async {
              if(UniversalFileHandler.getFileType("assets/sample.jpg")==FileType.image) {
                await UniversalFileHandler.open(context,
                  "assets/sample.jpg",
                );
              }
            },
            child: const Text("Open Asset Image"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if(UniversalFileHandler.getFileType("assets/word.doc")==FileType.word) {
                await UniversalFileHandler.open(context,
                  "assets/word.doc",
                );
              }
            },
            child: const Text("Open Asset Word File"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if(UniversalFileHandler.getFileType("assets/excel.xlsx")==FileType.excel) {
                await UniversalFileHandler.open(context,
                  "assets/excel.xlsx",
                );
              }
            },
            child: const Text("Open Asset Excel File"),
          ),
        ],
      ),
    );
  }
}