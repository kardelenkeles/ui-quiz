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

enum Difficulty { easy, mid, zor }

class _PagePickerScreenState extends State<PagePickerScreen> {
  late List<int> selectedPages;
  late TextEditingController startController;
  late TextEditingController endController;
  // Brand accent: use lime for page picker theme
  final Color brandBlue = Colors.lime;
  // Slider state
  late SfRangeValues _rangeValues;
  // Question count (1–20) and difficulty level
  late int _questionCount;
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    selectedPages = List<int>.from(widget.initialSelectedPages);
    _questionCount = 10; // default 10 questions
    _difficulty = Difficulty.mid; // default difficulty
    // Ensure pageCount is at least 1 to avoid invalid slider min/max values
    final safePageCount = widget.pageCount < 1 ? 1 : widget.pageCount;

    startController = TextEditingController(
      text: (selectedPages.isNotEmpty ? selectedPages.first : 1).toString(),
    );
    endController = TextEditingController(
      text: (selectedPages.isNotEmpty ? selectedPages.last : safePageCount)
          .toString(),
    );

    // initialize range slider values (ensure start <= end)
    final startInit = selectedPages.isNotEmpty ? selectedPages.first : 1;
    final endInit = selectedPages.isNotEmpty
        ? selectedPages.last
        : safePageCount;
    final sInit = startInit <= endInit ? startInit : 1;
    final eInit = endInit >= sInit ? endInit : safePageCount;
    _rangeValues = SfRangeValues(sInit.toDouble(), eInit.toDouble());
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
    final list = List<int>.generate(end - start + 1, (i) => start + i).toList();
    setState(() {
      selectedPages = list;
      // keep displayed slider values in sync when user edits text fields
      _rangeValues = SfRangeValues(start.toDouble(), end.toDouble());
    });
  }

  // Helpers for instantly-displayed values (driven by the slider)
  int get _displayStart => _rangeValues.start.round();
  int get _displayEnd => _rangeValues.end.round();
  int get _displayCount {
    final raw = _displayEnd - _displayStart + 1;
    if (raw <= 0) return 0;
    return raw > widget.maxSelectable ? widget.maxSelectable : raw;
  }

  @override
  Widget build(BuildContext context) {
    // enforce a hard limit of 8 pages for confirmation
    const int maxAllowed = 8;
    final int rawSelectionLength = (_displayEnd - _displayStart) + 1;
    final bool selectionTooLarge = rawSelectionLength > maxAllowed;
    // Require explicit selectedPages (from user actions: slider/apply/select all)
    final bool canConfirm = selectedPages.isNotEmpty && !selectionTooLarge;

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
              'Cancel',
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
            color: brandBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            minSize: 0,
            onPressed: () {
              setState(() {
                // select all pages (respecting widget.maxSelectable)
                final all = List<int>.generate(widget.pageCount, (i) => i + 1);
                selectedPages = all.take(widget.maxSelectable).toList();

                // update controllers and slider values to reflect the full selection
                final start = selectedPages.isNotEmpty
                    ? selectedPages.first
                    : 1;
                final end = selectedPages.isNotEmpty
                    ? selectedPages.last
                    : widget.pageCount;
                startController.text = start.toString();
                endController.text = end.toString();
                _rangeValues = SfRangeValues(start.toDouble(), end.toDouble());
              });
            },
            child: const Text(
              'Select All',
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
          child: Column(
            children: [
              // Başlık kutusu - diğer sayfalarla tutarlı
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Select Page Range',
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
                      'You can select up to ${widget.maxSelectable} pages',
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
                                'Start Page',
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
                                'End Page',
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
                            selectedPages.isEmpty
                                ? 'Selected: No pages'
                                : 'Selected: ${_displayStart}-${_displayEnd} (${_displayCount} pages)',
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
                          if (selectionTooLarge) ...[
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Your selection is too large. You can select up to ${widget.maxSelectable} pages.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  color: CupertinoColors.systemRed,
                                  fontSize: 13,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ],

                          if (widget.pageCount > 1) ...[
                            SfRangeSlider(
                              // brand colors
                              activeColor: brandBlue,
                              inactiveColor: brandBlue.withOpacity(0.18),

                              min: 1.0,
                              max: widget.pageCount.toDouble(),
                              values: _rangeValues,

                              stepSize: 1.0,
                              interval: (widget.pageCount / 4)
                                  .clamp(1, widget.pageCount)
                                  .toDouble(),
                              showTicks: false,
                              showLabels: true,
                              labelFormatterCallback:
                                  (dynamic actualValue, String formattedText) {
                                    final v = actualValue is double
                                        ? actualValue.round()
                                        : actualValue;
                                    return v.toString();
                                  },
                              enableTooltip: true,
                              tooltipTextFormatterCallback:
                                  (dynamic actualValue, String formattedText) {
                                    final v = actualValue is double
                                        ? actualValue.round()
                                        : actualValue;
                                    return v.toString();
                                  },
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
                          ] else ...[
                            // If only one page exists, show a static indicator instead of a slider
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                'Single page available — page 1 selected',
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ],
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
                              'Total Pages',
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
                              'Selected Pages',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 12,
                                fontFamily: 'Nunito',
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_displayCount',
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

              const SizedBox(height: 16),

              // Question count and difficulty selector
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      // Question count section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Question Count',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                              color: CupertinoColors.black,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  icon: const Icon(CupertinoIcons.minus),
                                  onPressed: _questionCount > 1
                                      ? () => setState(() {
                                          _questionCount--;
                                        })
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Text(
                                    '$_questionCount',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  icon: const Icon(CupertinoIcons.plus),
                                  onPressed: _questionCount < 20
                                      ? () => setState(() {
                                          _questionCount++;
                                        })
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Difficulty section
                      const Text(
                        'Difficulty Level',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDifficultyButton(
                              'Easy',
                              Difficulty.easy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDifficultyButton(
                              'Mid',
                              Difficulty.mid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDifficultyButton(
                              'Zor',
                              Difficulty.zor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Alt buton - Tamam (sağ alt)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 50,
                    width: 150,
                    decoration: BoxDecoration(
                      color: canConfirm
                          ? brandBlue
                          : brandBlue.withOpacity(0.35),
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
                        onTap: canConfirm
                            ? () {
                                // Ensure selectedPages reflects the current slider/text values
                                final safePageCount = widget.pageCount < 1
                                    ? 1
                                    : widget.pageCount;
                                final int start = _displayStart.clamp(
                                  1,
                                  safePageCount,
                                );
                                final int end = _displayEnd.clamp(
                                  1,
                                  safePageCount,
                                );
                                final resolvedStart = start <= end
                                    ? start
                                    : end;
                                final resolvedEnd = end >= resolvedStart
                                    ? end
                                    : resolvedStart;
                                final list = List<int>.generate(
                                  (resolvedEnd - resolvedStart) + 1,
                                  (i) => resolvedStart + i,
                                );
                                final finalPages = list
                                    .take(widget.maxSelectable)
                                    .toList();

                                Navigator.of(context).pop({
                                  'selectedPages': finalPages,
                                  'questionCount': _questionCount,
                                  'difficulty': _difficulty
                                      .toString()
                                      .split('.')
                                      .last,
                                  'autoGenerate': true,
                                });
                              }
                            : null,
                        child: Center(
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 16,
                              color: canConfirm
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
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
    );
  }

  Widget _buildDifficultyButton(String label, Difficulty difficulty) {
    final isSelected = _difficulty == difficulty;
    return GestureDetector(
      onTap: () => setState(() {
        _difficulty = difficulty;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: brandBlue, width: 2)
              : Border.all(color: CupertinoColors.systemGrey4, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            decoration: TextDecoration.none,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
            color: isSelected ? Colors.white : CupertinoColors.black,
          ),
        ),
      ),
    );
  }
}
