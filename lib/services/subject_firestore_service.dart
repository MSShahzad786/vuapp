
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class SubjectFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Subject>> fetchMySubjects() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('subjectsMetaData')
          .where('is_active', isEqualTo: true)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firestore timeout'),
          );

      if (snapshot.docs.isEmpty) {
        throw Exception('No Any Subject Found');
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final subjectsList = data['0'] as List<dynamic>? ?? [];
      final subjectsData = subjectsList.whereType<Map<String, dynamic>>().toList();

      if (subjectsData.isEmpty) {
        throw Exception('No Subject Found');
      }

      // Filter only active subjects
      final activeSubjects = subjectsData.where((subjectMap) => subjectMap['is_active'] == true).toList();

      if (activeSubjects.isEmpty) {
        throw Exception('No Active Subject Found');
      }

      return activeSubjects.map((subjectMap) {
        return Subject(
          id: subjectMap['subCode'] ?? '',
          subCode: subjectMap['subCode'] ?? '',
          subName: subjectMap['subName'] ?? '',
          subIcon: subjectMap['subIcon'] ?? '',
          org: subjectMap['org'] ?? '',
          underProcess: subjectMap['under_proccess'] ?? false,
          credits: subjectMap['credits'] ?? 0,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Subject>> searchSubjects(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('mySubjects')
          .where('subName', isGreaterThanOrEqualTo: query)
          .where('subName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      return snapshot.docs.map((doc) {
        return Subject.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {

      return [];
    }
  }

  Future<int> getMcqsCount(String subjectId) async {
    try {
      QuerySnapshot chaptersSnapshot = await _firestore
          .collection('mySubjects')
          .doc(subjectId)
          .collection('chapters')
          .get();

      int totalMcqs = 0;
      for (var chapterDoc in chaptersSnapshot.docs) {
        List<dynamic> mcqIds = chapterDoc['mcqIds'] ?? [];
        totalMcqs += mcqIds.length;
      }
      return totalMcqs;
    } catch (e) {

      return 0;
    }
  }
}
