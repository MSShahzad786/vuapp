import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vu_mcqs_app/services/auth_service.dart';
import 'package:vu_mcqs_app/models/user_info.dart' as models;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  models.UserInfo? _userInfo;
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  models.UserInfo? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user?.isAnonymous ?? false;

  // Constructor - listen to auth state changes
  AuthProvider() {
    _init();
  }

  void _init() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;

      if (user != null) {
        try {
          // Load user info from Firestore with timeout
          _userInfo = await _authService.getUserInfo(user.uid).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              return null;
            },
          );
        } catch (e) {
          _userInfo = null;
        }
      } else {
        _userInfo = null;
      }

      // Always notify listeners when auth state changes
      // This ensures UI updates properly on both sign-in and sign-out
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInWithGoogle();

      // Don't manually set user here - let the auth state listener handle it
      // This prevents race conditions and ensures consistent state management

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      // Clear local state immediately
      _user = null;
      _userInfo = null;
      _isLoading = false;

      // Notify listeners to update UI immediately
      notifyListeners();

      // Perform actual sign out
      await _authService.signOut();
    } catch (e) {
      // Even if sign out fails, keep the local state cleared
      // The auth state listener will handle any reconciliation
      rethrow;
    }
  }

}
