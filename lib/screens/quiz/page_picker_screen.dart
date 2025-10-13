import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Full-screen page picker screen for selecting page ranges
class PagePickerScreen extends StatefulWidget {
  final File selectedFile;
  final int pageCount;
  final List<int> initialSelectedPages;
  final int maxSelectable;

  const PagePickerScreen({
    Key? key,
    required this.selectedFile,
    required this.pageCount,
    required this.initialSelectedPages,
    required this.maxSelectable,
  }) : super(key: key);

  @override
  State<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends State<PagePickerScreen> {
  late List<int> selectedPages;
  late TextEditingController startController;
  late TextEditingController endController;

  @override
  void initState() {
    super.initState();
    selectedPages = List<int>.from(widget.initialSelectedPages);
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'İptal',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (selectedPages.isEmpty) {
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text(
                    'Uyarı',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      decoration: TextDecoration.none,
                    ),
                  ),
                  content: const Text(
                    'En az bir sayfa seçmelisiniz.',
                    style: TextStyle(fontFamily: 'Nunito'),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(fontFamily: 'Nunito'),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop({'selectedPages': selectedPages});
            }
          },
          child: const Text(
            'Tamam',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Başlık kutusu - diğer sayfalarla tutarlı
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                    child: Column(
                      children: [
                        Text(
                          'Sayfa Aralığı Seç',
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Maksimum ${widget.maxSelectable} sayfa seçebilirsiniz',
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Input controls - app tasarımına uygun
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Başlangıç Sayfası',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Nunito',
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: CupertinoColors.systemGrey4,
                                        width: 1,
                                      ),
                                    ),
                                    child: CupertinoTextField(
                                      controller: startController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (_) => _applyRange(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: null,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bitiş Sayfası',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Nunito',
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: CupertinoColors.systemGrey4,
                                        width: 1,
                                      ),
                                    ),
                                    child: CupertinoTextField(
                                      controller: endController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (_) => _applyRange(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: null,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Seçili: ${selectedPages.isEmpty ? 'Sayfa seçilmedi' : '${selectedPages.first}-${selectedPages.last} (${selectedPages.length} sayfa)'}',
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              color: CupertinoColors.systemBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dosya bilgileri - app tasarımına uygun
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.doc_text_fill,
                            size: 32,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.selectedFile.path.split('/').last,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: CupertinoColors.black,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Toplam Sayfa',
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.pageCount}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: CupertinoColors.systemGrey4,
                            ),
                            Column(
                              children: [
                                Text(
                                  'Seçili Sayfa',
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${selectedPages.length}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Alt butonlar - app tasarımına uygun
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  selectedPages = [];
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    CupertinoIcons.clear_circled,
                                    size: 18,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hiçbiri',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  selectedPages = List.generate(
                                    widget.pageCount,
                                    (i) => i + 1,
                                  ).take(widget.maxSelectable).toList();
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hepsini Seç',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
