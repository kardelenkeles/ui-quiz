import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_quiz/services/file_text_extractor.dart';

// Full-screen page picker screen which mirrors the previous bottom-sheet UI.
class PagePickerScreen extends StatefulWidget {
  final File selectedFile;
  final int pageCount;
  final List<int> initialSelectedPages;
  final Map<int, Uint8List?> initialPreviewCache;
  final int maxSelectable;

  const PagePickerScreen({
    Key? key,
    required this.selectedFile,
    required this.pageCount,
    required this.initialSelectedPages,
    required this.initialPreviewCache,
    required this.maxSelectable,
  }) : super(key: key);

  @override
  State<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends State<PagePickerScreen> {
  late List<int> selectedPages;
  late Map<int, Uint8List?> previewCache;
  late TextEditingController startController;
  late TextEditingController endController;

  @override
  void initState() {
    super.initState();
    selectedPages = List<int>.from(widget.initialSelectedPages);
    previewCache = Map<int, Uint8List?>.from(widget.initialPreviewCache);
    startController = TextEditingController(
      text: (selectedPages.isNotEmpty ? selectedPages.first : 1).toString(),
    );
    endController = TextEditingController(
      text: (selectedPages.isNotEmpty ? selectedPages.last : widget.pageCount)
          .toString(),
    );
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  void _applyRange() {
    final safePageCount = widget.pageCount < 1 ? 1 : widget.pageCount;
    int start = int.tryParse(startController.text) ?? 1;
    int end = int.tryParse(endController.text) ?? safePageCount;
    start = start.clamp(1, safePageCount);
    end = end.clamp(1, safePageCount);
    if (end < start) {
      final tmp = start;
      start = end;
      end = tmp;
    }
    final list = List<int>.generate(
      end - start + 1,
      (i) => start + i,
    ).take(widget.maxSelectable).toList();
    setState(() {
      selectedPages = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: PopScope(
        canPop: false, // Prevent automatic popping
        onPopInvoked: (didPop) {
          if (didPop) return;

          if (selectedPages.isEmpty) {
            // Show warning dialog if no pages selected
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Uyarı'),
                content: const Text('En az bir sayfa seçmelisiniz.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          } else {
            Navigator.of(context).pop({
              'selectedPages': selectedPages,
              'previewCache': previewCache,
            });
          }
        },
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Sayfaları seçin (maks ${widget.maxSelectable})'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (selectedPages.isEmpty) {
                  // Show warning dialog if no pages selected
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('Uyarı'),
                      content: const Text('En az bir sayfa seçmelisiniz.'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.of(context).pop({
                    'selectedPages': selectedPages,
                    'previewCache': previewCache,
                  });
                }
              },
              child: const Text('Tamam'),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Input controls - shrink to fit content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Başlangıç',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CupertinoTextField(
                                  controller: startController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (_) => _applyRange(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bitiş',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CupertinoTextField(
                                  controller: endController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (_) => _applyRange(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seçili aralık: ${selectedPages.isEmpty ? 'Yok' : '${selectedPages.first}-${selectedPages.last} (${selectedPages.length})'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid view - takes remaining space
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: widget.pageCount,
                    itemBuilder: (context, index) {
                      final pageIndex = index + 1;
                      final bytes = previewCache[pageIndex];

                      if (bytes == null) {
                        FileTextExtractor.getFilePreviewImage(
                          widget.selectedFile,
                          page: pageIndex,
                          width: 300,
                        ).then((b) {
                          if (!mounted) return;
                          setState(() {
                            previewCache[pageIndex] = b;
                          });
                        });
                      }

                      final selected = selectedPages.contains(pageIndex);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              selectedPages.remove(pageIndex);
                            } else {
                              if (selectedPages.length < widget.maxSelectable) {
                                selectedPages.add(pageIndex);
                              } else {
                                // Show a simple Cupertino alert as a transient replacement for SnackBar
                                showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    content: const Text(
                                      'Maksimum sayfa seçimi aşıldı.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('Tamam'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? Colors.blueAccent
                                      : Colors.grey.shade300,
                                  width: selected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: bytes != null
                                  ? Image.memory(bytes, fit: BoxFit.cover)
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: selected
                                    ? Colors.blue
                                    : Colors.white70,
                                child: Text(
                                  '$pageIndex',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom action buttons - fixed height
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          onPressed: () {
                            setState(() {
                              selectedPages = [];
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.clear_circled,
                                size: 16,
                                color: Colors.lime,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hiçbiri',
                                style: TextStyle(color: Colors.lime),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            setState(() {
                              selectedPages = List.generate(
                                widget.pageCount,
                                (i) => i + 1,
                              ).take(widget.maxSelectable).toList();
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.checkmark_circle,
                                size: 16,
                                color: Colors.lime,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hepsi',
                                style: TextStyle(color: Colors.lime),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
