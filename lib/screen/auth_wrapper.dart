import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart' as auth_provider;
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/screen/login_screen.dart';
import 'package:vu_mcqs_app/screen/main_screen.dart';
import 'package:vu_mcqs_app/screen/subject_list_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedSubjects = false;
  bool _hasSubjects = false;
  String? _lastUserId;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<auth_provider.AuthProvider>(context);

    // Reset state if user changed (logged out or different user)
    if (authProvider.user?.uid != _lastUserId) {
      _lastUserId = authProvider.user?.uid;
      _hasCheckedSubjects = false;
      _hasSubjects = false;
    }

    if (authProvider.isAuthenticated && !_hasCheckedSubjects) {
      _checkUserSubjects(authProvider.user!);
    }
  }

  Future<void> _checkUserSubjects(User user) async {
    try {
      // Check local database for selected subjects
      final activeSubjects = await _databaseService.getSelectedSubjects();
      final inactiveSubjects = await _databaseService.getInactiveSubjects();

      setState(() {
        _hasSubjects = activeSubjects.isNotEmpty || inactiveSubjects.isNotEmpty;
        _hasCheckedSubjects = true;
      });
    } catch (e) {
      setState(() {
        _hasSubjects = false;
        _hasCheckedSubjects = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading || (authProvider.isAuthenticated && !_hasCheckedSubjects)) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return _hasSubjects ? const MainScreen() : const SubjectListScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
