part of 'quiz_generator.dart';

extension _QuizGeneratorViewBuilder on _QuizGeneratorViewState {
  Widget buildQuizGeneratorView(BuildContext context) {
    // If there's any input (pasted text, a selected file, or captured photos),
    // other input options should be disabled (including camera).
    final bool hasInput =
        _textHasContent || _selectedFile != null || _capturedPhotos.isNotEmpty;

    return Material(
      child: Stack(
        children: [
          CupertinoPageScaffold(
            resizeToAvoidBottomInset: true,
            child: Stack(
              children: [
                // Main column content
                Column(
                  children: [
                    // Ana içerik - Scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),

                              Image.asset(
                                'asset/icon/b.png',
                                width: 300,
                                height: 260,
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Stack(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        minHeight: 150,
                                        maxHeight: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _textHasContent
                                            ? Colors.white
                                            : CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(4, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 10,
                                            offset: Offset(-4, -4),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: _textHasContent
                                              ? Colors.lime.withValues(
                                                  alpha: 0.5,
                                                )
                                              : CupertinoColors.systemGrey4,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _textController,
                                        readOnly:
                                            _selectedFile != null ||
                                            _capturedPhotos.isNotEmpty,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Tap to paste from clipboard...',
                                          hintStyle: const TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'Nunito',
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                          fontFamily: 'Nunito',
                                        ),
                                        onTap: () async {
                                          if (_selectedFile != null ||
                                              _capturedPhotos.isNotEmpty) {
                                            return;
                                          }
                                          ClipboardData? clipboardData =
                                              await Clipboard.getData(
                                                'text/plain',
                                              );
                                          if (clipboardData != null &&
                                              clipboardData.text != null) {
                                            _refresh(() {
                                              _textController.text =
                                                  clipboardData.text!;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: AnimatedOpacity(
                                        opacity: _textHasContent ? 0.0 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.doc_on_clipboard,
                                          color: CupertinoColors.systemGrey,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    if (_textHasContent)
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            _refresh(() {
                                              _textController.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  CupertinoColors.systemGrey5,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              CupertinoIcons.clear_thick,
                                              color: CupertinoColors.systemGrey,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // "or import your files" yazısı
                              const Text(
                                'or import your files',
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Import butonu ve Kamera ikonu yan yana
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Import butonu
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: CupertinoButton(
                                        onPressed: hasInput
                                            ? null
                                            : _importFile,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 54,
                                          vertical: 28,
                                        ),
                                        color: CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              _selectedFile != null
                                                  ? 'asset/icon/folderfilled.png'
                                                  : 'asset/icon/folder.png',
                                              width: 60,
                                              height: 30,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Kamera ikonu
                                    GestureDetector(
                                      onTap: hasInput
                                          ? null
                                          : _captureFromCamera,
                                      child: Opacity(
                                        opacity: hasInput ? 0.45 : 1.0,
                                        child: Container(
                                          padding: const EdgeInsets.all(28),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey6,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            'asset/icon/camera.png',
                                            width: 50,
                                            height: 30,
                                            color: CupertinoColors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (_selectedFile != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            foregroundColor:
                                                CupertinoColors.activeBlue,
                                          ),
                                          onPressed: () async {
                                            if (_selectedFile != null) {
                                              final pickerResult =
                                                  await _openPagePickerModal();
                                              // If picker returned pages and also provided settings,
                                              // apply them and auto-generate.
                                              if (_selectedPages.isNotEmpty) {
                                                if (pickerResult != null &&
                                                    (pickerResult['questionCount'] !=
                                                            null ||
                                                        pickerResult['difficulty'] !=
                                                            null)) {
                                                  if (!mounted) return;
                                                  _refresh(() {
                                                    try {
                                                      if (pickerResult['questionCount'] !=
                                                          null) {
                                                        _selectedQuestionCount =
                                                            (pickerResult['questionCount']
                                                                    as num)
                                                                .toInt();
                                                      }
                                                    } catch (_) {}
                                                    _selectedDifficulty =
                                                        pickerResult['difficulty']
                                                            ?.toString() ??
                                                        _selectedDifficulty;
                                                  });
                                                  await _generateQuiz();
                                                  return;
                                                }

                                                // otherwise, ask for question settings then generate
                                                final settings =
                                                    await _showQuestionSettingsModal();
                                                if (settings == null) return;
                                                if (!mounted) return;
                                                _refresh(() {
                                                  try {
                                                    _selectedQuestionCount =
                                                        (settings['questionCount']
                                                                as num)
                                                            .toInt();
                                                  } catch (_) {}
                                                  _selectedDifficulty =
                                                      settings['difficulty']
                                                          ?.toString() ??
                                                      _selectedDifficulty;
                                                });
                                                await _generateQuiz();
                                              }
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _selectedFile!.path
                                                      .split('/')
                                                      .last,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _refresh(
                                          () => _selectedFile = null,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey6,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  CupertinoColors.systemGrey4,
                                            ),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.clear_circled_solid,
                                            color: CupertinoColors.systemGrey,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),

                              // Show captured photos
                              if (_capturedPhotos.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _refresh(() {
                                              _capturedPhotos.clear();
                                              _capturedPhotosText.clear();
                                            }),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color:
                                                    CupertinoColors.systemGrey6,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: CupertinoColors
                                                      .systemGrey4,
                                                ),
                                              ),
                                              child: const Icon(
                                                CupertinoIcons
                                                    .clear_circled_solid,
                                                color:
                                                    CupertinoColors.systemGrey,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Show thumbnails with add button
                                      SizedBox(
                                        height: 80,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _capturedPhotos.length + 1,
                                          itemBuilder: (context, index) {
                                            // Add button at the end
                                            if (index ==
                                                _capturedPhotos.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 8.0,
                                                ),
                                                child: GestureDetector(
                                                  onTap: _addMorePhotos,
                                                  child: Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      color: CupertinoColors
                                                          .systemGrey6,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: CupertinoColors
                                                            .systemGrey4,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      CupertinoIcons.add,
                                                      size: 32,
                                                      color: CupertinoColors
                                                          .systemGrey,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: FutureBuilder<Uint8List>(
                                                      future:
                                                          _capturedPhotos[index]
                                                              .readAsBytes(),
                                                      builder: (context, snapshot) {
                                                        if (!snapshot.hasData) {
                                                          return const SizedBox(
                                                            width: 80,
                                                            height: 80,
                                                            child:
                                                                CupertinoActivityIndicator(),
                                                          );
                                                        }
                                                        return Image.memory(
                                                          snapshot.data!,
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  // Delete button overlay
                                                  Positioned(
                                                    top: 2,
                                                    right: 2,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _refresh(() {
                                                          _capturedPhotos
                                                              .removeAt(index);
                                                          if (index <
                                                              _capturedPhotosText
                                                                  .length) {
                                                            _capturedPhotosText
                                                                .removeAt(
                                                                  index,
                                                                );
                                                          }
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color: Colors
                                                                  .black54,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: const Icon(
                                                          CupertinoIcons.clear,
                                                          color: Colors.white,
                                                          size: 16,
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
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 40),

                              // Generate butonu
                              Center(
                                child: AnimatedButton(
                                  onPressed: _generateQuiz,
                                  color: Colors.lime,
                                  enabled: true,
                                  disabledColor: Colors.grey,
                                  shadowDegree: ShadowDegree.light,
                                  borderRadius: 20,
                                  duration: 0,
                                  height: 60,
                                  width: 310,
                                  child: const Text(
                                    'Generate',
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

                              const SizedBox(height: 40), // Alttan boşluk
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Overlay spinner while processing file selection
                if (_isProcessingFile)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.lime,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isUploadingFile
                                  ? 'Uploading file...'
                                  : 'Processing...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
          // Progress overlay modal
          if (_isGeneratingQuiz)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Linear Progress Bar
                        LinearProgressBar(
                          maxSteps: _loadingTexts.length,
                          progressType: LinearProgressBar.progressTypeLinear,
                          currentStep: _currentStep,
                          progressColor: Colors.lime,
                          backgroundColor: Colors.grey[300]!,
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 12,
                        ),
                        const SizedBox(height: 16),
                        // Loading text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            (_currentStep > 0 &&
                                    _currentStep <= _loadingTexts.length)
                                ? _loadingTexts[_currentStep - 1]
                                : '',
                            key: ValueKey(_currentStep),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Cancel button
                        ElevatedButton(
                          onPressed: () {
                            _refresh(() {
                              _isGeneratingQuiz = false;
                              _currentStep = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
