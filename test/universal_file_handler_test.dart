import 'package:flutter_test/flutter_test.dart';

import 'package:universal_file_handler/universal_file_handler.dart';

void main() {
  test('detects supported file types from common extensions', () {
    expect(
      FileUtils.detectFileType('https://example.com/avatar.png'),
      FileType.image,
    );
    expect(FileUtils.detectFileType('assets/docs/report.pdf'), FileType.pdf);
    expect(FileUtils.detectFileType(r'C:\docs\proposal.docx'), FileType.word);
    expect(FileUtils.detectFileType('/files/budget.xlsx'), FileType.excel);
    expect(FileUtils.detectFileType('archive.bin'), FileType.unknown);
  });

  test('creates stable cache keys for asset sources', () {
    expect(
      FileUtils.buildCacheKey(
        'assets/files/manual.pdf',
        assetPackage: 'universal_file_handler',
      ),
      'packages/universal_file_handler/assets/files/manual.pdf',
    );
  });

  test('builds smart cache file names without losing extensions', () {
    final managedName = FileUtils.buildManagedFileName(
      'https://example.com/files/report.final.pdf?download=1',
    );

    expect(managedName, matches(RegExp(r'^report\.final_[0-9a-f]{8}\.pdf$')));
  });

  test('file config copyWith preserves unspecified values', () {
    const config = FileConfig(
      cache: true,
      enableLog: false,
      timeout: Duration(seconds: 20),
      assetPackage: 'pkg_name',
    );

    final updated = config.copyWith(enableLog: true);

    expect(updated.cache, isTrue);
    expect(updated.enableLog, isTrue);
    expect(updated.timeout, const Duration(seconds: 20));
    expect(updated.assetPackage, 'pkg_name');
  });
}
