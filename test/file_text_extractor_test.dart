import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';

Future<File> _zipFile(
  Directory directory,
  String name,
  Map<String, String> entries,
) async {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(ArchiveFile.string(entry.key, entry.value));
  }
  final bytes = ZipEncoder().encode(archive);
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ui_quiz_test_');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('extracts UTF-8 text files', () async {
    final file = File('${tempDirectory.path}/notes.txt');
    await file.writeAsString('Merhaba quiz');

    expect(await FileTextExtractor.extractText(file), 'Merhaba quiz');
  });

  test('extracts text from DOCX XML', () async {
    final file = await _zipFile(tempDirectory, 'lesson.docx', {
      'word/document.xml':
          '<w:document xmlns:w="word"><w:p><w:t>Hello</w:t><w:t>World</w:t></w:p></w:document>',
    });

    expect(await FileTextExtractor.extractText(file), 'Hello World');
  });

  test('extracts slides and reports PPTX page count', () async {
    final file = await _zipFile(tempDirectory, 'slides.pptx', {
      'ppt/slides/slide1.xml':
          '<p:sld xmlns:p="p"><a:t xmlns:a="a">One</a:t></p:sld>',
      'ppt/slides/slide2.xml':
          '<p:sld xmlns:p="p"><a:t xmlns:a="a">Two</a:t></p:sld>',
    });

    expect(await FileTextExtractor.extractText(file), contains('One'));
    expect(await FileTextExtractor.extractText(file), contains('Two'));
    expect(await FileTextExtractor.getPageCount(file), 2);
  });

  test('extracts shared strings and numeric cells from XLSX', () async {
    final file = await _zipFile(tempDirectory, 'sheet.xlsx', {
      'xl/sharedStrings.xml': '<sst><si><t>Name</t></si></sst>',
      'xl/worksheets/sheet1.xml':
          '<worksheet><c t="s"><v>0</v></c><c><v>42</v></c></worksheet>',
    });

    expect(await FileTextExtractor.extractText(file), 'Name 42');
  });
}
