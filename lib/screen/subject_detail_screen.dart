// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/models/selected_subject.dart';
import 'package:vu_mcqs_app/models/chapter.dart';
import 'package:vu_mcqs_app/models/mcq.dart';
import 'package:vu_mcqs_app/services/chapter_service.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/services/connectivity_service.dart';
import 'package:vu_mcqs_app/widgets/mcq_card.dart';
import 'package:vu_mcqs_app/widgets/short_question_card.dart';
import 'package:vu_mcqs_app/providers/theme_provider.dart';

class SubjectDetailScreen extends StatefulWidget {
  final SelectedSubject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Chapter> _chapters = [];
  String _chapterType = 'Chapter';
  bool _isLoadingChapters = true;
  Chapter? _selectedChapter;
  List<MCQ> _mcqs = [];
  List<MCQ> _shorts = [];
  bool _isLoadingData = false;
  bool _isChapterLoading = false;
  double _fontSize = 16.0;
  final ChapterService _chapterService = ChapterService();
  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  late ScrollController _scrollController;
  int _currentMcqIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadChapterData();
  }

  void _onTabChanged() {

    setState(() {});
  }

  @override
  void dispose() {

    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_mcqs.isNotEmpty && _scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        final proportion = _scrollController.offset / maxExtent;
        final index = (proportion * (_mcqs.length - 1)).round();
        if (index >= 0 && index < _mcqs.length && index != _currentMcqIndex) {
          setState(() {
            _currentMcqIndex = index;
          });
        }
      }
    }
  }

  void _showJumpDialog() {
    final controller = TextEditingController(text: '${_currentMcqIndex + 1}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to MCQ'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter MCQ number (1-${_mcqs.length})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final num = int.tryParse(controller.text);
              if (num != null && num >= 1 && num <= _mcqs.length) {
                final index = num - 1;
                final maxExtent = _scrollController.position.maxScrollExtent;
                final offset = (index.toDouble() / (_mcqs.length - 1)) * maxExtent;
                _scrollController.jumpTo(offset.clamp(0.0, maxExtent));
                setState(() {
                  _currentMcqIndex = index;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }



  Future<void> _loadChapterData() async {

    setState(() => _isLoadingChapters = true);

    try {
      // First, try to load from local storage
      final localChapters = await _databaseService.getSelectedChapters(widget.subject.subCode);

      if (localChapters.isNotEmpty) {


        // Convert local data to Chapter objects
        _chapters = localChapters.map((chapterData) {
          return Chapter(
            id: chapterData['id'] as String,
            name: chapterData['chapName'] as String,
            orderby: chapterData['orderby'] as int,
            isMcq: true, // Default to true for chapters that can contain MCQs
            mcqCount: chapterData['mcqCount'] as int,
            shortCount: chapterData['shortCount'] as int,
          );
        }).toList();

        _chapterType = 'Chapter'; // Default type
        setState(() => _isLoadingChapters = false);



        // Load data for first chapter if available
        if (_chapters.isNotEmpty) {
          _selectedChapter = _chapters.first;

          await _loadDataForChapter(_selectedChapter!);
        }
        return;
      }

      // No local data, fetch from Firestore if online
      final isOnline = await _connectivityService.isOnline();
      if (!isOnline) {

        setState(() => _isLoadingChapters = false);
        return;
      }


      final data = await _chapterService.fetchChapterData(widget.subject.subCode);
      final firestoreChapters = (data['chapters'] as List).cast<Chapter>();

      setState(() {
        _chapters = firestoreChapters;
        _chapterType = data['type'] as String;
        _isLoadingChapters = false;
      });



      // Store chapters locally for future use
      for (final chapter in firestoreChapters) {
        await _databaseService.insertSelectedChapter(widget.subject.subCode, {
          'name': chapter.name,
          'orderby': chapter.orderby,
          'mcqCount': chapter.mcqCount,
          'shortCount': chapter.shortCount,
        });
      }

      // Load data for first chapter if available
      if (_chapters.isNotEmpty) {
        _selectedChapter = _chapters.first;

        await _loadDataForChapter(_selectedChapter!);
      } else {

      }
    } catch (e) {

      setState(() => _isLoadingChapters = false);
    }
  }

  Chapter? _getNextChapter() {
    if (_selectedChapter == null || _chapters.isEmpty) return null;

    final currentIndex = _chapters.indexWhere((chapter) => chapter.id == _selectedChapter!.id);
    if (currentIndex == -1 || currentIndex >= _chapters.length - 1) return null;

    return _chapters[currentIndex + 1];
  }

  Chapter? _getPreviousChapter() {
    if (_selectedChapter == null || _chapters.isEmpty) return null;

    final currentIndex = _chapters.indexWhere((chapter) => chapter.id == _selectedChapter!.id);
    if (currentIndex == -1 || currentIndex <= 0) return null;

    return _chapters[currentIndex - 1];
  }

  Future<void> _loadNextChapter() async {
    final nextChapter = _getNextChapter();
    if (nextChapter == null) return;


    setState(() {
      _selectedChapter = nextChapter;
      _isChapterLoading = true;
    });
    await _loadDataForChapter(nextChapter);
  }

  Future<void> _loadPreviousChapter() async {
    final previousChapter = _getPreviousChapter();
    if (previousChapter == null) return;


    setState(() {
      _selectedChapter = previousChapter;
      _isChapterLoading = true;
    });
    await _loadDataForChapter(previousChapter);
  }

  void _toggleDarkTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();

  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(12.0, 24.0);
    });

  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(12.0, 24.0);
    });

  }

  Future<void> _loadDataForChapter(Chapter chapter) async {
    setState(() => _isLoadingData = true);

    try {
      // First, try to load from local storage
      debugPrint('Loading data for chapter ${chapter.orderby} of subject ${widget.subject.subCode}');

      final localMcqs = await _databaseService.getMcqsForChapter(widget.subject.subCode, chapter.orderby);
      final localShorts = await _databaseService.getShortsForChapter(widget.subject.subCode, chapter.orderby);

      debugPrint('Found ${localMcqs.length} MCQs and ${localShorts.length} shorts locally');


      if (localMcqs.isNotEmpty || localShorts.isNotEmpty) {
        // Data exists locally, use it instantly

        setState(() {
          _mcqs = localMcqs;
          _shorts = localShorts;
          _isLoadingData = false;
          _isChapterLoading = false; // Clear chapter loading for instant display
          _currentMcqIndex = 0;
        });
        // Reset scroll position
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }

        return; // Exit immediately without any network calls
      }



      // No local data, check if we're online
      final isOnline = await _connectivityService.isOnline();

      if (!isOnline) {
        // Offline and no local data - show error immediately
        setState(() {
          _mcqs = [];
          _shorts = [];
          _isLoadingData = false;
          _isChapterLoading = false;
        });
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MCQs not available offline. Please connect to the internet to load content.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Online and no local data - keep loading state active while fetching
      // _isLoadingData and _isChapterLoading remain true here



      // Online and no local data, fetch from Firestore

      final mcqs = await _chapterService.fetchMcqsForChapter(widget.subject.subCode, chapter.orderby);
      final shorts = await _chapterService.fetchShortsForChapter(widget.subject.subCode, chapter.orderby);



      // Store fetched data locally with incremental loading for MCQs
      if (mcqs.isNotEmpty) {
        await _showMcqStorageProgress(context, mcqs, chapter);
        // Note: _mcqs are now set incrementally inside _loadMcqsIncrementally
      } else {
        // No MCQs to load
        setState(() {
          _mcqs = [];
          _isLoadingData = false;
          _isChapterLoading = false;
          _currentMcqIndex = 0;
        });
      }

      // Store shorts locally using batch insertion
      if (shorts.isNotEmpty) {
        try {
          await _databaseService.batchInsertShorts(widget.subject.subCode, chapter.orderby, shorts);
        } catch (e) {
          // If batch insert fails, fall back to individual inserts
          for (final short in shorts) {
            try {
              await _databaseService.insertShort(widget.subject.subCode, chapter.orderby, short);
            } catch (insertError) {
              // Handle individual insert error silently
            }
          }
        }
      }

      // Set shorts and finalize loading state
      setState(() {
        _shorts = shorts;
        _isLoadingData = false;
        _isChapterLoading = false;
        _currentMcqIndex = 0;
      });

      // Reset scroll position
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }



    } catch (e) {


      setState(() {
        _isLoadingData = false;
        _isChapterLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading MCQs: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _showMcqStorageProgress(BuildContext context, List<MCQ> mcqs, Chapter chapter) async {
    final progressNotifier = ValueNotifier<int>(0);
    final loadedMcqsNotifier = ValueNotifier<List<MCQ>>([]);
    final totalCount = mcqs.length;

    // Show progress dialog with incremental loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (context, storedCount, child) {
            return AlertDialog(
              title: const Text('Storing MCQs for offline use'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: totalCount > 0 ? storedCount / totalCount : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$storedCount/$totalCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (storedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'MCQs are loading incrementally...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    // Start incremental loading in the background
    _loadMcqsIncrementally(mcqs, chapter, progressNotifier, loadedMcqsNotifier);

    // Close the dialog after a short delay to show progress
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // Clean up
    progressNotifier.dispose();
    loadedMcqsNotifier.dispose();
  }

  Future<void> _loadMcqsIncrementally(
    List<MCQ> mcqs,
    Chapter chapter,
    ValueNotifier<int> progressNotifier,
    ValueNotifier<List<MCQ>> loadedMcqsNotifier,
  ) async {
    final batchSize = 10; // Process in batches for better performance
    final loadedMcqs = <MCQ>[];

    try {
      // Try batch insertion first for all MCQs
      await _databaseService.batchInsertMcqs(widget.subject.subCode, chapter.orderby, mcqs);
      progressNotifier.value = mcqs.length;

      // Load all MCQs at once since batch insert succeeded
      loadedMcqs.addAll(mcqs);
      loadedMcqsNotifier.value = List.from(loadedMcqs);

      // Update UI incrementally
      if (mounted) {
        setState(() {
          _mcqs = List.from(loadedMcqs);
        });
      }

    } catch (e) {
      // If batch insert fails, fall back to incremental individual inserts
      for (int i = 0; i < mcqs.length; i += batchSize) {
        final endIndex = (i + batchSize < mcqs.length) ? i + batchSize : mcqs.length;
        final batch = mcqs.sublist(i, endIndex);

        // Process batch
        for (final mcq in batch) {
          try {
            await _databaseService.insertMcq(widget.subject.subCode, chapter.orderby, mcq);
            loadedMcqs.add(mcq);
            progressNotifier.value = loadedMcqs.length;

            // Update UI every few items for incremental display
            if (loadedMcqs.length % 5 == 0 || loadedMcqs.length == mcqs.length) {
              loadedMcqsNotifier.value = List.from(loadedMcqs);
              if (mounted) {
                setState(() {
                  _mcqs = List.from(loadedMcqs);
                });
              }
            }
          } catch (insertError) {
            // Handle individual insert error silently
          }
        }

        // Small delay to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // Final UI update
    if (mounted) {
      setState(() {
        _mcqs = List.from(loadedMcqs);
        _isLoadingData = false;
        _isChapterLoading = false;
        _currentMcqIndex = 0;
      });

      // Reset scroll position
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _showChapterBottomSheet() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chapter List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Chapter list
              Expanded(
                child: _isLoadingChapters
                    ? const Center(child: CircularProgressIndicator())
                    : _chapters.isEmpty
                        ? const Center(
                            child: Text(
                              'No chapters available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = _chapters[index];
                              final isSelected = _selectedChapter?.id == chapter.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    '$_chapterType ${chapter.orderby}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).textTheme.bodyLarge?.color,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    chapter.name,
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${chapter.mcqCount + chapter.shortCount}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    debugPrint('Tapped chapter: ${chapter.name} (orderby: ${chapter.orderby}) for subject: ${widget.subject.subCode}');

                                    // Close the bottom sheet first
                                    Navigator.of(context).pop();

                                    // Check if we have local data before showing loading
                                    final hasLocalMcqs = await _databaseService.hasMcqsForChapter(widget.subject.subCode, chapter.orderby);
                                    final hasLocalShorts = await _databaseService.hasShortsForChapter(widget.subject.subCode, chapter.orderby);

                                    setState(() {
                                      _selectedChapter = chapter;
                                      // Only show loading if we don't have local data
                                      _isChapterLoading = !(hasLocalMcqs || hasLocalShorts);
                                    });

                                    await _loadDataForChapter(chapter);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedChapter != null ? '${widget.subject.subCode.toUpperCase()} - Chapter ${_selectedChapter!.orderby}' : widget.subject.subCode.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      if (_tabController.index == 0 && _mcqs.isNotEmpty)
                        GestureDetector(
                          onTap: _showJumpDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_currentMcqIndex + 1}/${_mcqs.length}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  centerTitle: false,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  snap: false,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(36),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide.none,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('MCQs ${_mcqs.isNotEmpty ? _mcqs.length : ''}'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Shorts ${_shorts.isNotEmpty ? _shorts.length : ''}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: _isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                   controller: _tabController,
                   children: [
                     // MCQs Tab
                     (_mcqs.isEmpty
                         ? const Center(child: Text('No MCQs available for this chapter'))
                         : Builder(
                             builder: (context) {
                               final hasPrevious = _getPreviousChapter() != null;
                               final hasNext = _getNextChapter() != null;
                               return ListView.builder(
                                 itemCount: _mcqs.length + (hasPrevious ? 1 : 0) + (hasNext ? 1 : 0),
                                 physics: const BouncingScrollPhysics(),
                                 itemBuilder: (context, index) {
                                   // Check if this is the first item and we have a previous chapter
                                   if (hasPrevious && index == 0) {
                                     final previousChapter = _getPreviousChapter()!;
                                     return Container(
                                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       child: TextButton(
                                         onPressed: _loadPreviousChapter,
                                         style: TextButton.styleFrom(
                                           backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                           foregroundColor: Theme.of(context).colorScheme.primary,
                                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                           shape: RoundedRectangleBorder(
                                             borderRadius: BorderRadius.circular(8),
                                           ),
                                         ),
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             const Icon(Icons.arrow_back, size: 16),
                                             const SizedBox(width: 6),
                                             Text(
                                               'Previous Chapter ${previousChapter.orderby}',
                                               style: const TextStyle(
                                                 fontSize: 14,
                                                 fontWeight: FontWeight.w500,
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     );
                                   }
                                   // Check if this is the last item and we have a next chapter
                                   else if (hasNext && index == _mcqs.length + (hasPrevious ? 1 : 0)) {
                                     final nextChapter = _getNextChapter()!;
                                     return Container(
                                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       child: TextButton(
                                         onPressed: _loadNextChapter,
                                         style: TextButton.styleFrom(
                                           backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                           foregroundColor: Theme.of(context).colorScheme.primary,
                                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                           shape: RoundedRectangleBorder(
                                             borderRadius: BorderRadius.circular(8),
                                           ),
                                         ),
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Text(
                                               'Next Chapter ${nextChapter.orderby}',
                                               style: const TextStyle(
                                                 fontSize: 14,
                                                 fontWeight: FontWeight.w500,
                                               ),
                                             ),
                                             const SizedBox(width: 6),
                                             const Icon(Icons.arrow_forward, size: 16),
                                           ],
                                         ),
                                       ),
                                     );
                                   } else {
                                     final mcqIndex = hasPrevious ? index - 1 : index;
                                     final mcq = _mcqs[mcqIndex];
                                     return McqCard(
                                       mcq: mcq,
                                       index: mcqIndex,
                                       subjectCode: widget.subject.subCode,
                                       chapterOrderby: _selectedChapter?.orderby ?? 1,
                                       fontSize: _fontSize,
                                     );
                                   }
                                 },
                               );
                             },
                           )),
                     // Shorts Tab
                     (_shorts.isEmpty
                         ? const Center(child: Text('No Short Questions available for this chapter'))
                         : ListView.builder(
                           itemCount: _shorts.length,
                           physics: const BouncingScrollPhysics(),
                           itemBuilder: (context, index) {
                             final question = _shorts[index];
                             return ShortQuestionCard(
                               question: question,
                               index: index,
                               subjectCode: widget.subject.subCode,
                               chapterOrderby: _selectedChapter?.orderby ?? 1,
                             );
                           },
                         )),
                   ],
                 ),
          ),
          // Loading overlay when chapter is loading
          if (_isChapterLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Chapter MCQs...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showChapterBottomSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.list),
      ),
    );
  }
}
