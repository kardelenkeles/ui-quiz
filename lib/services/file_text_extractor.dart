import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show MissingPluginException, Uint8List;
// Note: xlsx extraction implemented via archive + xml parsing (no excel package)

class FileTextExtractor {
  /// Extracts plain text from common document types.
  /// Supports: pdf, docx, pptx, xlsx, txt
  static Future<String> extractText(File file, {List<int>? pages}) async {
    final path = file.path.toLowerCase();

    try {
      if (path.endsWith('.pdf')) {
        return await _extractPdf(file, pages: pages);
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

  static Future<String> _extractPdf(File file, {List<int>? pages}) async {
    try {
      final doc = await PDFDoc.fromFile(file);
      if (pages == null || pages.isEmpty) {
        final text = await doc.text;
        return text;
      }

      final buffer = StringBuffer();
      try {
        for (final p in pages) {
          try {
            // PDFDoc page indices are 1-based in some implementations
            final pageObj = await doc.pageAt(p);
            final pageText = await pageObj.text;
            buffer.writeln(pageText);
          } catch (_) {
            // ignore individual page failures
          }
        }
        final result = buffer.toString().trim();
        if (result.isNotEmpty) return result;
      } catch (_) {}

      // Fallback to whole-document text
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

  /// Generates a PNG preview for common files.
  /// For PDFs it rasterizes the actual page. For other document types it
  /// renders a short text snippet into a one-page PDF and rasterizes that.
  /// Returns PNG bytes or null on failure.
  static Future<Uint8List?> getFilePreviewImage(
    File file, {
    int page = 1,
    int width = 300,
  }) async {
    final path = file.path.toLowerCase();
    try {
      // If the file is an image, return its bytes directly
      if (path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png')) {
        return await file.readAsBytes();
      }
      if (path.endsWith('.pdf')) {
        final pdfBytes = await file.readAsBytes();
        final stream = Printing.raster(pdfBytes, pages: [page - 1], dpi: 72);
        await for (final pdfRaster in stream) {
          return await pdfRaster.toPng();
        }
        return null;
      }

      // For other types, render a short snippet to a one-page PDF and rasterize it
      String snippet = '';
      if (path.endsWith('.docx'))
        snippet = (await _extractDocx(file)).trim();
      else if (path.endsWith('.pptx'))
        snippet = (await _extractPptx(file)).trim();
      else if (path.endsWith('.xlsx'))
        snippet = (await _extractXlsx(file)).trim();
      else if (path.endsWith('.txt'))
        snippet = (await file.readAsString()).trim();
      else
        snippet = await extractText(file);

      if (snippet.isEmpty) snippet = file.uri.pathSegments.last;

      // limit snippet length
      final maxLen = 800;
      if (snippet.length > maxLen)
        snippet = snippet.substring(0, maxLen) + '...';

      final pdfBytes = await _renderTextSnippetToPdfBytes(snippet);
      final stream = Printing.raster(pdfBytes, pages: [0], dpi: 72);
      await for (final pdfRaster in stream) {
        return await pdfRaster.toPng();
      }
      return null;
    } catch (e) {
      print('getFilePreviewImage error: $e');
      return null;
    }
  }

  /// Returns the number of pages/slides for supported file types.
  /// PDF and PPTX are supported. Returns null if unavailable.
  static Future<int?> getPageCount(File file) async {
    final path = file.path.toLowerCase();
    try {
      if (path.endsWith('.pdf')) {
        // Use flutter_pdf_text to get page count for PDFs.
        // (pdfrx usage was removed because its API varies across versions.)
        final doc = await PDFDoc.fromFile(file);
        return doc.length;
      }

      if (path.endsWith('.pptx')) {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final slideFiles = archive.files
            .where(
              (f) =>
                  f.name.toLowerCase().startsWith('ppt/slides/slide') &&
                  f.name.toLowerCase().endsWith('.xml'),
            )
            .toList();
        return slideFiles.length;
      }

      return null;
    } catch (e) {
      print('getPageCount error: $e');
      return null;
    }
  }

  static Future<Uint8List> _renderTextSnippetToPdfBytes(String text) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(text, style: pw.TextStyle(fontSize: 12)),
          );
        },
      ),
    );
    return await doc.save();
  }
}
