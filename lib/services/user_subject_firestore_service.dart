import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/selected_subject.dart';

class UserSubjectFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, List<SelectedSubject>>> fetchSubjectsData(String userId) async {
    try {
      // Query the selectedSubjects collection for document with is_current == true
      QuerySnapshot query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects')
          .where('is_current', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        DocumentSnapshot doc = query.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> activeSubjectsData = data['activeSubjects'] ?? [];
        List<dynamic> inactiveSubjectsData = data['inactiveSubjects'] ?? [];

        return {
          'active': activeSubjectsData.map((item) {
            return SelectedSubject.fromJson(item as Map<String, dynamic>);
          }).toList(),
          'inactive': inactiveSubjectsData.map((item) {
            return SelectedSubject.fromJson(item as Map<String, dynamic>);
          }).toList(),
        };
      }

      return {'active': [], 'inactive': []};
    } catch (e) {

      return {'active': [], 'inactive': []};
    }
  }

  Future<List<SelectedSubject>> fetchSelectedSubjects(String userId) async {
    final data = await fetchSubjectsData(userId);
    return data['active'] ?? [];
  }


  Future<bool> toggleSubjectStatus(String userId, String subCode) async {
    try {
      DocumentReference docRef = _firestore.doc('users/$userId/selectedSubjects');

      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) return false;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> activeSubjectsData = data['activeSubjects'] ?? [];
      List<dynamic> inactiveSubjectsData = data['inactiveSubjects'] ?? [];

      // Find subject in activeSubjects
      int activeIndex = -1;
      Map<String, dynamic>? subjectToMove;
      for (int i = 0; i < activeSubjectsData.length; i++) {
        if (activeSubjectsData[i] is Map<String, dynamic> &&
            (activeSubjectsData[i] as Map<String, dynamic>)['subCode'] == subCode) {
          activeIndex = i;
          subjectToMove = activeSubjectsData[i] as Map<String, dynamic>;
          break;
        }
      }

      if (activeIndex != -1) {
        // Move from active to inactive
        activeSubjectsData.removeAt(activeIndex);
        inactiveSubjectsData.add(subjectToMove);
      } else {
        // Find in inactiveSubjects
        int inactiveIndex = -1;
        for (int i = 0; i < inactiveSubjectsData.length; i++) {
          if (inactiveSubjectsData[i] is Map<String, dynamic> &&
              (inactiveSubjectsData[i] as Map<String, dynamic>)['subCode'] == subCode) {
            inactiveIndex = i;
            subjectToMove = inactiveSubjectsData[i] as Map<String, dynamic>;
            break;
          }
        }
        if (inactiveIndex != -1) {
          // Move from inactive to active
          inactiveSubjectsData.removeAt(inactiveIndex);
          activeSubjectsData.add(subjectToMove);
        } else {
          // Subject not found
          return false;
        }
      }

      await docRef.set({
        'is_current': true,
        'activeSubjects': activeSubjectsData,
        'inactiveSubjects': inactiveSubjectsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {

      return false;
    }
  }


  Future<bool> removeSubjectFromSelected(String userId, String subCode) async {
    try {
      CollectionReference colRef = _firestore.collection('users').doc(userId).collection('selectedSubjects');
      QuerySnapshot query = await colRef.where('is_current', isEqualTo: true).get();

      if (query.docs.isEmpty) return false;

      DocumentReference docRef = query.docs.first.reference;
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) return false;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> activeSubjectsData = data['activeSubjects'] ?? [];
      List<dynamic> inactiveSubjectsData = data['inactiveSubjects'] ?? [];

      // Remove from activeSubjects
      activeSubjectsData.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          return item['subCode'] == subCode;
        }
        return false;
      });

      // Remove from inactiveSubjects
      inactiveSubjectsData.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          return item['subCode'] == subCode;
        }
        return false;
      });

      await docRef.set({
        'is_current': true,
        'activeSubjects': activeSubjectsData,
        'inactiveSubjects': inactiveSubjectsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {

      return false;
    }
  }

  // New method to store at /users/[userid]/selectedSubjects/[randomId] with activeSubjects array
  Future<SelectedSubject?> addSubjectToSelectedSubjectsDoc(String userId, Subject subject, int mcqsCount) async {
    try {
      SelectedSubject selectedSubject = SelectedSubject(
        subCode: subject.subCode,
        subName: subject.subName,
        subIcon: subject.subIcon,
        org: subject.org,
        credits: subject.credits,
        mcqsCount: mcqsCount,
        subjRef: '/mySubjects/${subject.subCode}',
      );

      // Query the selectedSubjects collection for document with is_current == true
      CollectionReference colRef = _firestore.collection('users').doc(userId).collection('selectedSubjects');
      QuerySnapshot query = await colRef.where('is_current', isEqualTo: true).get();

      DocumentReference docRef;
      if (query.docs.isNotEmpty) {
        docRef = query.docs.first.reference;
      } else {
        docRef = colRef.doc('current1');
      }

      DocumentSnapshot doc = await docRef.get();
      Map<String, dynamic> data = {};

      if (doc.exists) {
        data = doc.data() as Map<String, dynamic>;
      }

      List<dynamic> activeSubjectsData = data['activeSubjects'] ?? [];
      List<dynamic> inactiveSubjectsData = data['inactiveSubjects'] ?? [];

      // Check if subject already exists in active
      bool subjectExists = activeSubjectsData.any((item) {
        if (item is Map<String, dynamic>) {
          return item['subCode'] == subject.subCode;
        }
        return false;
      });

      if (subjectExists) {

        return null;
      }

      // Remove from inactive if exists
      inactiveSubjectsData.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          return item['subCode'] == subject.subCode;
        }
        return false;
      });

      // Add subject data to activeSubjects array
      Map<String, dynamic> subjectData = selectedSubject.toJson();
      activeSubjectsData.add(subjectData);

      // Update the document with is_current at document level
      await docRef.set({
        'is_current': true,
        'activeSubjects': activeSubjectsData,
        'inactiveSubjects': inactiveSubjectsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });


      return selectedSubject;
    } catch (e) {

      return null;
    }
  }

  // Sync user reactions for a subject to Firestore
  Future<bool> syncUserReactionsForSubject(String userId, String subCode, Map<int, List<Map<String, dynamic>>> chapterReactions) async {
    try {
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('selectedSubjects')
          .doc(subCode);

      // Convert chapter reactions to the required format
      Map<String, dynamic> reactionsData = {};
      chapterReactions.forEach((chapterOrder, reactions) {
        reactionsData[chapterOrder.toString()] = reactions;
      });

      await docRef.set(reactionsData, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }
}
