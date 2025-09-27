import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vu_mcqs_app/models/subject.dart';
import 'package:vu_mcqs_app/models/selected_subject.dart';
import 'package:vu_mcqs_app/services/subject_service.dart';
import 'package:vu_mcqs_app/services/chapter_service.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/services/connectivity_service.dart';
import 'package:vu_mcqs_app/services/auth_service.dart';
import 'package:vu_mcqs_app/services/user_subject_firestore_service.dart';
import 'package:vu_mcqs_app/widgets/subject_list_item.dart';
import 'package:vu_mcqs_app/widgets/search_field.dart';
import 'package:vu_mcqs_app/screen/main_screen.dart';
import 'package:vu_mcqs_app/screen/user_profile_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final SubjectService _subjectService = SubjectService();
  final ChapterService _chapterService = ChapterService();
  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final TextEditingController _searchController = TextEditingController();
  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  bool _isLoading = true;
  bool _isOffline = false;
  final Set<String> _addingSubjects = {};
  Set<String> _addedSubjects = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchSubjects);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      setState(() => _isOffline = true);
      _subjects = [];
      _filteredSubjects = [];
    } else {
      setState(() => _isOffline = false);
      try {
        _subjects = await _subjectService.fetchMySubjects();
        _filteredSubjects = _subjects;
      } catch (e) {
        _subjects = [];
        _filteredSubjects = [];

        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to load subjects. Please check your internet connection and try again.'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadSubjects,
              ),
            ),
          );
        }
      }
    }


    await _loadUserSubjects();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserSubjects() async {
    try {
      final selectedSubjects = await _databaseService.getSelectedSubjects();
      final selectedSubjectCodes = selectedSubjects
          .map((s) => s['subCode'] as String)
          .toSet();
      setState(() {
        _addedSubjects = selectedSubjectCodes;
      });
    } catch (e) {
      setState(() {
        _addedSubjects = {};
      });
    }
  }

  void _searchSubjects() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredSubjects = _subjects);
    } else {
      setState(() => _filteredSubjects = _subjects
          .where((subject) => subject.subCode.toLowerCase().startsWith(query))
          .toList());
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showNoInternetDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please turn on your data or Wi-Fi to download subject data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn on Data'),
          ),
        ],
      ),
    ) ?? false;
  }


  Future<void> _addSubjectToUserCollection(Subject subject) async {
    final confirmed = await _showConfirmationDialog(
      'Add Subject',
      'Are you sure you want to add ${subject.subCode.toUpperCase()}?',
    );
    if (!confirmed) return;

    setState(() => _addingSubjects.add(subject.subCode));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check connectivity first
      final isOnline = await _connectivityService.isOnline();
      if (!isOnline) {
        // Show offline message and don't add subject
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Please check your connection and try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _addingSubjects.remove(subject.subCode));
        return;
      }

      // Fetch chapter data first to get mcqsCount
      int mcqsCount = 0;
      try {
        final chapterData = await _chapterService.fetchChapterData(subject.subCode);
        final chapters = chapterData['chapters'] as List<dynamic>? ?? [];
        mcqsCount = chapters.fold(0, (sum, chapter) => sum + (chapter.mcqCount as int? ?? 0));
      } catch (e) {
        // Continue with subject selection even if chapter data fails
        mcqsCount = 0;
      }

      // Online: Add to Firestore first using UserSubjectFirestoreService
      final firestoreService = UserSubjectFirestoreService();
      SelectedSubject? selectedSubject;
      try {
        selectedSubject = await firestoreService.addSubjectToSelectedSubjectsDoc(user.uid, subject, mcqsCount);
      } catch (e) {
        // Check if it's a network/connectivity error
        if (e.toString().contains('UNAVAILABLE') ||
            e.toString().contains('UnknownHostException') ||
            e.toString().contains('firestore.googleapis.com')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to connect to server. Please check your internet connection and try again.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _addingSubjects.remove(subject.subCode));
          return;
        } else {
          // Re-throw other errors
          rethrow;
        }
      }

      if (selectedSubject == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add subject. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _addingSubjects.remove(subject.subCode));
        return;
      }

      // Store subject in local DB
      await _databaseService.insertSelectedSubject(subject);
      setState(() => _addedSubjects.add(subject.subCode));

      // Store chapter data (already fetched above)
      try {
        final chapterData = await _chapterService.fetchChapterData(subject.subCode);
        final chapters = chapterData['chapters'] as List<dynamic>? ?? [];

        // Batch insert chapters for better performance
        final batchInserts = chapters.map((chapter) async {
          final chapterMap = {
            'name': chapter.name,
            'orderby': chapter.orderby,
            'mcqCount': chapter.mcqCount,
            'shortCount': chapter.shortCount,
          };
          await _databaseService.insertSelectedChapter(subject.subCode, chapterMap);
        }).toList();

        await Future.wait(batchInserts);
      } catch (e) {
        // Continue with subject selection even if chapter data fails
      }

      // Reload subjects to ensure UI is in sync
      await _loadUserSubjects();
    } catch (e) {
      debugPrint('Error adding subject: ${e.toString()}');

      // Remove from Firestore if local storage failed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final authService = AuthService();
          await authService.removeSubjectFromUserSelectedSubjects(user.uid, subject.subCode);
        } catch (cleanupError) {
          debugPrint('Error cleaning up Firestore: ${cleanupError.toString()}');
        }
      }

      // Remove from local storage
      try {
        await _databaseService.removeSelectedSubject(subject.subCode);
        await _databaseService.removeSelectedChapters(subject.subCode);
      } catch (cleanupError) {
        debugPrint('Error cleaning up local storage: ${cleanupError.toString()}');
      }

      setState(() => _addedSubjects.remove(subject.subCode));

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add subject. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _addingSubjects.remove(subject.subCode));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addedSubjects.isEmpty
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 0),
                  ),
                );
              },
        backgroundColor: _addedSubjects.isEmpty ? Colors.grey : Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow, size: 20),
        label: const Text(
          'Start Study',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: const Text(
          'All Subjects',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.green,
        elevation: 1,
      ),
      body: Column(
        children: [
          SearchField(
            controller: _searchController,
            hintText: 'Search subjects...',
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSubjects.isEmpty
                    ? const Center(child: Text('No subjects found'))
                    : ListView.builder(
                        itemCount: _filteredSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _filteredSubjects[index];
                          final isAdded = _addedSubjects.contains(subject.subCode);
                          return SubjectListItem(
                            subject: subject,
                            isAdded: isAdded,
                            isAdding: _addingSubjects.contains(subject.subCode),
                            isDownloading: false,
                            onAdd: () => _addSubjectToUserCollection(subject),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
