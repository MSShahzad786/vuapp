import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart' as auth_provider;
import 'package:vu_mcqs_app/providers/theme_provider.dart';
import 'package:vu_mcqs_app/models/selected_subject.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/services/sync_service.dart';
import 'package:vu_mcqs_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vu_mcqs_app/screen/main_screen.dart';
import 'package:vu_mcqs_app/screen/subject_detail_screen.dart';
import 'package:vu_mcqs_app/screen/subject_list_screen.dart';
import 'package:vu_mcqs_app/screen/database_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  List<SelectedSubject> _activeSubjects = [];
  List<SelectedSubject> _inactiveSubjects = [];
  bool _isLoadingSubjects = true;
  Set<String> _togglingSubjects = {}; // Track which subjects are being toggled

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final activeMaps = await _databaseService.getSelectedSubjects();
      final inactiveMaps = await _databaseService.getInactiveSubjects();
      setState(() {
        _activeSubjects = activeMaps.map((map) => SelectedSubject(
          subCode: map['subCode'],
          subName: map['subName'],
          subIcon: map['subIcon'],
          org: map['org'],
          credits: map['credits'],
          mcqsCount: 0,
          subjRef: '/local/${map['subCode']}',
        )).toList();
        _inactiveSubjects = inactiveMaps.map((map) => SelectedSubject(
          subCode: map['subCode'],
          subName: map['subName'],
          subIcon: map['subIcon'],
          org: map['org'],
          credits: map['credits'],
          mcqsCount: 0,
          subjRef: '/local/${map['subCode']}',
        )).toList();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSubjects = false;
      });

    }
  }

  Future<void> _removeSubject(SelectedSubject subject) async {
    if (!_togglingSubjects.contains(subject.subCode)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Subject'),
          content: Text('Are you sure you want to remove ${subject.subName} from your subjects?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ?? false;

      if (confirmed) {
        setState(() {
          _togglingSubjects.add(subject.subCode);
        });

        try {
          debugPrint('🔄 Starting removal of subject: ${subject.subCode}');

          // Try to remove from Firestore first
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final authService = AuthService();
              await authService.removeSubjectFromUserSelectedSubjects(user.uid, subject.subCode);
              debugPrint('✅ Removed from Firestore: ${subject.subCode}');
            } catch (firestoreError) {
              debugPrint('❌ Failed to remove from Firestore: ${firestoreError.toString()}');
              // Add to pending deletions for later sync
              await _databaseService.addPendingSubjectDeletion(subject.subCode);
            }
          }

          // Sync any unsynced reactions to Firestore before removing local data
          await _syncService.syncLocalReactionsToFirestore();

          // Always remove from local storage immediately
          final localOperations = [
            _databaseService.removeSelectedSubject(subject.subCode),
            _databaseService.removeSelectedChapters(subject.subCode),
            _databaseService.dropMcqTable(subject.subCode),
            _databaseService.dropShortTable(subject.subCode),
          ];
          await Future.wait(localOperations);

          debugPrint('✅ Subject removed from local storage: ${subject.subCode}');

          // Reload subjects immediately to reflect local changes
          await _loadSubjects();

        } catch (e) {
          debugPrint('❌ Error during subject removal: ${e.toString()}');
          // Even if there's an error, try to reload subjects to ensure UI is consistent
          try {
            await _loadSubjects();
          } catch (reloadError) {
            debugPrint('❌ Error reloading subjects: ${reloadError.toString()}');
          }
        } finally {
          // Always clear loading state immediately
          if (mounted) {
            setState(() {
              _togglingSubjects.remove(subject.subCode);
            });
          }
          debugPrint('✅ Loading state cleared for: ${subject.subCode}');
        }
      }
    }
  }



  void _toggleDarkTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<auth_provider.AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          final user = authProvider.user;
          final userInfo = authProvider.userInfo;

          if (user == null) {
            return const Center(
              child: Text('No user logged in'),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Name
                Center(
                  child: Text(
                    user.isAnonymous ? 'Guest Member' : (user.displayName ?? 'User'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Center(
                  child: Text(
                    user.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Email Verification Status
                if (userInfo != null && !userInfo.isEmailVerified)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Email not verified',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Subjects Section
                Expanded(
                  child: _isLoadingSubjects
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subjects List
                              ..._activeSubjects.map((subject) => _buildSubjectItem(subject, true)),
                              ..._inactiveSubjects.map((subject) => _buildSubjectItem(subject, false)),

                              // No subjects message
                              if (_activeSubjects.isEmpty && _inactiveSubjects.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No subjects found',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add Subjects Button
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SubjectListScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Add Subjects',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Go to Study Button
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(initialIndex: 0),
                            ),
                          );
                        },
                        child: Text(
                          'Go to Study',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dark Theme Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            themeProvider.themeMode == ThemeMode.dark
                                ? 'Dark Theme'
                                : 'Light Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) => _toggleDarkTheme(),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logout Text
                Center(
                  child: TextButton(
                    onPressed: () async {
                      try {
                        await authProvider.signOut();
                        if (context.mounted) {
                          // Navigate to root and remove all previous routes
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      } catch (e) {

                      }
                    },
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Database Button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DatabaseScreen()),
                      );
                    },
                    icon: const Icon(Icons.storage, size: 18),
                    label: const Text('Database'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectItem(SelectedSubject subject, bool isActive) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(subject: subject),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Subject Icon
              Icon(
                Icons.menu_book,
                size: 24,
                color: _getRandomColor(subject.subCode),
              ),
              const SizedBox(width: 12),

              // Subject Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Code (Bold)
                    Text(
                      subject.subCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subject Name (Subtitle)
                    Text(
                      subject.subName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Remove Button
              _togglingSubjects.contains(subject.subCode)
                  ? const SizedBox(
                      width: 60,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: () => _removeSubject(subject),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('delete'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRandomColor(String subCode) {
    final int hash = subCode.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];
    return colors[hash.abs() % colors.length];
  }
}
