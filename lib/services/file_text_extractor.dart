import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:flutter/services.dart' show MissingPluginException;
// Note: xlsx extraction implemented via archive + xml parsing (no excel package)

class FileTextExtractor {
  /// Extracts plain text from common document types.
  /// Supports: pdf, docx, pptx, xlsx, txt
  static Future<String> extractText(File file) async {
    final path = file.path.toLowerCase();

    try {
      if (path.endsWith('.pdf')) {
        return await _extractPdf(file);
      } else if (path.endsWith('.docx')) {
        return await _extractDocx(file);
      } else if (path.endsWith('.pptx')) {
        return await _extractPptx(file);
      } else if (path.endsWith('.xlsx')) {
        return await _extractXlsx(file);
      } else if (path.endsWith('.txt')) {
        return await file.readAsString();
      } else {
        // Unknown type: try reading as text
        try {
          return await file.readAsString();
        } catch (_) {
          return '';
        }
      }
    } catch (e) {
      print('Error extracting file text: $e');
      return '';
    }
  }

  static Future<String> _extractPdf(File file) async {
    try {
      final doc = await PDFDoc.fromFile(file);
      final text = await doc.text;
      return text;
    } catch (e) {
      // If plugin isn't registered (common after hot-reload), rethrow so UI can handle
      if (e is MissingPluginException) {
        print('PDF extract MissingPluginException: $e');
        throw e;
      }
      print('PDF extract error: $e');
      return '';
    }
  }

  static Future<String> _extractDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentEntry = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, []),
      );

      if (documentEntry.name.isEmpty) return '';

      final content = utf8.decode(documentEntry.content as List<int>);
      final document = xml.XmlDocument.parse(content);

      final buffer = StringBuffer();
      for (final node in document.findAllElements('t')) {
        buffer.write(node.text);
        buffer.write(' ');
      }
      return buffer.toString().trim();
    } catch (e) {
      print('DOCX extract error: $e');
      return '';
    }
  }

  static Future<String> _extractPptx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final buffer = StringBuffer();

      for (final f in archive.files) {
        if (f.name.toLowerCase().startsWith('ppt/slides/slide') &&
            f.name.toLowerCase().endsWith('.xml')) {
          final content = utf8.decode(f.content as List<int>);
          final doc = xml.XmlDocument.parse(content);
          for (final node in doc.findAllElements('t')) {
            buffer.write(node.text);
            buffer.write(' ');
          }
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      print('PPTX extract error: $e');
      return '';
    }
  }

  static Future<String> _extractXlsx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find shared strings (optional) and sheets
      String? sharedStringsXml;
      final sheetXmls = <String>[];

      for (final f in archive.files) {
        final name = f.name.toLowerCase();
        if (name == 'xl/sharedstrings.xml') {
          sharedStringsXml = utf8.decode(f.content as List<int>);
        }
        if (name.startsWith('xl/worksheets/sheet') && name.endsWith('.xml')) {
          sheetXmls.add(utf8.decode(f.content as List<int>));
        }
      }

      final sharedValues = <String>[];
      if (sharedStringsXml != null) {
        try {
          final doc = xml.XmlDocument.parse(sharedStringsXml);
          for (final si in doc.findAllElements('si')) {
            final buffer = StringBuffer();
            for (final t in si.findAllElements('t')) {
              buffer.write(t.text);
            }
            sharedValues.add(buffer.toString());
          }
        } catch (_) {}
      }

      final buffer = StringBuffer();
      for (final sheetContent in sheetXmls) {
        try {
          final doc = xml.XmlDocument.parse(sheetContent);
          for (final cell in doc.findAllElements('c')) {
            final t = cell.getElement('v');
            if (t == null) continue;
            final v = t.text;
            final type = cell.getAttribute('t');
            if (type == 's') {
              final idx = int.tryParse(v) ?? -1;
              if (idx >= 0 && idx < sharedValues.length) {
                buffer.write(sharedValues[idx]);
                buffer.write(' ');
              }
            } else {
              buffer.write(v);
              buffer.write(' ');
            }
          }
          buffer.write('\n');
        } catch (_) {}
      }

      return buffer.toString().trim();
    } catch (e) {
      print('XLSX extract error: $e');
      return '';
    }
  }
}
