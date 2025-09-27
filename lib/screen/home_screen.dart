import 'package:flutter/material.dart';
import 'package:vu_mcqs_app/models/selected_subject.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/widgets/subject_card.dart';
import 'package:vu_mcqs_app/widgets/section_header.dart';
import 'package:vu_mcqs_app/widgets/empty_state.dart';
import 'package:vu_mcqs_app/screen/subject_list_screen.dart';
import 'package:vu_mcqs_app/screen/subject_detail_screen.dart';
import 'package:vu_mcqs_app/screen/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SelectedSubject> _activeSubjects = [];
  List<SelectedSubject> _inactiveSubjects = [];
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserSubjects();
  }

  Future<void> _loadUserSubjects() async {
    setState(() => _isLoading = true);

    try {
      // Load active subjects from local SQFlite database
      final activeSubjectsData = await _databaseService.getSelectedSubjects();
      final inactiveSubjectsData = await _databaseService.getInactiveSubjects();

      // Convert active subjects data to SelectedSubject objects
      _activeSubjects = activeSubjectsData.map((subjectData) {
        return SelectedSubject(
          subCode: subjectData['subCode'] as String,
          subName: subjectData['subName'] as String,
          subIcon: subjectData['subIcon'] as String,
          org: subjectData['org'] as String,
          credits: subjectData['credits'] as int,
          mcqsCount: 0, // We'll need to fetch this separately or store it locally
          subjRef: subjectData['subCode'] as String,
        );
      }).toList();

      // Convert inactive subjects data to SelectedSubject objects
      _inactiveSubjects = inactiveSubjectsData.map((subjectData) {
        return SelectedSubject(
          subCode: subjectData['subCode'] as String,
          subName: subjectData['subName'] as String,
          subIcon: subjectData['subIcon'] as String,
          org: subjectData['org'] as String,
          credits: subjectData['credits'] as int,
          mcqsCount: 0, // We'll need to fetch this separately or store it locally
          subjRef: subjectData['subCode'] as String,
        );
      }).toList();


    } catch (e) {

      _activeSubjects = [];
      _inactiveSubjects = [];
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _toggleSubjectStatus(SelectedSubject subject, bool currentlyActive) async {
    try {
      final newStatus = currentlyActive ? 0 : 1;
      await _databaseService.updateSubjectStatus(subject.subCode, newStatus);
      await _loadUserSubjects();

    } catch (e) {

    }
  }


  Widget _buildSubjectCard(SelectedSubject subject, bool isActive) {
    return SubjectCard(
      subject: subject,
      isActive: isActive,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SubjectDetailScreen(subject: subject),
          ),
        );
      },
      onStatusToggle: () => _toggleSubjectStatus(subject, isActive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Subjects',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeSubjects.isEmpty && _inactiveSubjects.isEmpty
          ? EmptyState(
              title: 'No Subjects Selected',
              message: 'Choose subjects from our collection to begin your learning journey',
              buttonText: 'Browse Subjects',
              onButtonPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubjectListScreen(),
                  ),
                );
              },
              icon: Icons.library_books,
            )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        if (_activeSubjects.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Active Subjects',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          ..._activeSubjects.map((subject) {
                            return _buildSubjectCard(subject, true);
                          }),
                        ],
                        if (_inactiveSubjects.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Inactive Subjects',
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          ..._inactiveSubjects.map((subject) {
                            return _buildSubjectCard(subject, false);
                          }),
                        ],
                      ]
                    ),
                  ),
                ),
    );
  }
}
