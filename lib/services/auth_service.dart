import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vu_mcqs_app/models/user_info.dart' as models;
import 'package:vu_mcqs_app/models/subject.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Google sign-in timed out. Please try again.');
        },
      );
      if (googleUser == null) {
        return null; // User cancelled sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Failed to get authentication tokens from Google. Please try again.');
        },
      );
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Firebase sign-in timed out. Please check your internet connection and try again.');
        },
      );

      // Create or update user info in Firestore
      try {
        await _createOrUpdateGoogleUserInfo(userCredential.user!);
      } catch (firestoreError) {
        // Don't fail the entire sign-in if Firestore update fails
      }

      return userCredential;
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('network') || e.toString().contains('connectivity')) {
        throw Exception('Network connection error.');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('sign_in_cancelled')) {
        throw Exception('Google sign-in was cancelled or failed. Please try again.');
      } else if (e.toString().contains('developer_error') || e.toString().contains('invalid_client')) {
        throw Exception('Google sign-in configuration error. Please check your Firebase configuration.');
      } else {
        throw Exception('Google sign-in failed: ${e.toString()}');
      }
    }
  }

  // Create or update Google user info in Firestore
  Future<void> _createOrUpdateGoogleUserInfo(User user) async {
    try {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

      // Check if user document exists with timeout
      DocumentSnapshot docSnapshot = await userDoc.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore timeout: Unable to get user document');
        },
      );

      if (!docSnapshot.exists) {
        // Create new Google user info
        models.UserInfo googleUserInfo = models.UserInfo(
          userId: user.uid,
          authProvider: 'google',
          email: user.email,
          phoneNumber: user.phoneNumber,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          dateCreated: DateTime.now(),
          lastLogin: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );

        await userDoc.set(googleUserInfo.toJson()).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firestore timeout: Unable to create user document');
          },
        );

        // Initialize subjects subcollection for new user
        await _initializeUserSubjects(user.uid);
      } else {
        // Update last login time for existing user
        await userDoc.update({
          'lastLogin': DateTime.now().toIso8601String(),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firestore timeout: Unable to update user document');
          },
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<models.UserInfo?> getUserInfo(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(userId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore timeout: Unable to get user info');
        },
      );

      if (docSnapshot.exists) {
        final userInfo = models.UserInfo.fromJson(docSnapshot.data() as Map<String, dynamic>);
        return userInfo;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google Sign-In if user was signed in with Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore errors
      }

      // Sign out from Firebase Auth
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  //==============================// Add subject to user's selectedSubjects subcollection document with is_current = true
  Future<bool> addSubjectToUserSelectedSubjects(String userId, Subject subject) async {
    try {
      CollectionReference selectedSubjectsCol = _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects');

      // Query for document with is_current = true
      QuerySnapshot query = await selectedSubjectsCol
          .where('is_current', isEqualTo: true)
          .get();
  
      DocumentReference docRef;
      Map<String, dynamic> data = {};
      String docId;
      String fullPath;
  
      if (query.docs.isNotEmpty) {
        // Use existing document
        docRef = query.docs.first.reference;
        docId = query.docs.first.id;
        data = query.docs.first.data() as Map<String, dynamic>;
        fullPath = 'users/$userId/selectedSubjects/$docId';
      } else {
        // Create new document with random 3-digit number
        final random = DateTime.now().millisecondsSinceEpoch % 1000;
        docId = 'current${random.toString().padLeft(3, '0')}';
        docRef = selectedSubjectsCol.doc(docId);
        fullPath = 'users/$userId/selectedSubjects/$docId';
      }

      List<dynamic> activeSubjects = data['activeSubjects'] ?? [];
      List<dynamic> inactiveSubjects = data['inactiveSubjects'] ?? [];

      // Create subject data map (excluding underProcess)
      final subjectData = {
        'id': subject.id,
        'subCode': subject.subCode,
        'subName': subject.subName,
        'subIcon': subject.subIcon,
        'org': subject.org,
        'credits': subject.credits,
      };

      // Check if subject already exists in active (by subCode)
      bool subjectExists = activeSubjects.any((s) => s is Map && s['subCode'] == subject.subCode);
      if (subjectExists) {
        return true; // Already added
      }

      // Remove from inactive if it exists there (by subCode)
      inactiveSubjects.removeWhere((s) => s is Map && s['subCode'] == subject.subCode);

      // Add to active subjects
      activeSubjects.add(subjectData);
  
      // Prepare document data
      final updateData = {
        'is_current': true,
        'activeSubjects': activeSubjects,
        'inactiveSubjects': inactiveSubjects,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
  
      // Update/create the document
      await docRef.set(updateData);

      // Verify the update
      final verifyDoc = await docRef.get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data() as Map<String, dynamic>;
        final verifyActiveSubjects = verifyData['activeSubjects'] ?? [];
        bool subjectFound = verifyActiveSubjects.any((s) => s is Map && s['subCode'] == subject.subCode);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

// Remove subject from user's selectedSubjects subcollection
Future<bool> removeSubjectFromUserSelectedSubjects(String userId, String subjectCode) async {
  try {
    CollectionReference selectedSubjectsCol = _firestore
        .collection('users')
        .doc(userId)
        .collection('selectedSubjects');

    // Query for document with is_current = true
    QuerySnapshot query = await selectedSubjectsCol
        .where('is_current', isEqualTo: true)
        .get();

    if (query.docs.isEmpty) return false;

    DocumentReference docRef = query.docs.first.reference;
    Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;

    List<dynamic> activeSubjects = data['activeSubjects'] ?? [];
    List<dynamic> inactiveSubjects = data['inactiveSubjects'] ?? [];

    // Remove from both arrays (by subCode)
    activeSubjects.removeWhere((s) => s is Map && s['subCode'] == subjectCode);
    inactiveSubjects.removeWhere((s) => s is Map && s['subCode'] == subjectCode);

    // Update the document
    await docRef.update({
      'activeSubjects': activeSubjects,
      'inactiveSubjects': inactiveSubjects,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return true;
  } catch (e) {
    return false;
  }
}

// Toggle subject status between active and inactive in selectedSubjects subcollection
Future<bool> toggleSubjectStatusInSelectedSubjects(String userId, String subjectCode) async {
  try {
    CollectionReference selectedSubjectsCol = _firestore
        .collection('users')
        .doc(userId)
        .collection('selectedSubjects');

    // Query for document with is_current = true
    QuerySnapshot query = await selectedSubjectsCol
        .where('is_current', isEqualTo: true)
        .get();

    if (query.docs.isEmpty) return false;

    DocumentReference docRef = query.docs.first.reference;
    Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;

    List<dynamic> activeSubjects = data['activeSubjects'] ?? [];
    List<dynamic> inactiveSubjects = data['inactiveSubjects'] ?? [];

    // Find the subject data in activeSubjects
    Map<String, dynamic>? subjectData;
    int activeIndex = activeSubjects.indexWhere((s) => s is Map && s['subCode'] == subjectCode);
    if (activeIndex != -1) {
      // Move from active to inactive
      subjectData = activeSubjects.removeAt(activeIndex) as Map<String, dynamic>;
      inactiveSubjects.add(subjectData);
    } else {
      // Check inactiveSubjects
      int inactiveIndex = inactiveSubjects.indexWhere((s) => s is Map && s['subCode'] == subjectCode);
      if (inactiveIndex != -1) {
        // Move from inactive to active
        subjectData = inactiveSubjects.removeAt(inactiveIndex) as Map<String, dynamic>;
        activeSubjects.add(subjectData);
      } else {
        return false; // Subject not found
      }
    }

    // Update the document
    await docRef.update({
      'activeSubjects': activeSubjects,
      'inactiveSubjects': inactiveSubjects,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return true;
  } catch (e) {
    return false;
  }
}


  //==============================

  // Initialize subjects subcollection for new user
  Future<void> _initializeUserSubjects(String userId) async {
    try {
      // Create the selectedSubjects subcollection with initial empty structure
      CollectionReference selectedSubjectsCol = _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects');

      final docId = 'current001';

      // Create a document with is_current = true and empty arrays
      final docData = {
        'is_current': true,
        'activeSubjects': [],
        'inactiveSubjects': [],
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await selectedSubjectsCol.doc(docId).set(docData);

      // Verify the document was created
      final docSnapshot = await selectedSubjectsCol.doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  // Get user's selected subjects from Firestore (both active and inactive)
  Future<Set<String>> getUserSelectedSubjects(String userId) async {
    try {
      CollectionReference selectedSubjectsCol = _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects');

      // Query for document with is_current = true
      QuerySnapshot query = await selectedSubjectsCol
          .where('is_current', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return {}; // No selected subjects
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final activeSubjects = data['activeSubjects'] as List<dynamic>? ?? [];
      final inactiveSubjects = data['inactiveSubjects'] as List<dynamic>? ?? [];

      // Extract subCodes from both active and inactive subjects
      final activeCodes = activeSubjects
          .where((s) => s is Map && s['subCode'] != null)
          .map((s) => s['subCode'] as String);

      final inactiveCodes = inactiveSubjects
          .where((s) => s is Map && s['subCode'] != null)
          .map((s) => s['subCode'] as String);

      // Combine both sets
      final allSubjectCodes = {...activeCodes, ...inactiveCodes};

      return allSubjectCodes;
    } catch (e) {
      return {};
    }
  }

  // Debug method to check subjects subcollection status
  Future<void> debugUserSubjects(String userId) async {
    try {
      CollectionReference selectedSubjectsCol = _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects');

      // Check if collection exists by trying to get documents
      QuerySnapshot query = await selectedSubjectsCol
          .where('is_current', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        for (var doc in query.docs) {
          // Check if data is from cache or server
          final metadata = doc.metadata;

          // Show active/inactive subjects
          final data = doc.data() as Map<String, dynamic>;
          final activeSubjects = data['activeSubjects'] ?? [];
          final inactiveSubjects = data['inactiveSubjects'] ?? [];
        }
      } else {
        // Check if collection has any documents at all
        QuerySnapshot allDocs = await selectedSubjectsCol.get();
      }
    } catch (e) {
      // Debug method - silently handle errors
    }
  }

}
