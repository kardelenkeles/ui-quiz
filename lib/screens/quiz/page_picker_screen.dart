import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

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
  // Brand accent: blue with a lime/teal tint to match app's green-y accent
  final Color brandBlue = const Color(0xFF2FB3A6);
  // Slider state
  late SfRangeValues _rangeValues;

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
    // initialize range slider values
    final startInit = selectedPages.isNotEmpty ? selectedPages.first : 1;
    final endInit = selectedPages.isNotEmpty
        ? selectedPages.last
        : widget.pageCount;
    _rangeValues = SfRangeValues(startInit.toDouble(), endInit.toDouble());
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
        leading: Container(
          margin: const EdgeInsets.only(left: 8, top: 4),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(12),
            minSize: 0,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'İptal',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        trailing: Container(
          margin: const EdgeInsets.only(right: 8, top: 5),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.lime.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            minSize: 0,
            onPressed: () {
              setState(() {
                selectedPages = List.generate(
                  widget.pageCount,
                  (i) => i + 1,
                ).take(widget.maxSelectable).toList();
              });
            },
            child: const Text(
              'Hepsini Seç',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
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
                            color: brandBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Seçili: ${selectedPages.isEmpty ? 'Sayfa seçilmedi' : '${selectedPages.first}-${selectedPages.last} (${selectedPages.length} sayfa)'}',
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: brandBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Range slider (always visible)
                              SfRangeSlider(
                                min: 1.0,
                                max: (widget.pageCount <= 1)
                                    ? 1.0
                                    : widget.pageCount.toDouble(),
                                values: _rangeValues,

                                stepSize: 1.0,
                                interval: (widget.pageCount / 4)
                                    .clamp(1, widget.pageCount)
                                    .toDouble(),
                                showTicks: false,
                                showLabels: true,
                                enableTooltip: true,
                                onChanged: (SfRangeValues newValues) {
                                  setState(() {
                                    // round to ints
                                    final s = newValues.start.round();
                                    final e = newValues.end.round();
                                    _rangeValues = SfRangeValues(
                                      s.toDouble(),
                                      e.toDouble(),
                                    );
                                    startController.text = s.toString();
                                    endController.text = e.toString();
                                    // update selected pages via existing logic
                                    _applyRange();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

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
                            color: brandBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'asset/icon/documents.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,

                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    CupertinoIcons.doc_text_fill,
                                    size: 32,
                                    color: CupertinoColors.systemBlue,
                                  ),
                            ),
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
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                    color: brandBlue,
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

                  // Alt buton - Tamam (sağ alt)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 50,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.lime,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
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
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text(
                                          'Tamam',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                Navigator.of(
                                  context,
                                ).pop({'selectedPages': selectedPages});
                              }
                            },
                            child: const Center(
                              child: Text(
                                'Tamam',
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
